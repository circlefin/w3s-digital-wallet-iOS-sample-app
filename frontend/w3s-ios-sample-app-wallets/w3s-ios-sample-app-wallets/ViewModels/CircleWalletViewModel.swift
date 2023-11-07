// Copyright (c) 2023, Circle Technologies, LLC. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0 
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import CircleProgrammableWalletSDK

class CircleWalletViewModel: ObservableObject {
    
    enum CircleWalletState {
        case notCreated
        case userTokeneEncryptionKeyChallengeIdCreated
        case userTokenEncryptionKeyChallengeIdCreationFailed
        case challengeSuccessful
        case challengeFailed
        case pinSet
    }
    
    struct Challenge: Codable {
        let challengeId: String
    }
    
    struct UserData: Codable {
        let userId: String
        let userToken: String
        let encryptionKey: String
        let challengeId: String
    }
    
    struct UserWallet: Identifiable, Decodable {
        let id: String
        let state: String
        let walletSetId: String
        let custodyType: String
        let userId: String
        let address: String
        let blockchain: String
        let accountType: String
        let updateDate: String
        let createDate: String
        var balances = [TokenBalance]()
        
        private enum CodingKeys: String, CodingKey {
            case id, state, walletSetId, custodyType, userId, address, blockchain, accountType, updateDate, createDate
        }
    }
    
    struct Token: Identifiable, Codable {
        let id: String
        let blockchain: String
        let tokenAddress: String?
        let standard: String?
        let name: String
        let symbol: String
        let decimals: Int
        let isNative: Bool
        let updateDate: String
        let createDate: String
    }
    
    struct TokenBalance: Codable {
        var id = UUID()
        let token: Token
        let amount: String
        let updateDate: String
        
        private enum CodingKeys: String, CodingKey {
            case token, amount, updateDate
        }
    }
    
    struct CircleAPIError: Codable {
        let code: Int
        let message: String
    }
    
    enum CircleError: Error {
        case apiError
        case tokenExpired
        case challengeFailed
    }
    
    struct TransferFeeEstimate: Codable {
        let low, medium, high: FeeLevel
    }
    
    struct FeeLevel: Codable {
        let gasLimit: String
        let baseFee: String
        let priorityFee: String
        let maxFee: String
    }
    
    struct ValidAddress: Codable {
        let isValid: Bool
    }
    
    @Published var userWallets: [UserWallet] = []
    
    @Published var state: CircleWalletState = .notCreated
    @Published var userData: UserData?
    
    @Published var userToken: String = UserDefaults.standard.string(forKey: "circleUserToken") ?? ""
    @Published var encryptionKey: String = UserDefaults.standard.string(forKey: "circleEncryptionKey") ?? ""
    @Published var userId: String = UserDefaults.standard.string(forKey: "circleUserId") ?? ""
    
    let serverBaseURI: String = "http://localhost:3000/api"
    
    init() {
        self.userToken = UserDefaults.standard.string(forKey: "circleUserToken") ?? ""
        self.userId = UserDefaults.standard.string(forKey: "circleUserId") ?? ""
        self.encryptionKey = UserDefaults.standard.string(forKey: "circleEncryptionKey") ?? ""
    }
    
    // Create a User, Acquire a session token, Acquire the Challenge ID
    func createAndInitUserAsync() async -> Result<String, CircleError> {
        do {
            var request = URLRequest(url: URL(string: serverBaseURI + "/user")!,timeoutInterval: Double.infinity)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if (response as? HTTPURLResponse)?.statusCode == 500  {
                let error = try JSONDecoder().decode(CircleAPIError.self, from: data)
                if error.code == 155104 {
                    return .failure(.tokenExpired)
                }
                return .failure(.apiError)
            }
            
            let userData = try JSONDecoder().decode(UserData.self, from: data)
            Task {@MainActor in
                self.userToken = userData.userToken
                self.encryptionKey = userData.encryptionKey
                self.userId = userData.userId
            }
            UserDefaults.standard.set(userData.userToken, forKey: "circleUserToken")
            UserDefaults.standard.set(userData.userId, forKey: "circleUserId")
            UserDefaults.standard.set(userData.encryptionKey, forKey: "circleEncryptionKey")
            let result = await self.executeChallengeAsync(challengeIds: [userData.challengeId])
            
            switch result {
            case .success(let result):
                //self.state = .userTokeneEncryptionKeyChallengeIdCreated
                return .success(result)
            case .failure(_):
                print("Error: Challenge failed.")
                return .failure(.challengeFailed)
            }
        } catch {
            print("Error fetching data: \(error)")
            return .failure(.apiError)
        }
    }
    
    // Execute challenge
    func executeChallenge(challengeIds: [String], completion: @escaping ((Result<String, CircleError>) -> Void)) {
        WalletSdk.shared.execute(userToken: self.userToken,
                                 encryptionKey: self.encryptionKey,
                                 challengeIds: challengeIds) { response in
            switch response.result {
            case .success(let result):
                let challengeStatus = result.status.rawValue
                let challengeType = result.resultType.rawValue
                print("\(challengeType) - \(challengeStatus)")
                
                if result.resultType.rawValue == "SET_PIN"
                    && result.status.rawValue == "IN_PROGRESS" {
                    self.state = .pinSet
                    UserDefaults.standard.set(true, forKey: "circleSetPin")
                }
                
                if result.resultType.rawValue == "CREATE_TRANSACTION"
                    && result.status.rawValue == "COMPLETE" {
                    
                }
                
                completion(.success("\(challengeType) - \(challengeStatus)"))
                
            case .failure(let error):
                self.errorHandler(apiError: error, onErrorController: response.onErrorController)
                self.state = .challengeFailed
                completion(.failure(.challengeFailed))
            }
        }
    }
    
    func executeChallengeAsync(challengeIds: [String]) async -> Result<String, CircleError> {
        await withCheckedContinuation { continuation in
            Task {@MainActor in
                WalletSdk.shared.execute(userToken: self.userToken,
                                         encryptionKey: self.encryptionKey,
                                         challengeIds: challengeIds) { response in
                    switch response.result {
                    case .success(let result):
                        let challengeStatus = result.status.rawValue
                        let challengeType = result.resultType.rawValue
                        print("\(challengeType) - \(challengeStatus)")
                        
                        if result.resultType.rawValue == "SET_PIN"
                            && result.status.rawValue == "IN_PROGRESS" {
                            self.state = .pinSet
                            UserDefaults.standard.set(true, forKey: "circleSetPin")
                        }
                        
                        if result.resultType.rawValue == "CREATE_TRANSACTION"
                            && result.status.rawValue == "COMPLETE" {
                            
                        }
                        
                        //return .success("\(challengeType) - \(challengeStatus)")
                        
                        continuation.resume(returning: .success("\(challengeType) - \(challengeStatus)"))
                        
                    case .failure(let error):
                        self.errorHandler(apiError: error, onErrorController: response.onErrorController)
                        self.state = .challengeFailed
                        
                        //return .failure(.challengeFailed)
                        continuation.resume(returning: .failure(.challengeFailed))
                    }
                    
                }
            }
            
        }
        
        
        
    }
    
    // Refresh token if token expired
    func refreshUserTokenAsync() async {
        do {
            var request = URLRequest(url: URL(string: serverBaseURI + "/user/token")!,timeoutInterval: Double.infinity)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            let userId = UserDefaults.standard.string(forKey: "circleUserId")!
            let body: [String: String] = ["userId": userId]
            let finalBody = try? JSONSerialization.data(withJSONObject: body)
            
            request.httpBody = finalBody
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if (response as? HTTPURLResponse)?.statusCode == 500  {
                let error = try JSONDecoder().decode(CircleAPIError.self, from: data)
                print(error)
                return
            }
            
            let userData = try JSONDecoder().decode(UserData.self, from: data)
            DispatchQueue.main.async{
                self.userToken = userData.userToken
                self.encryptionKey = userData.encryptionKey
                self.userId = userData.userId
                UserDefaults.standard.set(userData.userToken, forKey: "circleUserToken")
                UserDefaults.standard.set(userData.userId, forKey: "circleUserId")
                UserDefaults.standard.set(userData.encryptionKey, forKey: "circleEncryptionKey")
                self.state = .userTokeneEncryptionKeyChallengeIdCreated
                Task{
                    await self.getWalletsAsync()
                }
            }
            
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    // Get user wallets
    func getWalletsAsync() async {
        do {
            if UserDefaults.standard.string(forKey: "circleUserToken")!.isEmpty
            {
                await refreshUserTokenAsync()
            }
            var request = URLRequest(url: URL(string: serverBaseURI + "/wallets")!,timeoutInterval: Double.infinity)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(UserDefaults.standard.string(forKey: "circleUserToken") ?? "", forHTTPHeaderField: "X-User-Token")
            request.httpMethod = "GET"
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if (response as? HTTPURLResponse)?.statusCode == 500  {
                let error = try JSONDecoder().decode(CircleAPIError.self, from: data)
                await refreshUserTokenAsync()
                print(error)
                return
            }
            
            let wallets = try JSONDecoder().decode([UserWallet].self, from: data)
            DispatchQueue.main.async{
                print("User token: ")
                print(UserDefaults.standard.string(forKey: "circleUserToken") ?? "")
                print("Encryption key: ")
                print(UserDefaults.standard.string(forKey: "circleEncryptionKey") ?? "")
                print(wallets)
                if wallets.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        print("Getting wallets again...")
                        Task {
                            await self.getWalletsAsync()
                        }
                    }
                } else {
                    //print("Received wallets...")
                    // Re-populate arrays with updated wallets and balances
                    self.userWallets.removeAll()
                    var walletIndex = 0
                    for wallet in wallets {
                        self.userWallets.append(wallet)
                        self.getWalletBalance(walletIndex: walletIndex, walletId: wallet.id)
                        walletIndex += 1
                        
                    }
                }
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    // Get wallet balance by id
    func getWalletBalance(walletIndex: Int, walletId: String) {
        var request = URLRequest(url: URL(string: serverBaseURI + "/wallets/" + walletId + "/balances")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(UserDefaults.standard.string(forKey: "circleUserToken") ?? "", forHTTPHeaderField: "X-User-Token")
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let balances = try? JSONDecoder().decode([TokenBalance].self, from: data) {
                    print(balances)
                    DispatchQueue.main.async{
                        for balance in balances {
                            self.userWallets[walletIndex].balances.append(balance)
                            print(self.userWallets[walletIndex].balances)
                        }
                    }
                } else {
                    print("Invalid Response")
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        
        task.resume()
    }
    
    // Change pin
    func changePin(completion: @escaping (String) -> Void) {
        var request = URLRequest(url: URL(string: serverBaseURI + "/user/pin")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(UserDefaults.standard.string(forKey: "circleUserToken") ?? "", forHTTPHeaderField: "X-User-Token")
        
        request.httpMethod = "PUT"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let challenge = try? JSONDecoder().decode(Challenge.self, from: data) {
                    print(challenge)
                    DispatchQueue.main.async{
                        completion(challenge.challengeId)
                    }
                } else {
                    print("Invalid Response")
                    DispatchQueue.main.async{
                        completion("")
                    }
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        
        task.resume()
    }
    
    // Recover Account
    func recoverAccount(completion: @escaping (String) -> Void) {
        var request = URLRequest(url: URL(string: serverBaseURI + "/user/pin/restore")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(UserDefaults.standard.string(forKey: "circleUserToken") ?? "", forHTTPHeaderField: "X-User-Token")
        
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let challenge = try? JSONDecoder().decode(Challenge.self, from: data) {
                    print(challenge)
                    DispatchQueue.main.async{
                        completion(challenge.challengeId)
                    }
                } else {
                    print("Invalid Response")
                    DispatchQueue.main.async{
                        completion("")
                    }
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        
        task.resume()
    }
    
    // Estimate transfer network fee
    func estimateTransferFeeAsync(amounts: [String], destinationAddress: String, tokenId: String, walletId: String) async -> Result<TransferFeeEstimate, CircleError> {
        do {
            var request = URLRequest(url: URL(string: serverBaseURI + "/transactions/transfer/estimateFee")!,timeoutInterval: Double.infinity)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(UserDefaults.standard.string(forKey: "circleUserToken") ?? "", forHTTPHeaderField: "X-User-Token")
            request.httpMethod = "POST"
            
            let body: [String: Any] = [
                "amounts": amounts,
                "destinationAddress": destinationAddress,
                "tokenId": tokenId,
                "walletId": walletId
            ]
            
            let finalBody = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = finalBody
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if (response as? HTTPURLResponse)?.statusCode == 500  {
                let error = try JSONDecoder().decode(CircleAPIError.self, from: data)
                if error.code == 155104 {
                    return .failure(.tokenExpired)
                }
                return .failure(.apiError)
            }
            
            let feeEstimate = try JSONDecoder().decode(TransferFeeEstimate.self, from: data)
    
            return .success(feeEstimate)
        } catch {
            print("Error fetching data: \(error)")
            return .failure(.apiError)
        }
    }
    
    // Validate address
    func validateAddressAsync(blockchain: String, address: String) async -> Result<Bool, CircleError> {
        do {
            var request = URLRequest(url: URL(string: serverBaseURI + "/transactions/validateAddress")!,timeoutInterval: Double.infinity)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(UserDefaults.standard.string(forKey: "circleUserToken") ?? "", forHTTPHeaderField: "X-User-Token")
            request.httpMethod = "POST"
            
            let body: [String: Any] = [
                "blockchain": blockchain,
                "address": address,
            ]
            
            let finalBody = try? JSONSerialization.data(withJSONObject: body)
            
            request.httpBody = finalBody
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if (response as? HTTPURLResponse)?.statusCode == 500  {
                let error = try JSONDecoder().decode(CircleAPIError.self, from: data)
                if error.code == 155104 {
                    return .failure(.tokenExpired)
                }
                return .failure(.apiError)
            }
            
            let valid = try JSONDecoder().decode(ValidAddress.self, from: data)
           
            return .success(valid.isValid)
        } catch {
            print("Error fetching data: \(error)")
            return .failure(.apiError)
        }
    }
    
    // Transfer token
    func transferAsync(amounts: [String], destinationAddress: String, tokenId: String, walletId: String, feeLevel: String) async -> Result<String, CircleError> {
        do {
            var request = URLRequest(url: URL(string: serverBaseURI + "/user/transactions/transfer")!,timeoutInterval: Double.infinity)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(UserDefaults.standard.string(forKey: "circleUserToken") ?? "", forHTTPHeaderField: "X-User-Token")
            request.httpMethod = "POST"
            
            let userId = UserDefaults.standard.string(forKey: "circleUserId")!
            
            let body: [String: Any] = [
                "userId": userId,
                "amounts": amounts,
                "destinationAddress": destinationAddress,
                "tokenId": tokenId,
                "walletId": walletId,
                "feeLevel": feeLevel
            ]
            let finalBody = try? JSONSerialization.data(withJSONObject: body)
            
            request.httpBody = finalBody
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if (response as? HTTPURLResponse)?.statusCode == 500  {
                let error = try JSONDecoder().decode(CircleAPIError.self, from: data)
                if error.code == 155104 {
                    return .failure(.tokenExpired)
                }
                return .failure(.apiError)
            }
            
            let challenge = try JSONDecoder().decode(Challenge.self, from: data)
            let result = await self.executeChallengeAsync(challengeIds: [challenge.challengeId])
            switch result {
            case .success(let result):
                return .success(result)
            case .failure(_):
                print("Error: Challenge failed.")
                return .failure(.challengeFailed)
            }
            //}
        } catch {
            print("Error fetching data: \(error)")
            return .failure(.apiError)
        }
    }
    
    func errorHandler(apiError: ApiError, onErrorController: UINavigationController?) {
        switch apiError.errorCode {
        case .userHasSetPin:
            onErrorController?.dismiss(animated: true)
        default:
            break
        }
    }
}

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

struct ExecuteChallengeView: View {
    @State private var challengeId = ""
    @State var buttonDisabled = true
    @State var showToast = false
    @State var toastMessage: String?
    @State var toastConfig: Toast.Config = .init()
    
    @EnvironmentObject var circleWalletViewModel: CircleWalletViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            HStack(spacing: 0) {
                Text("Challenge Id")
                    .font(Font.custom("Avenir", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.63, blue: 0.69))
            }
            TextField("Enter or paste challenge id", text: $challengeId)
                .onChange(of: challengeId) { challengeId in
                    if challengeId.isEmpty {
                        buttonDisabled = true
                    } else {
                        buttonDisabled = false
                    }
                }
            
            Button(action: {
                executeChallenge(userToken: circleWalletViewModel.userToken, encryptionKey: circleWalletViewModel.encryptionKey, challengeId: challengeId)
            }) {
                Text("EXECUTE CHALLENGE")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 24/255, green: 148/255, blue: 232/255))
                    .cornerRadius(5)
                    .padding()
            }
            .disabled(buttonDisabled)
            
        }
        .padding(16)
        .toast(message: toastMessage ?? "",
               isShowing: $showToast,
               config: toastConfig)
        
    }
    
    func executeChallenge(userToken: String, encryptionKey: String, challengeId: String) {
        WalletSdk.shared.execute(userToken: userToken,
                                 encryptionKey: encryptionKey,
                                 challengeIds: [challengeId]) { response in
            switch response.result {
            case .success(let result):
                let challengeStatus = result.status.rawValue
                let challeangeType = result.resultType.rawValue
                showToast(.success, message: "\(challeangeType) - \(challengeStatus)")
                
            case .failure(let error):
                showToast(.failure, message: "Error: " + error.errorString)
                errorHandler(apiError: error, onErrorController: response.onErrorController)
            }
        }
    }
}

extension ExecuteChallengeView {
    enum ToastType {
        case general
        case success
        case failure
    }
    
    func showToast(_ type: ToastType, message: String) {
        toastMessage = message
        showToast = true
        
        switch type {
        case .general:
            toastConfig = Toast.Config()
        case .success:
            toastConfig = Toast.Config(backgroundColor: .green, duration: 2.0)
        case .failure:
            toastConfig = Toast.Config(backgroundColor: .pink, duration: 10.0)
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

struct ExecuteChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        ExecuteChallengeView()
    }
}

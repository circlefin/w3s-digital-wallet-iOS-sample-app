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

struct SendTransactionView: View {
    @EnvironmentObject var circleWalletViewModel: CircleWalletViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var blockchain = ""
    @State var tokenId = ""
    @State var walletId = ""
    var completion: (String) -> Void
    @State private var destinationAddress = ""
    @State private var amount: Float = 0.0
    @State private var feeLevel = ""
    @State private var selectedFee = 0
    @State var transferFeeEstimate: CircleWalletViewModel.TransferFeeEstimate?
    @State private var isValidAddress = false
    
    @State var showAlert = false
    @State private var transferResult = ""
    
    @State var showToast = false
    @State var toastMessage: String?
    @State var toastConfig: Toast.Config = .init()
    
    @State var sendDisabled = true
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 0) {
                        Text("To Address")
                            .font(Font.custom("Avenir", size: 14))
                            .foregroundColor(Color(red: 0.60, green: 0.63, blue: 0.69))
                    }
                    TextField("Enter or paste address", text: $destinationAddress)
                        .onChange(of: destinationAddress) { address in
                            Task {
                                let result = await circleWalletViewModel.validateAddressAsync(blockchain: blockchain, address: address)
                                switch result {
                                case .success(let validAddress):
                                    self.isValidAddress = validAddress
                                case .failure(let error):
                                    print(error)
                                    showToast(.failure, message: error.localizedDescription)
                                }
                            }
                        }
                }
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 0) {
                        Text("Transfer Amount")
                            .font(Font.custom("Avenir", size: 14))
                            .foregroundColor(Color(red: 0.60, green: 0.63, blue: 0.69))
                    }
                    TextField("Enter amount", value: $amount, formatter: formatter)
                        .onChange(of: amount) { amount in
                            if self.isValidAddress {       }
                            Task{
                                let result = await circleWalletViewModel.estimateTransferFeeAsync(amounts: [String(amount)], destinationAddress: destinationAddress, tokenId: tokenId, walletId: walletId)
                                switch result {
                                case .success(let transferFeeEstimate):
                                    self.transferFeeEstimate = transferFeeEstimate
                                case .failure(let error):
                                    print(error)
                                    showToast(.failure, message: error.localizedDescription)
                                }
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .font(Font.custom("Avenir", size: 15))
                }
            }
            if (self.transferFeeEstimate != nil && amount != 0 ) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Blockchain Fee")
                        .font(Font.custom("Avenir", size: 14))
                        .foregroundColor(Color(red: 0.60, green: 0.63, blue: 0.69))
                    TransferFeeButton(label: "Fast", feeEstimate: self.transferFeeEstimate!.high, selected: feeLevel == "HIGH", action: {
                        feeLevel = "HIGH"
                        sendDisabled = false
                    })
                    TransferFeeButton(label: "Medium", feeEstimate: self.transferFeeEstimate!.medium, selected: feeLevel == "MEDIUM", action: {
                        feeLevel = "MEDIUM"
                        sendDisabled = false
                    })
                    TransferFeeButton(label: "Slow", feeEstimate: self.transferFeeEstimate!.low, selected: feeLevel == "LOW", action: {
                        feeLevel = "LOW"
                        sendDisabled = false
                    })
                    
                    Button(action: {
                        var amounts: [String] = []
                        amounts.append(String(amount))
                        Task {
                            let result = await circleWalletViewModel.transferAsync(amounts: amounts, destinationAddress: destinationAddress, tokenId: tokenId, walletId: walletId, feeLevel: feeLevel)
                            
                            switch result {
                            case .success(let transferResult):
                                completion(transferResult)
                                dismiss()
                            case .failure(let error):
                                print(error)
                                showToast(.failure, message: error.localizedDescription)
                            }
                        }
                        
                    }) {
                        Text("Send")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 24/255, green: 148/255, blue: 232/255))
                            .cornerRadius(5)
                            .padding()
                    }
                    .disabled(sendDisabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .toast(message: toastMessage ?? "",
               isShowing: $showToast,
               config: toastConfig)
        
    }
}


extension SendTransactionView {
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
}

struct SendTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        let transferFeeEstimate = CircleWalletViewModel.TransferFeeEstimate(low: CircleWalletViewModel.FeeLevel(gasLimit: "70148", baseFee: "0.000000017", priorityFee: "2.101749992", maxFee: "2.101750026"), medium: w3s_ios_sample_app_wallets.CircleWalletViewModel.FeeLevel(gasLimit: "70148", baseFee: "0.000000017", priorityFee: "2.505687485", maxFee: "2.505687519"), high: w3s_ios_sample_app_wallets.CircleWalletViewModel.FeeLevel(gasLimit: "70148", baseFee: "0.000000017", priorityFee: "3.814789185", maxFee: "3.814789219"))
        
        SendTransactionView(completion: {_ in }, transferFeeEstimate: transferFeeEstimate)
            .environmentObject({ () -> CircleWalletViewModel in
                let circleWalletViewModel = CircleWalletViewModel()
                
                return circleWalletViewModel
            }())
    }
}

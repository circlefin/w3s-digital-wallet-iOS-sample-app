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

struct TransferFeeButton: View {
    let label: String
    let feeEstimate: CircleWalletViewModel.FeeLevel
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Button(action: action) {
                ZStack() {
                    HStack(spacing: 16) {
                        ZStack() {
                            if selected {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 40.0, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: 55, height: 55)
                                .background(.white)
                                .cornerRadius(4)
                                .offset(x: 0, y: 0)
                                .opacity(0.10)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label)
                                .font(Font.custom("Avenir", size: 14).weight(.black))
                                .foregroundColor(.white)
                            HStack {
                                Text("Base fee: ")
                                    .font(Font.custom("Avenir", size: 14))
                                    .foregroundColor(.white)
                                Text(feeEstimate.baseFee)
                                    .font(Font.custom("Avenir", size: 14))
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Text("Gas limit: ")
                                    .font(Font.custom("Avenir", size: 14))
                                    .foregroundColor(.white)
                                Text(feeEstimate.gasLimit)
                                    .font(Font.custom("Avenir", size: 14))
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Text("Max fee: ")
                                    .font(Font.custom("Avenir", size: 14))
                                    .foregroundColor(.white)
                                Text(feeEstimate.maxFee)
                                    .font(Font.custom("Avenir", size: 14))
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Text("Priority fee: ")
                                    .font(Font.custom("Avenir", size: 14))
                                    .foregroundColor(.white)
                                Text(feeEstimate.priorityFee)
                                    .font(Font.custom("Avenir", size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
                .background(.gray)
                .cornerRadius(4)
            }
        }
    }
}

struct TransferFeeButton_Previews: PreviewProvider {
    static var previews: some View {
        TransferFeeButton(label: "Fast", feeEstimate: CircleWalletViewModel.FeeLevel(gasLimit: "70148", baseFee: "0.000000016", priorityFee: "8.248913537", maxFee: "8.248913569"), selected: true, action: {})
    }
}

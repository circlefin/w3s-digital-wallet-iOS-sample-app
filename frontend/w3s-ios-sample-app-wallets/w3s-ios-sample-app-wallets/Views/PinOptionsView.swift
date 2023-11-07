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

struct PinOptionsView: View {
    @EnvironmentObject var circleWalletViewModel: CircleWalletViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Button(action: changePIN) {
                    Text("CHANGE PIN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 24/255, green: 148/255, blue: 232/255))
                        .cornerRadius(5)
                        .padding()
                }
                Button(action: restorePIN) {
                    Text("RESTORE PIN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 24/255, green: 148/255, blue: 232/255))
                        .cornerRadius(5)
                        .padding()
                }
            }
        }
    }
    
    func changePIN() {
        circleWalletViewModel.changePin { challengeId in
            print("Change Pin...")
            WalletSdk.shared.execute(userToken: UserDefaults.standard.string(forKey: "circleUserToken") ?? "", encryptionKey: UserDefaults.standard.string(forKey: "circleEncryptionKey") ?? "", challengeIds: [challengeId])
        }
    }

    func restorePIN() {
        circleWalletViewModel.recoverAccount { challengeId in
            print("Recover account...")
            WalletSdk.shared.execute(userToken: UserDefaults.standard.string(forKey: "circleUserToken") ?? "", encryptionKey: UserDefaults.standard.string(forKey: "circleEncryptionKey") ?? "", challengeIds: [challengeId])
        }
    }
}

struct PinOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PinOptionsView()
    }
}

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

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var circleWalletViewModel: CircleWalletViewModel
    
    let adapter = WalletSdkAdapter()
    
    let endPoint = "https://api.circle.com/v1/w3s"
    @State var appId = "your-App-ID"
    
    init() {
        self.adapter.initSDK(endPoint: endPoint, appId: appId)
        
        if let storedAppId = self.adapter.storedAppId, !storedAppId.isEmpty {
            self.appId = storedAppId
        }
    }
    
    var body: some View {
        switch authViewModel.state {
        case .signedIn:
            // if pin is set
            if UserDefaults.standard.bool(forKey: "circleSetPin") == true { HomeView() }
            // if not set up the wallets
            else { CircleLoadingView().environmentObject(authViewModel) }
        case .circleSetPinInProgress:
            // after wallet set up
            HomeView()
        case .signedOut:
            // log in again after sign out
            LoginView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

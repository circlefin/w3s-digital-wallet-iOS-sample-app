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

struct CircleLoadingView: View {
    @State var showToast = false
    @State var toastMessage: String?
    @State var toastConfig: Toast.Config = .init()
    
    @State var statusText = "Creating your wallet..."
    
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var circleWalletViewModel: CircleWalletViewModel
    
    var body: some View {
        VStack {
            ProgressView() {
                Text(statusText)
                    .font(.title2)
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(.white))
                    .font(.title)
            }
            .progressViewStyle(CircularProgressViewStyle())
        }
        .tint(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 31/255, green: 26/255, blue: 48/255))
        .scrollContentBackground(.hidden)
        .onChange(of: circleWalletViewModel.state) { state in
            if state == .pinSet {
                self.authViewModel.state = .circleSetPinInProgress
            }
        }
        .toast(message: toastMessage ?? "",
               isShowing: $showToast,
               config: toastConfig)
        .task({
            _ = await circleWalletViewModel.createAndInitUserAsync()
        })
    }
}


extension CircleLoadingView {
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

struct CircleLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        CircleLoadingView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CircleWalletViewModel())
    }
}

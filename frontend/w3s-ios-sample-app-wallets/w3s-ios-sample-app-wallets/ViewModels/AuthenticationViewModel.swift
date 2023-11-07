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

import Firebase
import GoogleSignIn
import AuthenticationServices
import SwiftUI

class AuthenticationViewModel: ObservableObject {
    enum SignInState {
        case signedIn
        case signedOut
        case circleSetPinInProgress
    }
    
    @Published var state: SignInState = .signedOut
    
    func signIn() {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                self.authenticateUser(for: user, with: error)
                if error != nil || user == nil {
                    // Show the app's signed-out state.
                } else {
                    // Show the app's signed-in state.
                    print("Already signed in.")
                }
            }
        } else {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            let configuration = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = configuration
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, completion: { signResult, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.authenticateUser(for: signResult?.user, with: error)
                }
            })
        }
    }
    
    private func authenticateUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let user = user,
              let idToken = user.idToken else { return }
        let accessToken = user.accessToken
        let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
        
        Auth.auth().signIn(with: credential) { [unowned self] (_, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.state = .signedIn
            }
        }
    }
    
    func signOut() {
        // 1
        GIDSignIn.sharedInstance.signOut()
        
        do {
            UserDefaults.standard.removeObject(forKey: "circleUserToken")
            UserDefaults.standard.removeObject(forKey: "circleEncryptionKey")
            UserDefaults.standard.removeObject(forKey: "userFullName")
            UserDefaults.standard.removeObject(forKey: "userEmail")
            UserDefaults.standard.removeObject(forKey: "circleUserId")
            UserDefaults.standard.removeObject(forKey: "circleSetPin")
            try Auth.auth().signOut()
            state = .signedOut
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func SignInButton(_ type: SignInWithAppleButton.Style) -> some View{
        return SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let authResults):
                self.state = .signedIn
                
                if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                    if appleIDCredential.fullName?.givenName != nil && appleIDCredential.fullName?.familyName != nil {
                        let firstName = appleIDCredential.fullName!.givenName
                        let lastName = appleIDCredential.fullName!.familyName
                        UserDefaults.standard.set("\(firstName!) \(lastName!)", forKey: "userFullName")
                    }
                    
                    if appleIDCredential.email != nil {
                        let email = appleIDCredential.email
                        UserDefaults.standard.set(email, forKey: "userEmail")
                    }
                }
               
                case .failure(let error):
                    print("Authorisation failed: \(error.localizedDescription)")
                }
            }
                .frame(width: 280, height: 60, alignment: .center)
                .signInWithAppleButtonStyle(type)
        }
        
    }
    

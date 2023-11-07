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
import GoogleSignIn

struct HomeView: View {
    // 1
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var circleWalletViewModel: CircleWalletViewModel
    
    
    
    // 2
    private let user = GIDSignIn.sharedInstance.currentUser
    @State var buttonText = "Copy"
    @State var showToast = false
    @State var toastMessage: String?
    @State var toastConfig: Toast.Config = .init()
    
    @State private var showingSendSheet = false
    @State private var showingPinOptionsSheet = false
    @State private var showingExecuteChallengeSheet = false
    @State private var selectedWallet: CircleWalletViewModel.UserWallet?
    @State private var selectedBalance: CircleWalletViewModel.TokenBalance?
    
    struct WalletAndBalance: Identifiable {
        var id = UUID()
        var wallet: CircleWalletViewModel.UserWallet
        var balance: CircleWalletViewModel.TokenBalance
    }
    
    @State private var selectedWalletAndBalance: WalletAndBalance?
    
    let fullname = UserDefaults.standard.string(forKey: "userFullName")
    let email = UserDefaults.standard.string(forKey: "userEmail")
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Wallet")
                                .font(.system(size: 30, weight: .bold))
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    if self.fullname != nil || self.email != nil || user?.profile != nil {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user?.profile?.name ?? self.fullname ?? "")
                                    .font(.headline)
                                
                                Text(user?.profile?.email ?? self.email ?? "")
                                    .font(.subheadline)
                            }
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                        .padding()
                    }
                    
                    ForEach(circleWalletViewModel.userWallets, id:\.id) { wallet in
                        VStack(alignment: .leading) {
                            Text("Blockchain")
                                .font(.headline)
                            Text("\(wallet.blockchain)")
                                .font(.subheadline)
                            Text("Address")
                                .font(.headline)
                            HStack{
                                Text("\(wallet.address)")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .font(.subheadline)
                                    .textSelection(.enabled)
                                Button {
                                    UIPasteboard.general.string = wallet.address
                                } label: {
                                    Label(buttonText, systemImage: "doc.on.doc")
                                        .font(.subheadline)
                                        .onTapGesture {
                                            // show toast
                                            showToast(.success, message: "Address copied.");
                                        }
                                }
                            }
                            if wallet.balances.isEmpty {
                                HStack {
                                    self.getTokenIcon(tokenSymbol: "USDC")
                                        .frame(height: 30)
                                        .padding(10)
                                    VStack(alignment: .leading) {
                                        Text("USDC")
                                            .frame(alignment: .leading)
                                            .truncationMode(.tail)
                                        Text("0.00")
                                            .font(.subheadline)
                                            .frame(alignment: .leading)
                                            .truncationMode(.tail)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Image(systemName: "arrow.right")
                                        .symbolVariant(.circle)
                                        .symbolVariant(.fill)
                                        .padding(15)
                                }
                                .font(.headline)
                                .foregroundColor(Color.white)
                                .frame(height: 60)
                                .background(Color(red: 24/255, green: 148/255, blue: 232/255))
                                .cornerRadius(4)
                            }
                            ForEach(wallet.balances, id:\.id) { balance in
                                Button(action: {
                                    selectedWalletAndBalance = WalletAndBalance(
                                        wallet: wallet,
                                        balance: balance
                                    )
                                }) {
                                    HStack {
                                        self.getTokenIcon(tokenSymbol: balance.token.symbol)
                                            .frame(height: 30)
                                            .padding(10)
                                        VStack(alignment: .leading) {
                                            Text("\(balance.token.symbol)")
                                                .frame(alignment: .leading)
                                                .truncationMode(.tail)
                                                                                        
                                            Text("\(balance.amount)")
                                                .font(.subheadline)
                                                .frame(alignment: .leading)
                                                .truncationMode(.tail)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Image(systemName: "arrow.right")
                                            .symbolVariant(.circle)
                                            .symbolVariant(.fill)
                                            .padding(15)
                                        
                                    }
                                    .font(.headline)
                                    .foregroundColor(Color.white)
                                    .frame(height: 60)
                                    .background(Color(red: 24/255, green: 148/255, blue: 232/255))
                                    .cornerRadius(4)
                                }
                                
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                        .padding()
                    }
                    .sheet(item: $selectedWalletAndBalance, onDismiss: {
                        selectedWalletAndBalance = nil
                        
                    }) { walletAndBalance in
                        SendTransactionView(blockchain: walletAndBalance.wallet.blockchain, tokenId: walletAndBalance.balance.token.id, walletId: walletAndBalance.wallet.id) { result in
                            showToast(.success, message: result)
                            print(result)
                        }
                    }
                    Spacer()
                    
                    Button(action: authViewModel.signOut) {
                        Text("SIGN OUT")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 24/255, green: 148/255, blue: 232/255))
                            .cornerRadius(5)
                            .padding()
                    }
                }
                .toolbar(content: {
                    Image("circle-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding([.top, .bottom], 10)
                })
            }
            .refreshable {
                await circleWalletViewModel.getWalletsAsync()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 225/255, green: 223/255, blue: 232/255))
            .navigationViewStyle(StackNavigationViewStyle())
            .task{
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                    await circleWalletViewModel.getWalletsAsync()
                }
            }
            .toast(message: toastMessage ?? "",
                   isShowing: $showToast,
                   config: toastConfig)
        }
    }
    
}

extension HomeView {
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
    
    func getTokenIcon(tokenSymbol: String) -> some View {
        let imageName: String
        switch tokenSymbol {
        case "AVAX-FUJI", "AVAX":
            imageName = "icon-AVAX"
        case "MATIC-MUMBAI", "MATIC":
            imageName = "icon-MATIC"
        case "USDC":
            imageName = "icon-USDCoin"
        case "ETH-GOERLI", "ETH":
            imageName = "icon-ETH"
        default:
            imageName = ""
        }
        
        return Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(.leading, 10)
    }
}

/// A generic view that shows images from the network.
struct NetworkImage: View {
    let url: URL?
    
    var body: some View {
        if let url = url,
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let wallets = [
            CircleWalletViewModel.UserWallet(id: "0189bc50-65c7-72f8-94ab-8929130b379a", state: "LIVE", walletSetId: "0189bc50-65a4-762a-ada8-a03d1755a348", custodyType: "ENDUSER", userId: "9d9c661c-dcb0-4e3c-ae5c-6f3604ff46d2", address: "0x637e692da42405768e053585fdf4fdb25a5fa343", blockchain: "MATIC-MUMBAI", accountType: "EOA", updateDate: "2023-08-03T16:52:12Z", createDate: "2023-08-03T16:52:12Z", balances: [
                CircleWalletViewModel.TokenBalance(token: CircleWalletViewModel.Token(id: "e4f549f9-a910-59b1-b5cd-8f972871f5db", blockchain: "MATIC-MUMBAI", tokenAddress: nil, standard: nil, name: "Polygon-Mumbai", symbol: "MATIC-MUMBAI", decimals: 18, isNative: true, updateDate: "2023-06-29T02:37:14Z", createDate: "2023-06-29T02:37:14Z"), amount: "0.1", updateDate: "2023-08-04T04:20:54Z"),
                CircleWalletViewModel.TokenBalance(token: CircleWalletViewModel.Token(id: "38f2ad29-a77b-5a44-be05-8d03923878a2", blockchain: "MATIC-MUMBAI", tokenAddress: Optional("0x0fa8781a83e46826621b3bc094ea2a0212e71b23"), standard: Optional("ERC20"), name: "USD Coin (PoS)", symbol: "USDC", decimals: 6, isNative: false, updateDate: "2023-06-30T04:46:30Z", createDate: "2023-06-30T04:46:30Z"), amount: "0.1", updateDate: "2023-08-03T23:22:42Z"),
                CircleWalletViewModel.TokenBalance(token: w3s_ios_sample_app_wallets.CircleWalletViewModel.Token(id: "5ceaffbb-61f4-5e65-b1a7-13aa306e450a", blockchain: "MATIC-MUMBAI", tokenAddress: Optional("0x14c63920df84f306dcd5bfc84a1a3a6270016a24"), standard: Optional("ERC20"), name: "VanityTron.io", symbol: "VanityTron.io", decimals: 0, isNative: false, updateDate: "2023-07-27T15:27:40Z", createDate: "2023-07-27T15:27:40Z"), amount: "6666666", updateDate: "2023-08-04T04:20:54Z")
            ]),
            CircleWalletViewModel.UserWallet(id: "0189bc50-65c7-7307-9673-04b6ad2e2afb", state: "LIVE", walletSetId: "0189bc50-65a4-762a-ada8-a03d1755a348", custodyType: "ENDUSER", userId: "9d9c661c-dcb0-4e3c-ae5c-6f3604ff46d2", address: "0x637e692da42405768e053585fdf4fdb25a5fa343", blockchain: "AVAX-FUJI", accountType: "EOA", updateDate: "2023-08-03T16:52:12Z", createDate: "2023-08-03T16:52:12Z", balances: []),
            CircleWalletViewModel.UserWallet(id: "0189bc50-65c7-78c1-afaa-4d1f9c0b9a21", state: "LIVE", walletSetId: "0189bc50-65a4-762a-ada8-a03d1755a348", custodyType: "ENDUSER", userId: "9d9c661c-dcb0-4e3c-ae5c-6f3604ff46d2", address: "0x637e692da42405768e053585fdf4fdb25a5fa343", blockchain: "ETH-GOERLI", accountType: "EOA", updateDate: "2023-08-03T16:52:12Z", createDate: "2023-08-03T16:52:12Z", balances: [])
        ]
        
        HomeView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject({ () -> CircleWalletViewModel in
                let circleWalletViewModel = CircleWalletViewModel()
                circleWalletViewModel.userWallets = wallets
                return circleWalletViewModel
            }() )
    }
}


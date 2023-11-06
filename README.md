# Overview

The Digital Wallet App serves as a demonstration of integrating social sign-in functionality with web3 wallet generation. Upon a successful user authentication, the app automatically generates a web3 wallet, linking it to the authenticated user account. Beyond this, the app supports token transaction fuctionality, allowing users to send and receive tokens, coupled with a fee estimator for customizing transaction speeds.

### Prerequisites

* Sign up for the Circle Developer account here: https://console.circle.com/signup.
* Make sure you have [Xcode](https://apps.apple.com/tw/app/xcode/id497799835?mt=12) installed for iOS app developement.
* Ensure you have [Node.js](https://nodejs.org/en/download) and [NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) installed.
* Ensure you have [CocoaPods](https://formulae.brew.sh/formula/cocoapods) installed for managing iOS dependencies

### Setup Instructions
#### Frontend(iOS)
1. Navigate to the iOS App Directory
    ```bash
    cd frontend/w3s-ios-sample-app-wallets
    ```

2. Install the Dependencies
   Run the following command to install the `CircleProgrammableWalletSDK`:
    ```bash
    pod install
    ```

3. Open the App in Xcode
   Once the dependencies are installed, open the `.xcworkspace` file:
   ```bash
    open w3s-ios-sample-app-wallets.xcworkspace
    ```

4. Insert your App ID
   In Xcode, navigate to the `ContentView` file inside the `Views` folder. Replace the placeholder with your actual App ID obtained from the web3 developer console. 

5. Set Up Google Sign-In
   a. Download the `GoogleService-Info.plist`
   Navigate to the Google Developers Console, create or select a project, then enable the Google Sign-In API. Once done, you will be prompted to donwload a configuration file: `GoogleService-Info.plist`.
   b. Add `GoogleService-Info.plist` to your Xcode project.
   Ensure that the file is included in your app target.
   c. Configure URL Schemes
   Open the `Info.plist` in your Xcode project and look for the `URL Types` key. Add a new item with your reversed client ID from the `GoogleService-Info.plist`. This step ensures that after the sign-in, the app will handle the redirect back to your application correctly.

#### Backend(NextJS)
1. Navigate to the Backend Directory
    ```bash
    cd backend
    ```

2. Install the Dependencies
   Install the required packages for the backend using the following command:
    ```bash
    mpn install
    ```

3. Configure Environment Variables
   In the root of the backend directory, create a `.env` file:
   ```bash
    touch .env
    ```

    Populate the `.env` file with the following content:
    ```bash
    CIRCLE_API_KEY="YOUR_API_KEY_HERE"
    CIRCLE_BASE_URL="https://api.circle.com/v1/w3s"
    ```
    Ensure you replace `YOUR_API_KEY_HERE` with your actual API key.

## Running the App

### Frontend (iOS)

1. Run the App on a Simulator or Device
   With the `.xcworkspace` open in Xcode, select your target simulator or device, then press the play button to compile and run the app.

### Backend(NextJS)

1. Start the NextJS Server
   Initiate the backend server using:
   ```bash
    npm run dev
    ```

If you have questions, comments, or need help with code, we're here to help:

* on [Discord](https://discord.com/invite/buildoncircle)
* on Twitter at [@BuildOnCircle](https://twitter.com/BuildOnCircle)

Check out our [developer docs](https://developers.circle.com/w3s/docs).

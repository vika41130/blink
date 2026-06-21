# Vapor

A private messaging app with auto-deleting messages.

## Prerequisites

- Flutter SDK 3.29+
- Dart SDK
- Xcode (for iOS)
- Android Studio (for Android)
- CocoaPods (for iOS dependencies)
- Firebase CLI
- Node.js 20+ (for Cloud Functions)

## Setup

```bash
# Clone and enter project
cd vapor

# Get Flutter dependencies
flutter pub get

# iOS: Install pods
cd ios
pod install
cd ..

# Generate localizations (if needed)
flutter gen-l10n
```

## Run

```bash
# Run on connected device or simulator
flutter run

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Analyze code
flutter analyze
```

## Firebase Cloud Functions

```bash
# Install function dependencies
cd functions
npm install
cd ..

# Set email secrets (for verification emails)
# First, enable Secret Manager API at:
# https://console.developers.google.com/apis/api/secretmanager.googleapis.com/overview?project=blink-59a7b
firebase functions:secrets:set EMAIL_USER --project blink-59a7b
firebase functions:secrets:set EMAIL_PASS --project blink-59a7b

# Deploy functions
firebase deploy --only functions --project blink-59a7b
```

## Build

```bash
# Build APK (Android)
flutter build apk --release

# Build iOS
flutter build ios --release
```

## Xcode Build (iOS)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your target device or simulator
3. Set your Team under Signing & Capabilities (Runner > Signing & Capabilities)
4. Set Bundle Identifier to your own (e.g. `com.yourname.vapor`)
5. Product > Build (Cmd+B)
6. Product > Run (Cmd+R)

If pod issues occur:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

## Xcode Release Build (App Store / TestFlight)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Set scheme to `Runner` and device to `Any iOS Device (arm64)`
3. Edit scheme (Product > Scheme > Edit Scheme) > set Build Configuration to `Release`
4. Product > Archive
5. Once archive completes, Organizer window opens
6. Select the archive > Distribute App
7. Choose distribution method (App Store Connect / TestFlight)
8. Follow prompts to upload

Before archiving, ensure:
- Valid Apple Developer account is signed in
- Correct provisioning profile is set
- Version and build number are incremented in Runner > General

## Android Release Build (Play Store)

1. Create a keystore (one time only):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties`:
```
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=/Users/<your-username>/upload-keystore.jks
```

3. Build release APK or App Bundle:
```bash
# APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

4. Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

5. Upload the `.aab` file to Google Play Console

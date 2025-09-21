# Event Marketplace App - iOS Deployment Guide

## 🍎 iOS Build and Deployment

This guide provides complete instructions for building and deploying the Event Marketplace App to iOS App Store.

## 📋 Prerequisites

### Required Software (macOS only)
- **Xcode 15.0+** - Download from Mac App Store
- **CocoaPods** - Install with `sudo gem install cocoapods`
- **fastlane** - Install with `sudo gem install fastlane`
- **Flutter 3.35.3+** - Follow [Flutter installation guide](https://flutter.dev/docs/get-started/install/macos)

### Apple Developer Account
- **Apple Developer Program** membership ($99/year)
- **App Store Connect** access
- **Certificates and Provisioning Profiles** configured

## 🚀 Quick Start

### 1. Build and Archive
```bash
# Make scripts executable
chmod +x ios/build_archive.sh
chmod +x ios/export_ipa.sh

# Build archive
./ios/build_archive.sh

# Export IPA
./ios/export_ipa.sh
```

### 2. Using fastlane
```bash
cd ios

# Build and upload to App Store
fastlane release

# Build and upload to TestFlight
fastlane beta

# Build for development
fastlane development
```

### 3. Using Codemagic CI/CD
The project includes `codemagic.yaml` with pre-configured workflows:
- `ios-release` - Production App Store build
- `ios-testflight` - TestFlight beta build
- `android-release` - Google Play Store build
- `web-release` - Web deployment
- `windows-release` - Windows Store build

## 📱 App Configuration

### Bundle Identifier
- **Production**: `com.eventmarketplace.app`
- **Development**: `com.eventmarketplace.app.dev`

### App Information
- **Name**: Event Marketplace
- **Version**: 1.0.0
- **Build**: 1
- **Category**: Lifestyle
- **Minimum iOS**: 11.0

### Permissions
The app requests the following permissions:
- **Location** - Show nearby events and services
- **Camera** - Take photos for events and profiles
- **Photo Library** - Select images for events and profiles
- **Microphone** - Video calls and voice messages

## 🔧 Configuration Files

### Info.plist
- App display name and bundle identifier
- Required permissions with usage descriptions
- URL schemes for Firebase authentication
- Supported interface orientations

### GoogleService-Info.plist
- Firebase configuration for iOS
- Authentication, Firestore, and messaging setup
- **Note**: Replace with your actual Firebase project configuration

### Entitlements
- **Runner.entitlements** - Development push notifications
- **Runner-Release.entitlements** - Production push notifications
- Associated domains for deep linking

### Podfile
- iOS 11.0+ minimum deployment target
- Firebase pods for all services
- Image handling with SDWebImage
- Networking with Alamofire

## 🏗️ Build Process

### Manual Build
1. **Clean and get dependencies**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Install CocoaPods**:
   ```bash
   cd ios
   pod install --repo-update
   cd ..
   ```

3. **Build Flutter app**:
   ```bash
   flutter build ios --release --no-tree-shake-icons
   ```

4. **Create archive**:
   ```bash
   cd ios
   xcodebuild -workspace Runner.xcworkspace \
              -scheme Runner \
              -configuration Release \
              -archivePath build/Runner.xcarchive \
              archive
   ```

5. **Export IPA**:
   ```bash
   xcodebuild -exportArchive \
              -archivePath build/Runner.xcarchive \
              -exportPath build/ipa \
              -exportOptionsPlist build/ExportOptions.plist
   ```

### Automated Build (fastlane)
```bash
cd ios
fastlane release
```

## 📦 App Store Connect Setup

### Required Information
1. **App Information**:
   - App name: Event Marketplace
   - Subtitle: Find and book events and services
   - Category: Lifestyle
   - Content rights: Yes

2. **Pricing and Availability**:
   - Price: Free
   - Availability: All countries/regions

3. **App Privacy**:
   - Data collection practices
   - Privacy policy URL: https://eventmarketplace.app/privacy

### Required Assets
1. **App Icon**: 1024x1024px (provided in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
2. **Screenshots**:
   - iPhone 6.7" (iPhone 14 Pro Max): 1290x2796px
   - iPhone 6.5" (iPhone 11 Pro Max): 1242x2688px
   - iPhone 5.5" (iPhone 8 Plus): 1242x2208px
   - iPad Pro 12.9": 2048x2732px
   - iPad Pro 11": 1668x2388px

3. **App Preview Videos** (optional but recommended):
   - iPhone 6.7": 1290x2796px, 15-30 seconds
   - iPad Pro 12.9": 2048x2732px, 15-30 seconds

## 🔐 Code Signing

### Automatic Signing
The project is configured for automatic code signing:
- Development Team ID: `$(DEVELOPMENT_TEAM)`
- Bundle Identifier: `com.eventmarketplace.app`
- Provisioning Profile: Automatic

### Manual Signing
If you need manual signing:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project
3. Go to Signing & Capabilities
4. Uncheck "Automatically manage signing"
5. Select your Team and Provisioning Profile

## 🚨 Troubleshooting

### Common Issues

1. **"No iOS development team specified"**:
   - Set your Apple Developer Team ID in Xcode
   - Or add `DEVELOPMENT_TEAM` environment variable

2. **"Provisioning profile doesn't match"**:
   - Ensure bundle identifier matches in App Store Connect
   - Regenerate provisioning profiles

3. **"Firebase configuration not found"**:
   - Replace `GoogleService-Info.plist` with your actual Firebase config
   - Ensure it's added to the Xcode project

4. **"CocoaPods dependencies not found"**:
   - Run `cd ios && pod install --repo-update`
   - Clean and rebuild: `flutter clean && flutter pub get`

5. **"Archive validation failed"**:
   - Check that all required permissions are in Info.plist
   - Ensure app icons are properly configured
   - Verify bundle identifier matches App Store Connect

### Build Logs
- **Xcode build logs**: `/tmp/xcodebuild_logs/`
- **Flutter logs**: `flutter_drive.log`
- **Codemagic logs**: Available in Codemagic dashboard

## 📞 Support

For issues with:
- **Flutter**: [Flutter documentation](https://flutter.dev/docs)
- **iOS development**: [Apple Developer documentation](https://developer.apple.com/documentation)
- **Firebase**: [Firebase documentation](https://firebase.google.com/docs)
- **fastlane**: [fastlane documentation](https://docs.fastlane.tools)

## 🎯 Next Steps

After successful build:

1. **Upload to App Store Connect**:
   - Use Xcode Organizer or Application Loader
   - Or use fastlane: `fastlane release`

2. **Configure App Store listing**:
   - Add app description and keywords
   - Upload screenshots and app preview videos
   - Set pricing and availability

3. **Submit for review**:
   - Complete all required information
   - Submit for App Store review
   - Wait for Apple's approval (typically 24-48 hours)

4. **Release**:
   - Once approved, release to App Store
   - Monitor crash reports and user feedback
   - Plan future updates

---

**Ready to build! 🚀**

Run `./ios/build_archive.sh` to start the build process.

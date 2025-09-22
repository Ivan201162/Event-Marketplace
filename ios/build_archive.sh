#!/bin/bash

# iOS Archive Build Script for Event Marketplace App
# Run this script on macOS with Xcode installed

set -e

echo "🍎 Building iOS Archive for Event Marketplace App..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Install CocoaPods dependencies
echo "📦 Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

# Build iOS app
echo "🔨 Building iOS app..."
flutter build ios --release --no-tree-shake-icons

# Create archive
echo "📦 Creating archive..."
cd ios
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath build/Runner.xcarchive \
           archive

echo "✅ Archive created successfully at: ios/build/Runner.xcarchive"
echo "📱 Ready for App Store submission!"




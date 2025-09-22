#!/bin/bash

# iOS IPA Export Script for Event Marketplace App
# Run this script on macOS with Xcode installed

set -e

echo "🍎 Exporting IPA for Event Marketplace App..."

# Check if archive exists
if [ ! -d "build/Runner.xcarchive" ]; then
    echo "❌ Archive not found. Please run build_archive.sh first."
    exit 1
fi

# Create export options plist
echo "📝 Creating export options..."
cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>\$(DEVELOPMENT_TEAM)</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

# Export IPA
echo "📦 Exporting IPA..."
xcodebuild -exportArchive \
           -archivePath build/Runner.xcarchive \
           -exportPath build/ipa \
           -exportOptionsPlist build/ExportOptions.plist

echo "✅ IPA exported successfully!"
echo "📱 IPA location: ios/build/ipa/Runner.ipa"
echo "🚀 Ready for App Store Connect upload!"




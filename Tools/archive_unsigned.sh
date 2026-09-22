#!/bin/sh
# Archive rồi zip Payload. Không gọi exportArchive.
set -e
cd "$(dirname "$0")/.."
command -v xcodebuild >/dev/null 2>&1 || {
  echo "xcodebuild không có trên máy này. Chạy script trên Mac đã cài Xcode."
  exit 127
}
rm -rf build/Meine.xcarchive build/Payload build/Meine-unsigned.ipa
xcodebuild archive \
  -project Meine.xcodeproj \
  -scheme Meine \
  -configuration Release \
  -archivePath build/Meine.xcarchive \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  DEVELOPMENT_TEAM= \
  CODE_SIGN_ENTITLEMENTS= \
  EXPANDED_CODE_SIGN_IDENTITY= \
  ENABLE_PREVIEWS=NO \
  ENABLE_ON_DEMAND_RESOURCES=NO \
  ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOLS=NO \
  ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS=NO \
  COMPILER_INDEX_STORE_ENABLE=NO
mkdir -p build/Payload
cp -R build/Meine.xcarchive/Products/Applications/*.app build/Payload/
cd build
zip -r Meine-unsigned.ipa Payload
echo "IPA: $(pwd)/Meine-unsigned.ipa"

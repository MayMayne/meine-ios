# Build IPA unsigned

Máy viết code không có Xcode. Bạn build trên Mac.

## Mở project

Mở `Meine.xcworkspace` hoặc `Meine.xcodeproj`. Không cần Swift Package, không cần CocoaPods. Asset catalog và framework hệ thống đã nằm trong target.

Signing đã tắt trong project (`CODE_SIGNING_ALLOWED = NO`). Nếu Xcode vẫn đòi team, chọn Signing & Capabilities → bỏ Automatically manage signing.

## Lệnh

```
xcodebuild -project Meine.xcodeproj -scheme Meine -configuration Release -destination 'generic/platform=iOS' -archivePath build/Meine.xcarchive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" archive
```

Nếu scheme chưa có, Xcode tạo scheme Meine từ target cùng tên, hoặc thêm `-target Meine` thay `-scheme`.

Đóng gói:

```
mkdir -p build/Payload
cp -R build/Meine.xcarchive/Products/Applications/Meine.app build/Payload/
cd build && zip -r Meine-unsigned.ipa Payload
```

IPA này không cài bằng Finder, Apple Configurator hay Device Management.

- TrollStore: cài thẳng, không cần ký lại.
- Sideloadly, SideStore hoặc AltStore: tool tự ký lúc cài.
- Jailbreak có AppSync Unified: cài như gói thường.

## Chạy nguồn mẫu

Trong app: Nhà → Thêm nguồn → chọn thư mục `docs/examples/local-demo`. Manifest đọc được. File mp4/m4a mẫu không có trong repo, nên nút phát báo thiếu media cho đến khi bạn bỏ file đúng href.

## Giới hạn bản này

- EQ lưu 10 băng, chưa gắn AudioUnit vào AVPlayer.
- Dịch AI soạn prompt và đưa sang app khác. Không gọi API.
- TTS chưa đọc thành tiếng. Bảng note đã có.
- Drive, OneDrive, WebDAV chưa có màn đăng nhập. HTTP href trong catalog vẫn phát được.
- Ảnh icon app chưa có.

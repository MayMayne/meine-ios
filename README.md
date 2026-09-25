# Meine

App iOS giải trí bốn phân hệ. Không nguồn cố định. Bản này là khung 0.1.0.

## Đang chạy được sau khi build

- Ba tab: Nhà, Thư viện, Cài đặt.
- Thêm thư mục qua Files. App nhớ bookmark.
- Nhận phim, mùa phim, album nhạc (một cấp nghệ sĩ), chương tranh, epub/txt.
- Nguồn bật khoá thì ẩn tên trên Nhà. Face ID thật chưa gắn — nút mở chỉ là cổng tạm.

## Chưa có

Player, reader, EQ, dịch, JavaScriptCore, WebDAV, backup `.meinebackup`.

## Build IPA không ký

Đẩy repo này lên GitHub, vào Actions, chạy `Build Unsigned IPA` trên runner `macos-latest`, tải artifact `unsigned-ipa`.

Cài bằng TrollStore. Sideloadly / SideStore / AltStore sẽ ký lại lúc cài. IPA không ký không cài được qua Finder.

Máy iSH không có Xcode nên không compile tại chỗ.

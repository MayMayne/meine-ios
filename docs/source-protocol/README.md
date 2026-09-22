# Giao thức nguồn Meine

Tài liệu này là hợp đồng giữa app và người phát triển nguồn. Làm đúng các file dưới đây là nguồn chạy được, không cần sửa app.

## Đọc theo thứ tự

1. [Bắt đầu trong 15 phút](01-quickstart.md) — một nguồn local tối thiểu.
2. [manifest.json](02-manifest.md) — danh tính, theme, trang chủ, tính năng.
3. [Catalog](03-catalog.md) — phim, nhạc, tranh, chữ.
4. [Resolver và URL](04-resolver.md) — local, HTTP, Drive, template.
5. [Trang chủ](05-home-layout.md) — tuỳ chỉnh giao diện trang chủ.
6. [Mật khẩu và quyền](06-auth.md)
7. [Lyric, phụ đề, chương](07-sidecars.md)
8. [Tính năng player được phép bật](08-capabilities.md)
9. [Lỗi, phân trang, cache](09-errors-and-paging.md)
10. [Ví dụ đầy đủ](../examples/)

## Một nguồn là gì

Một thư mục (hoặc một URL gốc) có ít nhất:

```
meine-source/
  manifest.json          # bắt buộc
  catalog/
    home.json            # khuyên dùng: dữ liệu cho các khối trang chủ
    movies.json          # tuỳ loại nguồn có
    music.json
    comics.json
    books.json
  media/                 # nếu là nguồn local
  artwork/
  lyrics/
  subtitles/
```

App nhận nguồn bằng một trong các cách:

- Chọn thư mục local (Files, iCloud, On My iPhone).
- Dán URL tới `manifest.json`.
- Dán URL gốc; app tự thử `{gốc}/manifest.json`.
- Quét file `.meine-source` (JSON ngắn trỏ tới URL gốc + tên hiển thị).
- Nhập connector đám mây (Drive / OneDrive / WebDAV) rồi trỏ tới thư mục chứa `manifest.json`.

## Phiên bản

Hiện tại: **schema 1**. Mọi file JSON phải có `"schemaVersion": 1` ở manifest. Catalog kế thừa version của manifest nếu không ghi riêng.

# Resolver và nơi chứa file

App không quan tâm file nằm ở Drive, ổ máy hay CDN. Nó chỉ cần biến `href` thành một URL hoặc file URL mà AVFoundation / trình tải ảnh / trình đọc chữ mở được.

## href hợp lệ

1. Tương đối: `media/a.mp4` — tính từ gốc nguồn.
2. Tuyệt đối https: `https://cdn.example/a.mp4`.
3. Template: xem dưới.
4. `href` dạng `connector://...` chỉ do app sinh ra, nguồn không tự bịa scheme lạ.

Cấm: `file://` trỏ ra ngoài root nguồn, `..`, URL không có scheme lẫn không phải path tương đối.

## Template

Trong manifest:

```json
{
  "endpoints": {
    "catalog": "https://api.example/meine/catalog/",
    "mediaTemplate": "https://cdn.example/{path}?token={token}"
  }
}
```

Item:

```json
{ "media": { "href": "movies/a.m3u8", "mime": "application/vnd.apple.mpegurl" } }
```

App thay `{path}` bằng href đã encode, `{token}` bằng token trong AuthVault nếu có. Thiếu token mà template cần → mở màn hình khoá, không gọi URL hỏng.

Biến cho phép: `{path}` `{ref}` `{id}` `{token}` `{lang}`. Biến lạ để nguyên và báo lỗi nguồn.

## Resolve động

Khi link sống vài phút (signed URL), manifest đặt:

```json
{ "endpoints": { "resolve": "https://api.example/meine/resolve" } }
```

App POST JSON:

```json
{
  "ref": "movie:demo",
  "chapterId": null,
  "intent": "play"
}
```

`intent`: `play` | `download` | `artwork` | `subtitle` | `lyrics` | `page`.

Response 200:

```json
{
  "url": "https://cdn.example/signed.m3u8?sig=...",
  "expiresAt": "2026-09-22T03:00:00Z",
  "headers": { "Authorization": "Bearer ..." }
}
```

App cache URL đến `expiresAt` trừ 30 giây. Hết hạn thì resolve lại, không làm giật player nếu đang có buffer.

`headers` chỉ gắn vào request media của item đó, không gửi sang domain khác.

## Local

User chọn thư mục. App giữ security-scoped bookmark. Moij href tương đối mở trong thư mục đó. Đây là đường nhanh nhất và ổn định nhất: không mạng, không token.

Gợi ý cho người đóng gói nguồn local:

- MP4 faststart.
- Ảnh đã resize.
- Một `manifest.json`, không symlink ra ngoài.
- Tên file ASCII hoặc UTF-8 NFC. Tránh `:` và `/` trong tên file.

## HTTP tĩnh

Đưa cả thư mục lên bất kỳ host nào phục vụ file tĩnh (nginx, S3, GitHub raw không khuyến nghị vì rate limit, Cloudflare R2…). URL nguồn = URL của `manifest.json` bỏ tên file, hoặc URL file manifest.

App gửi `Accept-Encoding: gzip` và tôn trọng `ETag` / `Last-Modified`. Nguồn nên bật gzip cho JSON.

## WebDAV

User nhập gốc WebDAV + tài khoản trong màn hình connector. Manifest nằm trong một thư mục WebDAV. App dùng PROPFIND có Depth giới hạn, không đệ quy cả ổ.

## Google Drive và OneDrive

App có connector sẵn (tuỳ phiên bản build). Người phát triển nguồn **không** nhúng client secret vào manifest.

Cách làm đúng:

1. User tự đăng nhập Drive/OneDrive trong Meine.
2. Chọn thư mục đã chia sẻ hoặc thư mục của họ, bên trong có `manifest.json`.
3. App tải JSON qua API chính thức, media qua link tạm của connector, rồi đưa vào cùng player.

Cách làm cũng đúng nếu bạn tự xuất file ra CDN và chỉ để href https trong catalog — khi đó không cần connector.

Không hỗ trợ: dán link chia sẻ Drive của từng file lẻ mà không có manifest. App cần catalog để biết chương, lyric, thứ tự.

## Ổn định

- Timeout catalog: 15 giây, 2 lần retry, backoff 0.5s / 1.5s.
- Timeout byte đầu của media: 10 giây rồi báo, player giữ vị trí.
- Ảnh: tối đa 4 request song song.
- Đổi mạng giữa chừng: AVPlayer tự leo lại HLS; file progressive thì app tua lại từ byte đã có nếu server hỗ trợ Range. Nguồn nên bật `Accept-Ranges: bytes`.
- HTTP 206 là bắt buộc nếu muốn tua file MP4/MP3 lớn. Không có Range, app vẫn phát nhưng tua sẽ tải lại.

## Kiểm tra trước khi phát hành nguồn

- [ ] Mọi href tương đối tồn tại.
- [ ] HLS có playlist đủ variant, hoặc một variant 720p.
- [ ] Ảnh trả `Content-Type` đúng.
- [ ] JSON validate với schema (app có nút Kiểm tra nguồn).
- [ ] `ref` không trùng, không đổi giữa hai version trừ khi bạn cố ý làm mất tiến độ.

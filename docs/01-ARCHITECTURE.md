# Kiến trúc

```
┌─────────────────────────────────────────────┐
│  SwiftUI  Home / Library / Players          │
├─────────────────────────────────────────────┤
│  Feature flags từ nguồn + override người dùng│
├─────────────────────────────────────────────┤
│  SourceRuntime                              │
│    ManifestLoader → Catalog → Resolver      │
│    AuthVault (mật khẩu, token)              │
│    MediaCache + Prefetch                    │
├─────────────────────────────────────────────┤
│  Connectors (chỉ app ship, không phải plugin)│
│    local · http(json) · webdav · gdrive*    │
│    onedrive* · custom URL template          │
└─────────────────────────────────────────────┘
* Connector đám mây là tuỳ chọn, bật khi user đăng nhập.
```

## Vì sao không cho nguồn chạy code

Chạy JavaScript/WASM của người lạ trên iOS vừa chậm vừa không an toàn. Meine chọn **dữ liệu khai báo**:

- `manifest.json` — nguồn là ai, có những loại nào, trang chủ trông thế nào.
- `catalog/*.json` — danh sách tác phẩm.
- URL template — cách ghép link stream, ảnh, lyric.
- Connector có sẵn trong app — cách nói chuyện với local, HTTP, WebDAV, Drive.

Người phát triển nguồn muốn logic riêng (ký URL, phân trang lạ) thì đặt một **HTTP endpoint** trả về đúng schema catalog. App chỉ gọi HTTP, không nhúng code của họ.

## Luồng mở một tác phẩm

1. Đọc manifest (cache, ETag).
2. Vẽ trang chủ từ `home.layout` — không chờ hết catalog.
3. User chọn item → `Resolver` đổi `ref` thành URL phát được (local file, HTTP, signed URL).
4. Player nhận `Playable` đã chuẩn hóa. Player không biết nguồn là Drive hay ổ máy.
5. Lỗi mạng: hiện trạng thái, giữ UI, retry có backoff. Không crash.

## Hợp đồng ổn định

- Schema có `schemaVersion`. App hỗ trợ N và N-1.
- Field lạ bị bỏ qua, không làm hỏng parse.
- Field bắt buộc thiếu → nguồn đó vào trạng thái lỗi, các nguồn khác vẫn chạy.
- Mọi list đều phân trang (`cursor`). App không tải cả catalog một lần nếu nguồn bảo là lớn.

## Cache

| Thứ | Ở đâu | Hết hạn |
| --- | --- | --- |
| Manifest | Application Support | theo `cacheTtl`, mặc định 1 giờ |
| Trang catalog | cùng chỗ + bộ nhớ | theo `cacheTtl` |
| Ảnh bìa | Cache directory, LRU | 200 MB mặc định |
| Media đang phát / đã tải | Cache hoặc Documents nếu user tải offline | user xoá |
| Tiến độ, thư viện, playlist | SwiftData, máy user | không hết hạn |

Mọi request có `Task` hủy được. Đổi nguồn hoặc rời màn hình thì hủy.

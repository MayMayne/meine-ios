# Lỗi, phân trang, cache

App phải sống khi nguồn hỏng một phần. Quy tắc này là bắt buộc với người phát triển nguồn lẫn với code app.

## Phân trang

File catalog lớn trả về một trang:

```json
{
  "schemaVersion": 1,
  "nextCursor": "eyJvIjo1MH0",
  "items": []
}
```

Trang sau: cùng URL cộng `cursor` bằng giá trị `nextCursor`. Local thì file kế tiếp `catalog/music.2.json` và `nextCursor` là tên file đó, tương đối.

- Một trang nên dưới 200 item và dưới 500 KB JSON.
- `nextCursor` không hết hạn trong ngày. Hết hạn thì trả trang đầu, đừng trả 500.
- Không đổi `ref` của item chỉ vì nó sang trang khác.

## Mã lỗi HTTP

| Mã | App làm |
| --- | --- |
| 200 | Parse |
| 204 | Trang trống hợp lệ |
| 304 | Dùng cache |
| 401 | Hỏi lại token, giữ UI |
| 403 | Báo không có quyền, không retry vòng lặp |
| 404 | Mục này không còn. Ẩn thẻ, không xoá thư viện user |
| 429 | Đọc `Retry-After`, tối đa 60 giây, rồi thử một lần |
| 5xx | Retry 2 lần rồi báo nguồn tạm lỗi |

Body lỗi JSON nếu có:

```json
{ "error": { "code": "gone", "message": "Đã gỡ" } }
```

`message` là câu cho người, không phải stack trace.

## Parse

- JSON hỏng: nguồn vào trạng thái lỗi, nguồn khác vẫn chạy.
- Item thiếu `title` hoặc `kind`: bỏ item đó.
- `kind` lạ: bỏ item.
- Ảnh gãy: thẻ hiện chữ, không hiện ô vỡ layout.
- Media gãy lúc bấm phát: màn hình lỗi trong player, nút thử lại, vị trí cũ được giữ nếu đã có tiến độ.

## Cache

- Tôn trọng `cacheTtl` manifest.
- Gửi `If-None-Match` khi có ETag.
- User kéo để làm mới thì bỏ qua TTL một lần.
- Ảnh LRU, mặc định 200 MB, user sửa được.
- Không cache response 401 và 500.

## Việc app tự làm để mượt, nguồn không phải nhắc

- Không decode ảnh và JSON trên luồng UI.
- Prefetch ảnh của section kế tiếp, không prefetch cả catalog.
- Hủy tải khi rời màn.
- Player tạo lại từ `Playable` chuẩn, không giữ socket của connector khi user đã chuyển bài.
- HLS ưu tiên variant vừa màn hình, không luôn lấy 1080p trên mạng yếu.

## Kiểm tra nguồn trong app

Nút Kiểm tra chạy offline nếu là thư mục local:

- manifest đủ trường
- mọi `ref` trên home có item
- href tương đối tồn tại
- không có `..`
- JSON đủ schemaVersion
- ảnh mẫu mở được

Kết quả là danh sách cảnh báo, không chặn user mở nguồn trừ khi thiếu manifest.

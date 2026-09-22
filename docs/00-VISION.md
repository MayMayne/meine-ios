# Meine — tầm nhìn

Meine là app iOS viết bằng Swift. Người dùng xem phim, nghe nhạc, đọc truyện tranh và truyện chữ. App **không gắn một nguồn nội dung cố định**. Mọi thứ người dùng thấy đến từ một hoặc nhiều **nguồn** do chính họ (hoặc người phát triển nguồn) cung cấp.

## Nguyên tắc không được phá

1. **Nguồn là plugin, app là runtime.** App không giả định API của một website cụ thể. Mọi nguồn nói cùng một hợp đồng (manifest + catalog + resolver).
2. **Mượt và ổn định dù nguồn từ đâu.** API chậm, Drive, file local, hay JSON tĩnh đều đi qua cùng một lớp cache, prefetch và hủy request. UI không bao giờ chờ mạng trên luồng chính.
3. **Người phát triển nguồn được tuỳ chỉnh trang chủ và một phần player**, trong khung an toàn mà app cho phép. Không được chạy mã tùy ý.
4. **Mật khẩu nguồn thuộc về người dùng.** App mã hóa cục bộ. Nguồn không nhận lại mật khẩu đã lưu trừ khi người dùng mở khóa.
5. **Mặc định giao diện:** nền xanh biển pastel + trắng. Người dùng và nguồn có thể đổi theme, nhưng theme mặc định luôn tồn tại và có thể khôi phục.

## Bốn loại nội dung

| Loại | `kind` | Ví dụ |
| --- | --- | --- |
| Phim dài | `video.movie` | phim, tập phim dài |
| Phim ngắn | `video.shortFilm` | clip vài phút, có playlist và album |
| Video ngắn | `video.clip` | feed dọc kiểu TikTok / Reels / Shorts |
| Nhạc | `audio.track` | bài hát, album, playlist |
| Truyện tranh | `comic.series` | page, webtoon |
| Truyện chữ | `text.book` | chương, novel |

Một nguồn có thể chỉ phục vụ một loại, hoặc nhiều loại.

## Ai làm gì

- **App (Meine):** player, thư viện, theme, font, EQ, dịch/TTS UI, bảo mật, cache, offline.
- **Người phát triển nguồn:** catalog, URL media, metadata, layout trang chủ, gợi ý tính năng player, lyric/subtitle nếu có.
- **Người dùng:** thêm nguồn, đặt mật khẩu, thư viện, playlist/danh sách đọc public hoặc private, tinh chỉnh player.

## Ngoài phạm vi của hợp đồng nguồn

App không yêu cầu nguồn phải có tài khoản Meine, server Meine, hay SDK bắt buộc. Một thư mục file JSON + media trên máy đã là một nguồn hợp lệ.

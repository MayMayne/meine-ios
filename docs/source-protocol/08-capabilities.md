# Tính năng player

Khối `capabilities` trong manifest hoặc từng item là gợi ý. User ghi đè được. Mỗi khoá nhận `on`, `off`, hoặc `default`. Thiếu khoá là theo mặc định bên dưới.

Nguồn không khoá cứng tính năng mà máy user vẫn làm được. `off` chỉ là ẩn mặc định.

## Truyện chữ

| Khoá | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `reader.pageTurn` | on | Lật trang |
| `reader.scroll` | on | Cuộn |
| `reader.autoScroll` | on | Cuộn tự động, slider tốc độ |
| `reader.themes` | on | Đen, xám, vàng, be, trắng, xanh lá, slider đậm nhạt |
| `reader.textColor` | on | Màu chữ và slider |
| `reader.customFonts` | on | Font sẵn hoặc otf, ttf user thêm |
| `reader.translate.apps` | on | Google Translate, DeepL, app dịch trên máy |
| `reader.translate.ai` | on | Dịch AI nếu user đã cấu hình |
| `reader.tts` | on | TTS, có bảng note lỗi phát âm |
| `library.add` | on | Thêm vào thư viện |
| `lists.user` | on | Danh sách đọc public hoặc private |

## Nhạc

Mặc định đều on: phát nền, lyric full màn, lyric nửa màn, font riêng, hiệu ứng, màu nền lyric, EQ, ảnh nền user chọn hoặc tự tải, playlist, chia sẻ card lyric.

EQ của app: 10 băng 32, 64, 125, 250, 500, 1k, 2k, 4k, 8k, 16k Hz, thêm preamp. Preset phẳng, giọng, bass, sáng, đêm. Nguồn không gửi hệ số EQ.

## Truyện tranh

Mặc định đều on. Webtoon là chế độ đọc mặc định. Thêm trang lẻ trái sang phải, phải sang trái, trang lẻ dọc. Xoay hướng. Vùng nhấn trái phải, viền, chữ L, Kindle. Nền và đậm nhạt, lề, tự cuộn, hẹn giờ tắt tự cuộn, nhấn giữ để cuộn.

Nguồn chỉ đặt `defaultReading`. Không cấm user đổi hướng.

## Phim

Phim dài, mặc định on nếu làm được: phụ đề, vuốt trái âm lượng, vuốt phải độ sáng, toàn màn hình không viền đen do chrome, chia sẻ khung hình, style sub mềm.

Phim ngắn: user tạo danh sách phát và bỏ danh sách vào album public hoặc private.

Video ngắn: feed dọc, tự chuyển clip. Hành vi tham chiếu TikTok, Reels, Shorts, không chép giao diện của họ.

## Dịch và TTS

Nguồn không gọi API dịch hộ. Dịch thường đi qua app trên máy. Dịch AI dùng ba bảng của user: xưng hô (tên gốc, tên mong muốn, ngôi), prompt theo thể loại, note lỗi để lần sau tránh. TTS có note lỗi phát âm riêng. Chưa cấu hình AI thì nút nói rõ cần nhà cung cấp, không bịa bản dịch.

## Font

User thêm otf, ttf. Font hỏng bị bỏ, không phá font hệ thống. Nguồn không tự cài font im lặng.

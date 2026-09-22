# Player nhạc — ảnh tham khảo

Hai ảnh, cùng 1170×2532.

- `attachments/uploads/photo_9795D10D.png` — nửa màn: artwork, tên bài, lyric một phần, điều khiển.
- `attachments/uploads/photo_FDA710EB.png` — gần full lyric: lời chiếm gần hết, điều khiển vẫn còn ở đáy.

User muốn thêm một bước nữa: **full screen thì thanh menu tạm ẩn luôn**, không chỉ phóng lyric.

## Nửa màn

1. Nền là ảnh bìa phóng lớn, làm mờ và tối. Không phải nền đen đặc như player phim.
2. Hàng trên: đóng bên trái. Bên phải: danh sách, yêu thích, thêm.
3. Ảnh vuông bo góc, tên bài, nghệ sĩ.
4. Vài dòng lyric. Dòng đang hát sáng, dòng quanh mờ.
5. Thanh tiến độ, giờ đã phát và giờ còn lại.
6. Nút: xáo, bài trước, phát, bài sau, lặp.
7. Đáy: thiết bị phát và hàng đợi.

## Full lyric

- Ảnh bìa và tên bài nhường chỗ. Lyric chiếm từ dưới hàng trên đến sát điều khiển.
- Dòng đang hát lớn, nằm khoảng giữa màn. Các dòng khác mờ theo khoảng cách.
- Chạm một dòng để chọn câu, phục vụ chia sẻ card.

## Full screen

- Ẩn hàng trên, thanh tiến độ, hàng nút phát, và hàng thiết bị / hàng đợi.
- Chỉ còn lyric trên nền (ảnh mờ hoặc màu đơn sắc).
- Chạm một lần để thanh menu hiện lại. Chạm lần nữa, hoặc nút thu, thì ẩn tiếp.
- Không tự hiện lại khi chuyển dòng lyric. Chỉ hiện khi user chạm, hoặc khi tua / đổi bài bằng tai nghe nếu hệ thống đòi UI.

Ba mức, không gộp:

| Mức | Artwork + tên | Lyric | Menu điều khiển |
| --- | --- | --- | --- |
| Nửa | hiện | vài dòng | hiện |
| Full lyric | ẩn | chiếm phần giữa | hiện |
| Full screen | ẩn | cả màn | ẩn |

## Không lấy từ ảnh

Tên bài, lời và ảnh bìa trong ảnh chỉ là ví dụ. App không nhúng chúng.

EQ, font, màu nền đơn sắc, hiệu ứng theo LRC/SRT/TTML vẫn ở menu thêm, không đặt lên màn chính.

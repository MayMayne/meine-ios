# Player phim dài — ảnh tham khảo

Ảnh: `attachments/uploads/photo_32F83A21.png` (1170×2532). User xác nhận đây là **player video**, không phải nhạc.

Bố cục đọc từ ảnh:

1. Nền đen toàn màn. Không nền pastel ở player phim.
2. Hàng trên: nút đóng bên trái. Bên phải có các nút phụ (âm thanh, chia sẻ, thêm).
3. Khung phim nằm giữa, sát hai cạnh, không bị app thêm viền đen hai bên. Khoảng đen trên và dưới là phần UI, không phải letterbox do sai tỷ lệ.
4. Phụ đề mềm nằm trong khung, sát mép dưới hình, có nền để đọc trên ảnh sáng.
5. Dưới khung: thời lượng hai bên, thanh tua ở giữa. Trên thanh có mốc chương.
6. Hàng nút: tua lùi, phát/tạm dừng, tua tới. Không phải hàng nút nhạc.
7. Hàng dưới cùng: khóa xoay, PiP, tốc độ, tập tiếp, phụ đề, thu UI.

## Luật khi code

- Gesture ẩn UI: vuốt trái đổi âm lượng, vuốt phải đổi độ sáng. Ảnh này là lúc UI đang hiện.
- Toàn màn hình nghĩa là khung phim sát cạnh, không thêm pillarbox. Phim không đúng tỷ lệ máy thì vẫn giữ pixel, chỉ bỏ chrome.
- Sub mềm hoặc sub user thêm thì đổi được màu, đậm nhạt, font, cỡ, nền chữ. Sub cứng không đụng tới.
- Chia sẻ màn hình lấy khung đang hiện, kèm dòng sub mềm nếu đang bật.
- Nguồn chỉ đưa media và track sub. Không xếp lại nút.

Ảnh chỉ là thước bố cục. Không lấy hình trong phim làm tài sản app.

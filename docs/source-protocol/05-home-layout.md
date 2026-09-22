# Trang chủ do nguồn tuỳ chỉnh

Trang chủ không phải website. Nguồn không gửi HTML, CSS hay JavaScript. Nguồn gửi một cây khối. App vẽ bằng component của Meine, nên mọi nguồn trông cùng một ngôn ngữ thị giác, vẫn khác nhau về thứ tự, nội dung và màu.

Người dùng luôn có tab Thư viện và tab Cài đặt. Nguồn chỉ sở hữu **trang chủ của chính nguồn đó**.

## home trong manifest

Ba cách, chọn một.

### A. File riêng (khuyên dùng)

```json
{ "home": { "ref": "catalog/home.json" } }
```

### B. Nhúng khi trang rất nhỏ

```json
{
  "home": {
    "inline": {
      "title": "Nhà",
      "sections": []
    }
  }
}
```

Chỉ dùng khi dưới khoảng 8 KB. Catalog lớn phải tách file.

### C. Nhiều trang (tab con)

```json
{
  "home": {
    "tabs": [
      { "id": "now", "title": "Hôm nay", "ref": "catalog/home-now.json" },
      { "id": "film", "title": "Phim", "ref": "catalog/home-film.json" },
      { "id": "read", "title": "Đọc", "ref": "catalog/home-read.json" }
    ]
  }
}
```

Tối đa 6 tab. Tab đầu là tab mở sẵn.

## Hình dạng file home

```json
{
  "schemaVersion": 1,
  "title": "Hôm nay",
  "subtitle": "Chào buổi sáng",
  "theme": {
    "accent": "#7EC8C3",
    "background": "#F7FFFE",
    "onBackground": "#16302E",
    "card": "#FFFFFF"
  },
  "sections": [],
  "items": {}
}
```

`theme` ở home ghi đè `theme` manifest cho riêng trang này. Vẫn bị kiểm tra tương phản. Màu mặc định của app khi nguồn không khai báo: nền `#E7F6F4`, thẻ `#FFFFFF`, nhấn `#5BB8B0`, chữ `#1B3331`.

## Các loại section

| `type` | Dùng khi | Trường riêng |
| --- | --- | --- |
| `hero` | 1 tới 5 tác phẩm nổi bật, vuốt ngang | `items` |
| `rail` | Hàng thẻ ngang | `items`, `cardStyle` |
| `grid` | Lưới poster | `items`, `columns` |
| `list` | Hàng dọc có mô tả | `items` |
| `continue` | App điền từ tiến độ máy user | không cần items |
| `banner` | Một câu chữ + nút | `body`, `action` |
| `genreChips` | Chip lọc | `tags` |
| `feed` | Feed video ngắn | `feed` |
| `spacer` | Khoảng thở | `size` |

Section không rõ `type` bị bỏ qua, các section sau vẫn hiện. App không làm trắng cả trang vì một khối lỗi.

### Trường chung của section

| Trường | Ý nghĩa |
| --- | --- |
| `id` | Bắt buộc, duy nhất trong trang |
| `type` | Bắt buộc |
| `title` | Tuỳ chọn |
| `subtitle` | Tuỳ chọn |
| `items` | Mảng item rút gọn hoặc `{ "ref": "..." }` |
| `more` | `{ "title": "Xem hết", "catalog": "catalog/movies.json" }` |

`cardStyle`: `poster` (2:3) | `square` | `wide` (16:9) | `compact`. Mặc định theo kind: nhạc = square, phim/tranh/chữ = poster, clip = wide.

`columns`: 2 hoặc 3. Mặc định 3 trên điện thoại, 4 trên máy ngang. Nguồn không được đặt 1 để phá layout, trừ `list`.

### hero

```json
{
  "id": "hero",
  "type": "hero",
  "items": [
    { "ref": "movie:a", "title": "A", "artwork": "artwork/a.jpg", "kind": "video.movie" }
  ]
}
```

### banner

Không phát media. Dùng cho thông báo của người giữ nguồn.

```json
{
  "id": "note",
  "type": "banner",
  "title": "Lịch cập nhật",
  "body": "Chương mới vào thứ Sáu.",
  "action": { "label": "Xem truyện", "ref": "book:demo" }
}
```

`action` chỉ được trỏ `ref` trong nguồn này, hoặc `catalog` nội bộ. Không mở URL web từ banner ở schema 1 (tránh trang chủ biến thành trình duyệt).

### continue

```json
{ "id": "cont", "type": "continue", "title": "Xem tiếp", "kinds": ["video.movie", "text.book"] }
```

App điền. Nguồn không bịa tiến độ.

### feed

```json
{ "id": "clips", "type": "feed", "title": "Ngắn", "feed": "for-you" }
```

Mở player dọc. Dữ liệu clip lấy từ catalog có cùng `feed`.

### genreChips

```json
{ "id": "tags", "type": "genreChips", "tags": ["tiên hiệp", "đô thị", "ngôn tình"] }
```

Bấm chip = lọc item đã tải có tag đó, hoặc gọi `endpoints.search` nếu có.

## Item rút gọn trên home

Home chỉ cần đủ để vẽ thẻ: `ref`, `kind`, `title`, `artwork`. Khi user bấm, app tải item đầy đủ từ:

1. map `items` trong chính file home, nếu có ref đó
2. nếu không, `catalog/{kind-file}` hoặc endpoint `item?ref=`

Quy ước file theo kind nếu nguồn không khai báo khác trong manifest `endpoints.item`:

| kind | file mặc định |
| --- | --- |
| `video.movie` | `catalog/movies.json` |
| `video.shortFilm` | `catalog/shorts.json` |
| `video.clip` | `catalog/clips.json` |
| `audio.track` | `catalog/music.json` |
| `comic.series` | `catalog/comics.json` |
| `text.book` | `catalog/books.json` |

Có thể ghi đè:

```json
{
  "endpoints": {
    "catalog": "catalog/",
    "item": "https://api.example/meine/item?ref={ref}"
  }
}
```

## Những gì nguồn không làm được trên trang chủ

- Không đặt widget HTML.
- Không autoplay có tiếng. Hero có thể là ảnh. Clip chỉ phát tiếng sau khi user mở feed hoặc bật âm trong player.
- Không che tab bar, không khoá gesture hệ thống.
- Không đổi icon app, không đổi màu các trang Thư viện / Cài đặt.
- Không theo dõi. Schema 1 không có pixel, không có script analytics. Nếu sau này có, sẽ là opt-in và ghi trong version mới.

## Quy trình thiết kế một trang chủ

1. Liệt kê 3 việc user hay làm nhất với nguồn của bạn (nghe tiếp, đọc chương mới, lướt clip).
2. Đặt đúng một `hero` hoặc một `continue` ở trên cùng, không cả hai lẫn thêm banner dài.
3. Tối đa 8 section trên điện thoại. Thêm nữa thì tách tab.
4. Mỗi rail 8–20 item. Phần còn lại để sau `more`.
5. Ảnh thẻ cùng một tỷ lệ trong một section.
6. Viết `title` ngắn, không viết hoa toàn bộ.
7. Chọn `accent` lệch nhẹ quanh xanh biển nếu muốn hòa với app, hoặc màu riêng nếu nguồn có nhận diện. Kiểm tra chữ trên nền bằng mắt ở chế độ sáng.
8. Chạy **Nguồn → Kiểm tra**. App báo section lạ, ảnh gãy, ref không có item đầy đủ.
9. Tăng `version` trong manifest mỗi lần đổi catalog mà user cần thấy ngay. Đổi mỗi `theme` không cần đổi ref.

## Ví dụ một trang cân

```json
{
  "schemaVersion": 1,
  "title": "Nhà",
  "sections": [
    { "id": "c", "type": "continue", "title": "Tiếp tục" },
    {
      "id": "h",
      "type": "hero",
      "items": [{ "ref": "movie:a", "kind": "video.movie", "title": "A" }]
    },
    {
      "id": "m",
      "type": "rail",
      "title": "Nhạc mới",
      "cardStyle": "square",
      "items": [{ "ref": "track:a", "kind": "audio.track", "title": "A" }],
      "more": { "title": "Tất cả", "catalog": "catalog/music.json" }
    }
  ]
}
```

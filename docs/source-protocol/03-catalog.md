# Catalog

Catalog mô tả *có gì để xem*, không mô tả pixel. Mỗi item có `ref` duy nhất trong nguồn.

`ref` nên dạng `{loại}:{id}` ví dụ `movie:spirited-01`, `track:yeu-em`, `comic:one-piece`, `book:du-lich`. Không chứa khoảng trắng. Ổn định qua các lần cập nhật — tiến độ người dùng bám vào `ref`.

## Bọc chung của mọi file catalog

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-09-22T02:00:00Z",
  "nextCursor": null,
  "items": []
}
```

`nextCursor`: `null` nếu hết. Khác `null` thì app gọi lại với `?cursor=`. Xem [09-errors-and-paging.md](09-errors-and-paging.md).

Item cũng có thể nằm rải trong `home.json` dưới khoá `items` (object map theo ref) để nguồn nhỏ chỉ cần một file. Nguồn lớn tách file theo loại.

## Trường chung của item

| Trường | Bắt buộc | Ghi chú |
| --- | --- | --- |
| `ref` | có, nếu item nằm trong mảng | Không cần nếu là value của map `items` |
| `kind` | có | Khớp `kinds` trong manifest |
| `title` | có | |
| `subtitle` | không | |
| `summary` | không | Không HTML. Xuống dòng = `\n` |
| `artwork` | không | Ảnh bìa. Tỷ lệ khuyên 2:3 (poster) hoặc 1:1 (nhạc) |
| `backdrop` | không | Ảnh ngang 16:9 |
| `language` | không | BCP-47 |
| `tags` | không | string[], dùng lọc và chip |
| `ageRating` | không | `G` `PG` `T` `M` `18` hoặc chuỗi tự do ngắn |
| `publishedAt` | không | ISO-8601 |
| `capabilities` | không | Ghi đè gợi ý manifest cho riêng item này |

## video.movie — phim dài

```json
{
  "ref": "movie:demo",
  "kind": "video.movie",
  "title": "Phim demo",
  "duration": 5400,
  "artwork": "artwork/demo.jpg",
  "media": {
    "href": "https://cdn.example/demo/master.m3u8",
    "mime": "application/vnd.apple.mpegurl"
  },
  "subtitles": [
    {
      "id": "vi",
      "language": "vi",
      "label": "Tiếng Việt",
      "href": "subtitles/demo.vi.srt",
      "mime": "application/x-subrip",
      "default": true
    }
  ],
  "seasons": [
    {
      "id": "s1",
      "title": "Phần 1",
      "episodes": [
        {
          "id": "e1",
          "title": "Tập 1",
          "duration": 2400,
          "media": { "href": "media/s01e01.mp4", "mime": "video/mp4" }
        }
      ]
    }
  ]
}
```

- Phim lẻ: có `media`, không cần `seasons`.
- Phim bộ: `media` có thể bỏ; mỗi tập có `media`.
- `duration` tính bằng giây.
- MIME khuyên dùng: `video/mp4`, `application/vnd.apple.mpegurl` (HLS), `application/dash+xml`.
- App phát HLS/MP4 native. Nguồn nên đưa HLS hoặc MP4 H.264/AAC để máy yếu vẫn mượt. HEVC được nếu thiết bị hỗ trợ; app tự hỏi AVFoundation, không đoán.

## video.shortFilm — phim ngắn

Giống movie nhưng `kind` là `video.shortFilm`. Thêm:

```json
{
  "albumRefs": ["album:dem-he"],
  "playlistEligible": true
}
```

Người dùng tạo danh sách phát và nhét danh sách đó vào album. Album do user tạo nằm trên máy. Nguồn chỉ *gợi ý* album bằng `albumRefs` nếu catalog có object album:

```json
{
  "ref": "album:dem-he",
  "kind": "video.album",
  "title": "Đêm hè",
  "visibility": "public"
}
```

`visibility` của album nguồn chỉ là gợi ý hiển thị (`public` | `private`). Album người dùng tự tạo luôn tôn trọng lựa chọn public/private của họ và không upload đi đâu trừ khi chính nguồn có endpoint share (không bắt buộc ở schema 1).

## video.clip — video ngắn

```json
{
  "ref": "clip:001",
  "kind": "video.clip",
  "title": "Khoảnh khắc",
  "creator": "Tên kênh",
  "duration": 18,
  "artwork": "artwork/001.jpg",
  "media": { "href": "media/clips/001.mp4", "mime": "video/mp4" },
  "feed": "for-you"
}
```

App xếp các clip cùng `feed` thành cột dọc, phát lần lượt, vuốt lên để tới clip sau. Nguồn muốn nhiều feed thì đặt `feed` khác nhau (`for-you`, `following`). Không có `feed` → app gom một feed mặc định.

Clip nên ngắn, file MP4 progressive hoặc HLS, có faststart (`moov` đầu file) để phát ngay.

## audio.track — nhạc

```json
{
  "ref": "track:yeu-em",
  "kind": "audio.track",
  "title": "Yêu em",
  "artists": ["Ca sĩ"],
  "album": "Tên album",
  "duration": 214,
  "artwork": "artwork/yeu-em.jpg",
  "media": { "href": "media/yeu-em.flac", "mime": "audio/flac" },
  "lyrics": [
    {
      "id": "lrc-vi",
      "format": "lrc",
      "language": "vi",
      "href": "lyrics/yeu-em.lrc",
      "synced": true,
      "default": true
    }
  ],
  "backdropSuggestions": ["artwork/yeu-em-wide.jpg"]
}
```

MIME app cam kết phát nếu iOS phát được: `audio/mpeg`, `audio/mp4`, `audio/aac`, `audio/wav`, `audio/flac`, `audio/alac`. File lạ: app thử, thất bại thì báo không hỗ trợ, không crash.

Lyric: xem [07-sidecars.md](07-sidecars.md).

## comic.series — truyện tranh

```json
{
  "ref": "comic:demo",
  "kind": "comic.series",
  "title": "Demo",
  "authors": ["Hoạ sĩ"],
  "artwork": "artwork/comic.jpg",
  "defaultReading": "webtoon",
  "chapters": [
    {
      "id": "c1",
      "title": "Chương 1",
      "pages": [
        { "href": "media/comic/c1/001.jpg", "width": 800, "height": 1200 },
        { "href": "media/comic/c1/002.jpg", "width": 800, "height": 4000 }
      ]
    }
  ]
}
```

`defaultReading`: `webtoon` | `pagedLTR` | `pagedRTL` | `pagedVertical`. App mặc định `webtoon` nếu nguồn không nói.

- Webtoon: mỗi page là một ảnh dài, app xếp dọc.
- Paged: mỗi page là một trang. `width`/`height` giúp app chọn layout trước khi tải ảnh.
- Ảnh: JPEG, PNG, WEBP. Nên dưới 2 MB/ảnh, cạnh dài dưới 4096 nếu có thể. App downsample khi vẽ, nhưng file quá lớn vẫn tốn RAM lúc giải nén — nguồn nên nén sẵn.

Không nhét base64 vào JSON.

## text.book — truyện chữ

```json
{
  "ref": "book:demo",
  "kind": "text.book",
  "title": "Demo",
  "authors": ["Tác giả"],
  "artwork": "artwork/book.jpg",
  "genres": ["tiên hiệp"],
  "chapters": [
    {
      "id": "c1",
      "title": "Chương 1",
      "href": "media/books/c1.txt",
      "mime": "text/plain"
    },
    {
      "id": "c2",
      "title": "Chương 2",
      "href": "media/books/c2.md",
      "mime": "text/markdown"
    }
  ]
}
```

MIME: `text/plain`, `text/markdown`, `application/xhtml+xml`. App bỏ script/style nếu gặp HTML. Không thực thi gì trong nội dung chương.

Genre dùng làm gợi ý prompt dịch (user sửa được).

## Ảnh

Mọi `artwork`, `backdrop`, `href` ảnh đi qua cùng quy tắc resolver. Kích thước khuyên:

| Vai | Cạnh |
| --- | --- |
| Thumbnail thẻ | 400 px |
| Poster | 800 px |
| Backdrop | 1280 px |
| Ảnh nền player nhạc | 1600 px |

App không bắt buộc nhiều kích thước. Một URL là đủ.

## Cấm

- HTML trong `title`.
- URL `javascript:`, `file://` trỏ ra ngoài thư mục nguồn, hoặc path chứa `..`.
- Item không có cách lấy media (không `media`, không `chapters`, không `pages`).

# Bắt đầu trong 15 phút

Mục tiêu: một nguồn local có 1 bài nhạc và 1 truyện chữ, trang chủ 2 khối, app mở được không cần server.

## 1. Tạo thư mục

```
MeineDemo/
  manifest.json
  catalog/home.json
  media/tracks/song.m4a
  media/books/chuong-1.txt
  artwork/cover.jpg
```

## 2. manifest.json

```json
{
  "schemaVersion": 1,
  "id": "local.demo.meine",
  "name": "Demo của tôi",
  "version": "1.0.0",
  "defaultLocale": "vi",
  "kinds": ["audio.track", "text.book"],
  "home": { "ref": "catalog/home.json" },
  "endpoints": {
    "catalog": "catalog/"
  }
}
```

`id` là chuỗi ổn định, không đổi khi bạn sửa tên hiển thị. Dùng dạng `local.tenban` hoặc domain bạn sở hữu (`nguon.example.com`).

## 3. catalog/home.json

```json
{
  "schemaVersion": 1,
  "title": "Hôm nay",
  "sections": [
    {
      "id": "now",
      "type": "hero",
      "title": "Đang nghe",
      "items": [
        {
          "ref": "track:demo-1",
          "kind": "audio.track",
          "title": "Bài demo",
          "artwork": "artwork/cover.jpg"
        }
      ]
    },
    {
      "id": "read",
      "type": "rail",
      "title": "Đọc tiếp",
      "items": [
        {
          "ref": "book:demo-1",
          "kind": "text.book",
          "title": "Truyện demo",
          "artwork": "artwork/cover.jpg"
        }
      ]
    }
  ],
  "items": {
    "track:demo-1": {
      "kind": "audio.track",
      "title": "Bài demo",
      "artists": ["Bạn"],
      "artwork": "artwork/cover.jpg",
      "media": { "href": "media/tracks/song.m4a", "mime": "audio/mp4" }
    },
    "book:demo-1": {
      "kind": "text.book",
      "title": "Truyện demo",
      "authors": ["Bạn"],
      "artwork": "artwork/cover.jpg",
      "chapters": [
        {
          "id": "c1",
          "title": "Chương 1",
          "href": "media/books/chuong-1.txt",
          "mime": "text/plain"
        }
      ]
    }
  }
}
```

## 4. Thêm vào app

1. Mở Meine → Nguồn → Thêm.
2. Chọn **Thư mục trên máy**.
3. Trỏ vào `MeineDemo`.
4. App đọc manifest, vẽ trang chủ, phát được bài và chương.

Không có mạng vẫn chạy, vì mọi `href` là đường dẫn tương đối trong thư mục nguồn.

## 5. Việc nên làm tiếp

- Đổi màu trang chủ: xem [05-home-layout.md](05-home-layout.md).
- Thêm mật khẩu: xem [06-auth.md](06-auth.md).
- Đưa catalog lên HTTP để người khác dùng: xem [04-resolver.md](04-resolver.md).

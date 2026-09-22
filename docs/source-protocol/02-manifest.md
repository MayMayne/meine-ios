# manifest.json

File bắt buộc ở gốc nguồn. UTF-8, không BOM. Dung lượng khuyến nghị dưới 64 KB. Không nhét catalog vào đây.

## Trường

| Trường | Bắt buộc | Kiểu | Ý nghĩa |
| --- | --- | --- | --- |
| `schemaVersion` | có | `1` | Version hợp đồng |
| `id` | có | string | Định danh ổn định, `[a-z0-9._-]{3,80}` |
| `name` | có | string | Tên hiện trên app, tối đa 60 ký tự |
| `version` | có | semver | Version *nội dung* nguồn, không phải version app |
| `summary` | không | string | Một câu mô tả |
| `defaultLocale` | không | BCP-47 | Mặc định `vi` |
| `kinds` | có | string[] | Các loại nội dung nguồn này có |
| `home` | có | object | Cách vẽ trang chủ. Xem layout doc |
| `endpoints` | có | object | Catalog và resolver ở đâu |
| `theme` | không | object | Màu gợi ý cho trang chủ nguồn này |
| `capabilities` | không | object | Tính năng player muốn bật. User vẫn tắt được |
| `auth` | không | object | Nguồn có khoá không, kiểu khoá |
| `cacheTtl` | không | số giây | Mặc định 3600. `0` = luôn mạng (local bỏ qua) |
| `attribution` | không | object | Tên tác giả nguồn, link, giấy phép nội dung |
| `minAppVersion` | không | semver | App cũ hơn thì báo cần cập nhật, không crash |

## endpoints

```json
{
  "endpoints": {
    "catalog": "catalog/",
    "search": "catalog/search.json",
    "resolve": null
  }
}
```

- `catalog`: thư mục hoặc URL gốc của các file catalog.
- `search`: không bắt buộc. Nếu thiếu, app tìm trong các trang đã tải.
- `resolve`: URL POST nếu link media phải ký lúc phát. Nguồn tĩnh để `null` và ghi `href` thẳng trong item.

Đường dẫn không bắt đầu bằng `http://` hoặc `https://` là **tương đối với gốc nguồn**.

## theme (gợi ý, không áp đặt cả app)

```json
{
  "theme": {
    "accent": "#7EC8C3",
    "background": "#F4FBFA",
    "onBackground": "#1C2B2A",
    "card": "#FFFFFF",
    "radius": "soft"
  }
}
```

App kiểm tra tương phản. Nếu chữ và nền quá gần, app tự nới màu chứ không vẽ chữ không đọc được. Màu không hợp lệ bị bỏ, rơi về xanh biển pastel + trắng.

`radius`: `sharp` | `soft` | `round`.

Theme nguồn **chỉ áp cho trang chủ và thẻ của nguồn đó**. Player dùng theme người dùng, trừ khi capability cho phép nguồn gợi ý màu nền player (user vẫn ghi đè).

## auth

```json
{
  "auth": {
    "mode": "password",
    "hint": "Mật khẩu bạn đã đặt khi xuất nguồn"
  }
}
```

`mode`: `none` (mặc định) | `password` | `bearer` | `connector`.

Chi tiết: [06-auth.md](06-auth.md).

## capabilities

Xem [08-capabilities.md](08-capabilities.md). Manifest chỉ *đề xuất*. Thiếu field = app dùng mặc định an toàn của loại nội dung đó.

## Ví dụ tối thiểu hợp lệ

```json
{
  "schemaVersion": 1,
  "id": "local.ten.sach",
  "name": "Sách của Ten",
  "version": "0.1.0",
  "kinds": ["text.book"],
  "home": { "ref": "catalog/home.json" },
  "endpoints": { "catalog": "catalog/" }
}
```

## id không được đổi

Đổi `id` = app coi là nguồn mới. Thư viện, tiến độ, mật khẩu đã lưu sẽ không khớp. Đổi tên hiển thị thì chỉ sửa `name`.

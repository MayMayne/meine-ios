# Mật khẩu và quyền

Người dùng có thể khoá nguồn của chính họ. Người phát triển nguồn có thể yêu cầu mật khẩu hoặc token, nhưng không đọc lại mật khẩu app đã lưu.

## Ba lớp, không trộn

1. **Khoá app.** User bật tại Nguồn, Đặt mật khẩu. Chỉ chặn UI trên máy. Phù hợp thư mục local của chính user.
2. **Khoá gói.** Người đóng gói mã hóa media trước khi đưa đi. App hỏi mật khẩu rồi giải mã. Mất mật khẩu là mất nội dung. Không có cửa hậu.
3. **Token API.** Nguồn HTTP cần Authorization. User dán token một lần. Khác với mật khẩu xem nội dung.

## manifest

```json
{
  "auth": {
    "mode": "password",
    "scope": "app",
    "hint": "Gợi ý, không phải mật khẩu",
    "keyId": "k1"
  }
}
```

| mode | Hành vi |
| --- | --- |
| `none` | Không hỏi. User vẫn có thể tự bật khoá app. |
| `password` | Hỏi mật khẩu theo `scope` |
| `bearer` | Hỏi token, gửi `Authorization: Bearer` tới đúng host endpoint |
| `connector` | Dùng phiên Drive, OneDrive hoặc WebDAV |

`scope` khi mode là password:

- `app` (mặc định): không giải mã file. Chỉ chặn UI.
- `bundle`: cần khóa dẫn xuất từ mật khẩu để đọc file mã hóa.

## Gói mã hóa, tuỳ chọn

Thuật toán cố định:

- KDF: scrypt, N=16384, r=8, p=1, salt 16 byte trong `encryption.json`.
- Cipher: AES-256-GCM, nonce 12 byte ở đầu mỗi file.
- Không dùng mật khẩu thô làm khóa AES.

`encryption.json` ở gốc nguồn, không phải bí mật:

```json
{
  "schemaVersion": 1,
  "alg": "AES-256-GCM",
  "kdf": "scrypt",
  "salt": "<base64 16 bytes>",
  "keyId": "k1"
}
```

Sai mật khẩu: báo sai, không xoá file. Sau 8 lần sai trong 10 phút thì chờ 60 giây.

## Lưu trên máy

- Mật khẩu và token nằm trong Keychain, theo `id` nguồn.
- Không ghi vào catalog, log, hay ảnh chia sẻ.
- Xoá nguồn là xoá mục Keychain đó.
- HTTP 401 với bearer: hỏi token mới, không xoá thư viện.

Token không được gửi sang domain lạ. Media trên CDN thì endpoint resolve trả signed URL.

## Public và private

Playlist nhạc, danh sách đọc, album phim ngắn do user tạo lưu trên máy.

- `private`: chỉ máy này.
- `public` ở schema 1 nghĩa là được xuất file JSON để đưa cho người khác. Không có máy chủ Meine.

Nguồn không được đổi danh sách của user từ private sang public.

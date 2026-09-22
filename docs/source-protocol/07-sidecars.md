# Lyric, phụ đề, chương

File đi kèm tách khỏi JSON. Catalog chỉ trỏ `href`.

## Lyric nhạc

| format | Đuôi | App làm được |
| --- | --- | --- |
| `lrc` | `.lrc` | Thời gian từng dòng. Karaoke nếu có word time |
| `srt` | `.srt` | Câu theo khoảng thời gian |
| `ttml` | `.ttml` | Câu, và karaoke nếu có span thời gian |
| `vtt` | `.vtt` | Như srt |
| `plain` | `.txt` | Không sync. Hiện cả bài |

`synced: true` chỉ khi file có mốc thời gian. App kiểm tra lại. Khai sai thì coi như plain, không làm hỏng player.

### LRC

Hỗ trợ `[mm:ss.xx]`, `[mm:ss.xxx]`, nhiều mốc một dòng, `[offset:+/-ms]`, metadata `[ar:]` `[ti:]` `[al:]` (không hiện như lời), enhanced LRC dạng `từ<mm:ss.xx>`.

Dòng không parse được thì bỏ dòng đó.

### Hiệu ứng theo dữ liệu, không theo ý nguồn

User chọn hiệu ứng. App chỉ hiện hiệu ứng mà file nuôi được.

| Hiệu ứng | Cần |
| --- | --- |
| `fadeLine` | sync dòng |
| `scrollFocus` | sync dòng |
| `typeOn` | sync dòng |
| `blurReveal` | sync dòng |
| `karaokeSweep` | thời gian từng từ (enhanced LRC hoặc TTML span) |

SRT không có từng từ thì không có karaokeSweep. App ẩn lựa chọn, không giả lập chữ chạy sai.

Full màn hình (chỉ lyric) và nửa màn hình (lyric + điều khiển), màu nền, đậm nhạt, font user tải lên: việc của player. Nguồn chỉ gợi ý ảnh nền qua `backdropSuggestions`.

## Phụ đề phim

```json
{
  "id": "vi",
  "language": "vi",
  "label": "Tiếng Việt",
  "href": "subtitles/a.vi.srt",
  "mime": "application/x-subrip",
  "default": true,
  "kind": "soft"
}
```

Định dạng: SRT, VTT, TTML. Sub mềm gắn trong MP4 app đọc từ asset nếu không có file ngoài.

`kind` là `soft` hoặc `embedded`. Sub cháy vào hình thì khai đúng sự thật, vì app không đổi màu sub cứng.

Màu chữ, đậm nhạt, font user thêm, cỡ chữ, nền chữ và đậm nhạt nền: user chỉnh trong player khi sub là mềm hoặc user tự thêm. Nguồn không style từng câu bằng HTML.

## Truyện chữ

MIME: `text/plain`, `text/markdown`, `application/xhtml+xml`.

Markdown được phép: heading, đoạn, đậm, nghiêng, ảnh, link. Link không tự mở trình duyệt trong lúc đọc.

Bị bỏ: script, style, iframe, video tự chạy.

Mỗi chương một file. Có thể gộp, nhưng file nhiều megabyte sẽ lật trang chậm trên máy cũ.

Gợi ý dịch, không bắt buộc:

```json
{
  "translationHints": {
    "genre": "tiên hiệp",
    "addressBook": [
      { "source": "师兄", "preferred": "sư huynh", "pronoun": "anh" }
    ]
  }
}
```

Lần đầu user bật dịch, app chép hint vào bảng của họ. Bản user đã sửa không bị nguồn ghi đè.

Bảng lỗi dịch AI và bảng lỗi TTS nằm trên máy user. Schema 1 không upload các bảng này về nguồn.

## Truyện tranh

Thứ tự mảng `pages` là thứ tự đọc gốc. User xoay hướng trong app, nguồn không cần xuất hai bộ ảnh.

```json
{ "href": "p1.jpg", "width": 800, "height": 1280, "spread": "single" }
```

`spread`: `single`, `left`, `right`. App bỏ qua spread khi user đang xem webtoon.

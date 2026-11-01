# 📱 Google Pixel 10 Pro — Cloud Android Phone Trên GitHub Actions

> Dự án tạo điện thoại ảo **Google Pixel 10 Pro (Android 14)** trên nền tảng đám mây GitHub Actions, điều khiển trực tiếp qua trình duyệt Web với đầy đủ tính năng như máy thật (Google Play Store, CH Play, cảm ứng đa điểm 60 FPS, cài APK kéo thả, phím cứng ảo).

---

## 🌟 Tính Năng Nổi Bật

* **✨ Trải nghiệm như máy thật:**
  * Mô phỏng phần cứng **Google Pixel 10 Pro** với chip Google Tensor G5, 16 GB RAM ảo, màn hình OLED 1080x2400 (420 dpi).
  * Chạy **Android 14.0 (API Level 34)** hoặc **Android 13.0 (API Level 33)** chính thức.
  * Tích hợp sẵn **Google Play Services & CH Play chính hãng** — bạn có thể đăng nhập tài khoản Google để tải game, ứng dụng ngân hàng, mạng xã hội (TikTok, Facebook, Zalo, Telegram...).
* **⚡ Tăng tốc phần cứng KVM:**
  * Khai thác trực tiếp `/dev/kvm` trên GitHub Actions runner giúp tốc độ xử lý nhanh, mượt mà và không giật lag.
* **🌐 Điều khiển Web không cần cài đặt phần mềm:**
  * Mở link trên bất kỳ trình duyệt nào (Chrome, Safari, Edge, Firefox) từ máy tính, laptop, iPad hay điện thoại khác.
  * Khung viền mô phỏng **Pixel 10 Pro Obsidian Titanium** với màn hình cong tràn viền, camera đục lỗ (Punch-hole) và thanh trạng thái hiển thị pin/giờ theo thời gian thực.
  * Truyền hình ảnh H.264 tốc độ **60 FPS** độ trễ cực thấp (<80ms) bằng Scrcpy Web engine.
* **🕹️ Bộ điều khiển thông minh:**
  * **Cảm ứng tự nhiên:** Chuột click tương đương chạm ngón tay, kéo giữ chuột tương đương vuốt/cuộn màn hình.
  * **Phím cứng:** Nút Nguồn (Power - Bật/Tắt màn hình), Tăng/Giảm âm lượng (Volume Up/Down).
  * **Thanh điều hướng:** Quay lại (Back), Màn hình chính (Home), Chuyển ứng dụng đa nhiệm (Recents).
  * **Cử chỉ nhanh:** Kéo thanh thông báo (Notification Shade), Cài đặt nhanh (Quick Settings).
* **📦 Cài đặt APK cực dễ:**
  * Kéo thả trực tiếp file `.apk` bất kỳ từ máy tính vào màn hình web để tự động cài đặt vào điện thoại trong vài giây.
* **📋 Nhập liệu & Clipboard:**
  * Ô nhập văn bản hỗ trợ gõ tiếng Việt từ bàn phím máy tính và gửi thẳng vào ô nhập liệu trên điện thoại.
* **📸 Chụp ảnh màn hình HD:**
  * Nút chụp màn hình 1-click tải ngay ảnh chụp độ phân giải 1080x2400 về máy tính.
* **🔒 Kết nối an toàn & Miễn phí 100%:**
  * Tự động tạo đường hầm HTTPS bảo mật qua Cloudflare Quick Tunnel (`https://xxxx.trycloudflare.com`), không cần tài khoản, không cần mở port.
  * Tùy chọn gửi thông báo kèm đường link truy cập trực tiếp về Telegram cá nhân ngay khi máy khởi động xong.

---

## 🚀 Hướng Dẫn Khởi Chạy 1-Click

### Bước 1: Đưa mã nguồn lên tài khoản GitHub của bạn
Tạo một repository mới trên GitHub (ví dụ: `cloud-pixel-phone`) và tải toàn bộ mã nguồn của dự án này lên.

### Bước 2: Bật quyền chạy Actions
1. Vào mục **Settings** của repository -> Chọn **Actions** -> **General**.
2. Tại mục **Workflow permissions**, chọn **Read and write permissions** rồi bấm **Save**.

### Bước 3: (Tùy chọn) Cài đặt thông báo Telegram
Nếu muốn nhận link web tự động qua Telegram mỗi khi máy sẵn sàng:
1. Vào **Settings** -> **Secrets and variables** -> **Actions** -> Chọn **New repository secret**.
2. Thêm 2 secret:
   * `TELEGRAM_BOT_TOKEN`: Token của bot Telegram của bạn.
   * `TELEGRAM_CHAT_ID`: ID chat Telegram nhận tin nhắn.

### Bước 4: Khởi chạy điện thoại ảo
1. Chuyển sang tab **Actions** trên GitHub.
2. Ở danh sách bên trái, chọn workflow **Cloud Pixel 10 Pro**.
3. Bấm vào nút **Run workflow**:
   * **Phiên bản Android:** Chọn `34` (Android 14) hoặc `33` (Android 13).
   * **Tên dòng máy:** Chọn `Google Pixel 10 Pro`.
   * **Thời gian duy trì:** Mặc định `300` phút (tối đa 350 phút ~ gần 6 tiếng).
   * **Tự động cài APK (Tùy chọn):** Dán link tải trực tiếp file APK nếu muốn máy cài sẵn khi vừa mở.
4. Bấm nút màu xanh **Run workflow**.

### Bước 5: Truy cập & Điều khiển
1. Đợi khoảng 2 - 3 phút để hệ thống khởi tạo Android và kích hoạt Cloudflare Tunnel.
2. Bấm vào lượt chạy đang chạy, bạn sẽ thấy đường link web dạng:
   ```text
   👉 https://xxxx-xxxx-xxxx.trycloudflare.com
   ```
   được hiển thị nổi bật trong phần **Summary** của Action.
3. Bấm vào link và bắt đầu trải nghiệm chiếc Google Pixel 10 Pro đám mây của bạn!

---

## 📂 Cấu Trúc Dự Án

```text
cloud-pixel-phone/
├── .github/
│   └── workflows/
│       └── cloud-phone.yml        # Kịch bản GitHub Actions tự động hóa toàn bộ
├── server/
│   ├── web_dashboard.py           # Backend REST API điều khiển ADB (Port 5000)
│   └── index.html                 # Giao diện Web điều khiển Pixel 10 Pro (HTML5/CSS3/JS)
├── scripts/
│   ├── setup-sdk.sh               # Cài đặt Android SDK, Commandline tools & KVM
│   ├── create-avd.sh              # Tạo cấu hình AVD Google Pixel 10 Pro
│   ├── launch-emulator.sh         # Khởi chạy Android Emulator với KVM
│   ├── tunnel.sh                  # Khởi chạy Nginx, Scrcpy Web & Cloudflare Tunnel
│   ├── keepalive.sh               # Vòng lặp duy trì kết nối & gửi telemetry
│   └── nginx.conf                 # Cấu hình Nginx Unified Reverse Proxy
└── README.md                      # Tài liệu hướng dẫn sử dụng chi tiết
```

---

## ⚖️ Điều Khoản & Giới Hạn Sử Dụng
* **Giới hạn thời gian:** GitHub Actions áp dụng mức trần tối đa 6 giờ cho mỗi lượt chạy (`timeout-minutes: 360`). Khi hết thời gian, máy sẽ tự động tắt và dữ liệu phiên chạy tạm thời sẽ được xóa sạch.
* **Mục đích sử dụng:** Thích hợp để kiểm thử ứng dụng Android, test APK từ xa, chạy thử game hoặc ứng dụng trên máy ảo cấu hình cao mà không tốn dung lượng máy tính thật.

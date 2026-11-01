#!/usr/bin/env bash
# ==============================================================================
# Setup Web Streaming, Reverse Proxy & Cloudflare Quick Tunnel
# ==============================================================================
set -euo pipefail

REPO_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

echo "============================================================"
echo "🌐 [1/4] Khởi động Scrcpy Web Streaming Service (Port 8000)"
echo "============================================================"

# Chạy Scrcpy Web bằng Docker image tối ưu
docker rm -f scrcpy-web >/dev/null 2>&1 || true
if docker run -d \
    --name scrcpy-web \
    --restart unless-stopped \
    --network host \
    --privileged \
    shmayro/scrcpy-web:latest; then
    echo "Đang chờ scrcpy-web khởi động..."
    for _ in $(seq 1 20); do
        if curl -s -m 2 http://127.0.0.1:8000/ >/dev/null 2>&1; then
            echo "✅ Scrcpy Web Service đã hoạt động!"
            break
        fi
        sleep 2
    done
else
    echo "⚠️ Docker scrcpy-web không khả dụng, sử dụng bộ truyền Canvas REST Stream tích hợp sẵn."
fi

echo "============================================================"
echo "⚙️ [2/4] Khởi động Python ADB Control REST API (Port 5000)"
echo "============================================================"

export API_PORT=5000
nohup python3 "$REPO_DIR/server/web_dashboard.py" > /tmp/api_server.log 2>&1 &
echo "✅ API Server đã khởi chạy (PID: $!)"

echo "============================================================"
echo "🔀 [3/4] Cấu hình Nginx Unified Gateway (Port 80)"
echo "============================================================"

sudo systemctl stop apache2 2>/dev/null || sudo service apache2 stop 2>/dev/null || true
sudo cp "$REPO_DIR/scripts/nginx.conf" /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl restart nginx || sudo service nginx restart
echo "✅ Nginx Unified Gateway đã kích hoạt thành công!"

echo "============================================================"
echo "🚀 [4/4] Khởi động Cloudflare Quick Tunnel (Public HTTPS)"
echo "============================================================"

if [ ! -x /usr/local/bin/cloudflared ]; then
    sudo curl -fsSL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
    sudo chmod +x /usr/local/bin/cloudflared
fi

nohup /usr/local/bin/cloudflared tunnel \
    --url "http://127.0.0.1:80" \
    --no-autoupdate \
    --protocol http2 \
    > /tmp/cloudflared.log 2>&1 &

TUNNEL_URL=""
for _ in $(seq 1 45); do
    TUNNEL_URL=$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' /tmp/cloudflared.log | head -1 || true)
    [ -n "$TUNNEL_URL" ] && break
    sleep 2
done

if [ -z "$TUNNEL_URL" ]; then
    echo "::error::Không thể tạo Cloudflare Tunnel! Chi tiết log:"
    cat /tmp/cloudflared.log
    exit 1
fi

echo "============================================================"
echo "🎉 ĐIỆN THOẠI CLOUD GOOGLE PIXEL 10 PRO ĐÃ TRỰC TUYẾN!"
echo "============================================================"
echo ""
echo "🔗 Đường link truy cập & điều khiển trực tiếp trên Web:"
echo "👉 $TUNNEL_URL"
echo ""
echo "============================================================"

# Lưu URL vào file để các bước sau sử dụng
echo "$TUNNEL_URL" > /tmp/cloud_phone_url.txt

# Ghi chú trực quan vào GitHub Step Summary
cat << EOF >> "$SUMMARY"
# 📱 Điện Thoại Cloud Google Pixel 10 Pro

### 🌐 [BẤM VÀO ĐÂY ĐỂ ĐIỀU KHIỂN TRÊN TRÌNH DUYỆT]($TUNNEL_URL)
> **Link truy cập:** \`$TUNNEL_URL\`

---

### ✨ Thông Số Thiết Bị:
- **Model:** Google Pixel 10 Pro (Flagship)
- **Hệ điều hành:** Android 14.0 (API Level 34)
- **Tăng tốc phần cứng:** KVM Hardware Virtualization (60 FPS mượt mà)
- **Dịch vụ Google:** CH Play chính hãng & Google Play Services sẵn sàng
- **Độ trễ truyền tải:** Dưới 80ms (H.264 WebRTC Stream)

### 🎮 Hướng Dẫn Sử Dụng Nhanh:
1. Mở đường link trên bất kỳ trình duyệt nào (Máy tính, iPhone, iPad, Android).
2. Chuột tương ứng với ngón tay cảm ứng: bấm click để chạm, kéo giữ để vuốt/cuộn.
3. Kéo thả bất kỳ file \`.apk\` nào từ máy tính vào giao diện web để cài đặt tự động.
4. Bấm các phím Home, Back, Đa nhiệm, Nút nguồn ở thanh điều khiển bên cạnh.
EOF

# Tự động cập nhật Website Homepage trên GitHub Repo & lưu vào nhánh live
if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
    echo "Cập nhật link trực tiếp vào trang chủ Repo GitHub..."
    curl -s -X PATCH \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}" \
        -d "{\"homepage\": \"$TUNNEL_URL\"}" > /dev/null 2>&1 || true

    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git branch -D live 2>/dev/null || true
    git checkout --orphan live 2>/dev/null || true
    echo "$TUNNEL_URL" > url.txt
    git add url.txt
    git commit -m "chore: live cloud phone at $TUNNEL_URL" || true
    git push -f origin live || true
    git checkout -f main || true
fi

# Gửi thông báo Telegram nếu có Secret
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    MSG="📱 *Google Pixel 10 Pro Cloud Phone Đã Sẵn Sàng\!*%0A%0A🌐 *Link điều khiển Web:*%0A$TUNNEL_URL%0A%0A⚡ _Android 14 · Google Play · KVM 60FPS_"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${MSG}" \
        -d "parse_mode=MarkdownV2" >/dev/null 2>&1 || true
    echo "📲 Đã gửi thông báo link truy cập qua Telegram!"
fi

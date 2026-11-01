#!/usr/bin/env bash
# ==============================================================================
# Heartbeat & Keep-Alive Loop for Cloud Android Phone
# ==============================================================================
set -euo pipefail

MINUTES="${1:-300}"
SECONDS_TOTAL=$((MINUTES * 60))
START_TIME=$(date +%s)
END_TIME=$((START_TIME + SECONDS_TOTAL))

echo "============================================================"
echo "⏱️ Duy trì điện thoại hoạt động trong $MINUTES phút..."
echo "============================================================"

URL="$(cat /tmp/cloud_phone_url.txt 2>/dev/null || echo 'Chưa rõ URL')"

while true; do
    CURRENT_TIME=$(date +%s)
    REMAINING=$((END_TIME - CURRENT_TIME))

    if [ "$REMAINING" -le 0 ]; then
        echo "⏰ Đã hết thời lượng $MINUTES phút theo yêu cầu. Đang đóng phiên làm việc..."
        break
    fi

    REM_MIN=$((REMAINING / 60))
    REM_SEC=$((REMAINING % 60))

    # Đọc RAM và tình trạng máy
    MEM_INFO=$(free -m | awk '/Mem:/ {print $3"MB / "$2"MB"}')
    CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }')

    echo "💓 [Heartbeat] Còn lại: ${REM_MIN}p ${REM_SEC}s | RAM: $MEM_INFO | Load: $CPU_LOAD | Web: $URL"

    # Kiểm tra xem emulator còn sống không
    if ! adb shell getprop sys.boot_completed >/dev/null 2>&1; then
        echo "⚠️ Cảnh báo: Mất kết nối ADB với emulator, đang thử kết nối lại..."
        adb reconnect || true
    fi

    # Ngủ 60 giây giữa các nhịp tim
    sleep 60
done

echo "🏁 Phiên Cloud Phone kết thúc an toàn."

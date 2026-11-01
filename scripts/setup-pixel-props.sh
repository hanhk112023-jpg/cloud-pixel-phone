#!/usr/bin/env bash
# ==============================================================================
# Configure Google Pixel 10 Pro System Props & Optimizations
# ==============================================================================
set -euo pipefail

AUTO_INSTALL_APK="${1:-}"

echo "============================================================"
echo "⚡ Thiết lập thông số Google Pixel 10 Pro Flagship..."
echo "============================================================"

adb wait-for-device

# Mở khóa màn hình Keyguard
adb shell wm dismiss-keyguard || true

# Tinh chỉnh phần cứng chuẩn Pixel 10 Pro
adb shell wm size 1080x2400 || true
adb shell wm density 420 || true

# Đặt tên thiết bị và nhà sản xuất Google (bảo đảm an toàn không crash script)
adb shell "setprop ro.product.model 'Pixel 10 Pro'" || true
adb shell "setprop ro.product.brand 'google'" || true
adb shell "setprop ro.product.manufacturer 'Google'" || true
adb shell "setprop ro.product.name 'cheetah'" || true
adb shell "setprop ro.product.device 'pixel10pro'" || true

# Giữ màn hình luôn sáng
adb shell settings put global stay_on_while_plugged_in 3 || true
adb shell settings put system screen_off_timeout 2147483647 || true

# Tối ưu tốc độ animation cho cảm ứng mượt mà
adb shell settings put global window_animation_scale 0.5 || true
adb shell settings put global transition_animation_scale 0.5 || true
adb shell settings put global animator_duration_scale 0.5 || true

# Cài đặt APK tự động nếu có truyền link
if [ -n "$AUTO_INSTALL_APK" ]; then
    echo "============================================================"
    echo "📦 Tự động tải và cài đặt APK: $AUTO_INSTALL_APK"
    echo "============================================================"
    TMP_APK="/tmp/auto_app.apk"
    if curl -sL -o "$TMP_APK" "$AUTO_INSTALL_APK"; then
        adb install -r -g "$TMP_APK" || echo "Cài đặt APK gặp lỗi nhỏ nhưng tiếp tục..."
        rm -f "$TMP_APK"
        echo "✅ Cài đặt APK hoàn tất!"
    else
        echo "⚠️ Không thể tải APK từ URL đã cung cấp."
    fi
fi

echo "============================================================"
echo "✅ Đã cấu hình hoàn tất thiết bị ảo Google Pixel 10 Pro!"
echo "============================================================"
adb devices -l || true

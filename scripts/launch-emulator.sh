#!/usr/bin/env bash
# ==============================================================================
# Launch Headless Android Emulator with KVM Hardware Acceleration
# ==============================================================================
set -euo pipefail

AVD_NAME="${1:-pixel10}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/home/runner/android-sdk}"
AVD_HOME="${ANDROID_AVD_HOME:-/home/runner/.android/avd}"

export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"

echo "============================================================"
echo "⚡ Khởi động máy ảo Pixel 10 Pro (Headless KVM Accelerator)..."
echo "============================================================"

# Xóa các file khóa lock cũ nếu có
rm -f "$AVD_HOME/$AVD_NAME.avd/"*.lock

# Khởi chạy emulator ở chế độ nền (không mở cửa sổ đồ họa host, tiết kiệm RAM/CPU)
nohup emulator -avd "$AVD_NAME" \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -gpu swiftshader_indirect \
    -memory 3072 \
    -camera-back virtualscene \
    -camera-front emulated \
    -timezone Asia/Ho_Chi_Minh \
    > /tmp/emulator.log 2>&1 &

EMU_PID=$!
echo "Emulator PID: $EMU_PID"

echo "============================================================"
echo "⏳ Đang chờ hệ điều hành Android khởi động (Boot sequence)..."
echo "============================================================"

adb wait-for-device

BOOTED=""
for i in $(seq 1 60); do
    BOOTED="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [ "$BOOTED" = "1" ]; then
        echo "🎉 Android Boot hoàn tất sau $((i * 5)) giây!"
        break
    fi
    printf '.'
    sleep 5
done
echo

if [ "$BOOTED" != "1" ]; then
    echo "::error::Android không thể boot hoàn tất sau 5 phút. Xem log:"
    tail -40 /tmp/emulator.log || true
    exit 1
fi

echo "============================================================"
echo "🔧 Tinh chỉnh hệ thống chuẩn Flagship Pixel 10 Pro"
echo "============================================================"

# Giữ màn hình luôn sáng khi cắm sạc ảo
adb shell settings put global stay_on_while_plugged_in 3
adb shell settings put system screen_off_timeout 2147483647
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5

# Thiết lập thông số Model Pixel 10 Pro
adb shell setprop ro.product.model "Pixel 10 Pro"
adb shell setprop ro.product.brand "google"
adb shell setprop ro.product.manufacturer "Google"

# Tắt khóa màn hình Keyguard để vào thẳng màn hình chính
adb shell wm dismiss-keyguard || true

echo "✅ Thiết bị ảo Pixel 10 Pro đã sẵn sàng phục vụ!"
adb devices -l

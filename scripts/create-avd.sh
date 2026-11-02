#!/usr/bin/env bash
# ==============================================================================
# Create Google Pixel 10 Pro Virtual Device (AVD)
# ==============================================================================
set -euo pipefail

AVD_NAME="${1:-pixel10}"
API_LEVEL="${2:-34}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/home/runner/android-sdk}"
AVD_HOME="${ANDROID_AVD_HOME:-/home/runner/.android/avd}"

mkdir -p "$AVD_HOME"
export ANDROID_AVD_HOME="$AVD_HOME"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"

echo "============================================================"
echo "📱 Tạo thiết bị ảo Google Pixel 10 Pro (API $API_LEVEL)..."
echo "============================================================"

IMAGE_TAG="system-images;android-${API_LEVEL};google_apis_playstore;x86_64"
AVD_PATH="$AVD_HOME/$AVD_NAME.avd"

# Xóa AVD cũ nếu có
avdmanager delete avd -n "$AVD_NAME" >/dev/null 2>&1 || true
rm -rf "$AVD_PATH" "$AVD_HOME/$AVD_NAME.ini"

# Tạo AVD với profile Pixel hoặc fallback, chỉ định rõ đường dẫn -p
if echo no | avdmanager create avd -n "$AVD_NAME" -p "$AVD_PATH" -k "$IMAGE_TAG" -d "pixel_7" --force 2>/dev/null; then
    echo "✅ Đã tạo AVD với profile Pixel 7 cơ sở"
elif echo no | avdmanager create avd -n "$AVD_NAME" -p "$AVD_PATH" -k "$IMAGE_TAG" -d "pixel" --force 2>/dev/null; then
    echo "✅ Đã tạo AVD với profile Pixel cơ sở"
else
    echo "⚠️ Đang tạo AVD chế độ mặc định..."
    echo no | avdmanager create avd -n "$AVD_NAME" -p "$AVD_PATH" -k "$IMAGE_TAG" --force
fi

# Tìm file config.ini thực tế
CONFIG_FILE="$AVD_PATH/config.ini"
if [ ! -f "$CONFIG_FILE" ]; then
    FOUND=$(find /home/runner "$HOME" /root -name "config.ini" 2>/dev/null | grep "$AVD_NAME" | head -1 || true)
    if [ -n "$FOUND" ] && [ -f "$FOUND" ]; then
        CONFIG_FILE="$FOUND"
        echo "Tìm thấy file config.ini tại: $CONFIG_FILE"
    fi
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Tạo mới file config.ini tại $AVD_PATH/config.ini"
    mkdir -p "$AVD_PATH"
    CONFIG_FILE="$AVD_PATH/config.ini"
    touch "$CONFIG_FILE"
fi

echo "============================================================"
echo "⚙️ Tinh chỉnh phần cứng chuẩn Google Pixel 10 Pro (Flagship)"
echo "============================================================"

cat << 'EOF' >> "$CONFIG_FILE"
hw.device.name=Pixel 10 Pro
hw.device.manufacturer=Google
hw.cpu.ncore=3
hw.ramSize=3072
vm.heapSize=512
disk.dataPartition.size=32G
PlayStore.enabled=true
hw.lcd.width=1080
hw.lcd.height=2400
hw.lcd.density=420
hw.camera.back=virtualscene
hw.camera.front=emulated
hw.gps=yes
hw.battery=yes
hw.accelerometer=yes
hw.audioInput=yes
hw.audioOutput=yes
hw.keyboard=yes
hw.mainKeys=no
showDeviceFrame=no
skin.dynamic=yes
skin.name=1080x2400
skin.path=_no_skin
fastboot.chosenSnapshotFile=
fastboot.forceChosenSnapshotBoot=no
fastboot.forceColdBoot=yes
fastboot.forceFastBoot=no
EOF

# Đảm bảo file .ini gốc trỏ đúng đường dẫn
cat << EOF > "$AVD_HOME/$AVD_NAME.ini"
avd.ini.encoding=UTF-8
path=$AVD_PATH
path.rel=avd/$AVD_NAME.avd
target=android-${API_LEVEL}
EOF

echo "✅ Cấu hình AVD thành công:"
grep -E "hw.device.name|hw.ramSize|PlayStore.enabled|hw.lcd" "$CONFIG_FILE" || true

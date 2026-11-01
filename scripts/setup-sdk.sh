#!/usr/bin/env bash
# ==============================================================================
# Setup Android SDK, Emulator & KVM Hardware Acceleration
# ==============================================================================
set -euo pipefail

API_LEVEL="${1:-34}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/home/runner/android-sdk}"

echo "============================================================"
echo "🚀 [1/6] Kiểm tra và cấu hình KVM Hardware Acceleration"
echo "============================================================"
if [ ! -e /dev/kvm ]; then
    echo "::error::/dev/kvm không khả dụng trên runner! Cần KVM để chạy giả lập Android mượt mà."
    exit 1
fi

sudo chmod 666 /dev/kvm
echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666"' | sudo tee /etc/udev/rules.d/99-kvm.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=kvm || true
ls -l /dev/kvm
echo "✅ KVM Hardware Virtualization đã kích hoạt thành công!"

echo "============================================================"
echo "📦 [2/6] Cài đặt thư viện hệ thống cần thiết (PulseAudio, GL, NSS)"
echo "============================================================"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    libpulse0 \
    libnss3 \
    libgl1 \
    libegl1 \
    libvulkan1 \
    libxcomposite1 \
    libxcursor1 \
    libxi6 \
    libxtst6

sudo ldconfig
echo "✅ Thư viện runtime cho Android Emulator đã được cài đặt!"

echo "============================================================"
echo "📦 [3/6] Thiết lập Android Command-line Tools"
echo "============================================================"
mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"

if [ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
    TMP_CT="/tmp/commandlinetools"
    mkdir -p "$TMP_CT"
    curl -sL -o "$TMP_CT/ct.zip" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    unzip -q "$TMP_CT/ct.zip" -d "$TMP_CT"
    rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    mv "$TMP_CT/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    rm -rf "$TMP_CT"
fi

export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"

echo "============================================================"
echo "🔑 [4/6] Chấp thuận bản quyền Android SDK & Google APIs"
echo "============================================================"
yes | sdkmanager --licenses > /dev/null 2>&1 || true

echo "============================================================"
echo "📥 [5/6] Cài đặt System Image Android $API_LEVEL (Google Play Store)"
echo "============================================================"
IMAGE_TAG="system-images;android-${API_LEVEL};google_apis_playstore;x86_64"
echo "Đang cài đặt gói: $IMAGE_TAG ..."

sdkmanager "platform-tools" "emulator" "$IMAGE_TAG" | grep -v "=" || true

# Tạo symlink thư viện cho emulator nếu cần
PULSE_LIB="$(find /usr/lib -name "libpulse.so.0" 2>/dev/null | head -1 || true)"
if [ -n "$PULSE_LIB" ] && [ -d "$ANDROID_SDK_ROOT/emulator/lib64" ]; then
    echo "Liên kết $PULSE_LIB vào $ANDROID_SDK_ROOT/emulator/lib64/"
    ln -sf "$PULSE_LIB" "$ANDROID_SDK_ROOT/emulator/lib64/libpulse.so.0" || true
fi

echo "============================================================"
echo "✅ [6/6] Hoàn tất thiết lập Android SDK & Platform Tools!"
echo "============================================================"
adb version
emulator -version | head -2 || true

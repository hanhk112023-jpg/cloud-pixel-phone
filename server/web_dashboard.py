#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
Pixel 10 Pro Cloud Phone — Control Gateway & High-Speed Stream Server
================================================================================
Cung cấp các API điều khiển thiết bị Android qua ADB và nén ảnh JPEG siêu tốc:
  - Phím cứng (Power, Volume, Home, Back, Recents, Notifications)
  - Cảm ứng (Tap, Swipe, Drag)
  - Mở ứng dụng nhanh (CH Play, Chrome, YouTube, Settings)
  - Nhập văn bản & Đồng bộ Clipboard
  - Cài đặt file APK (Drag & Drop)
  - Chụp ảnh màn hình (JPEG siêu nhẹ cho Stream Web, PNG HD cho Tải về)
  - Luồng phát MJPEG trực tiếp
  - Trạng thái hệ thống (Battery, RAM, CPU, Current App)
================================================================================
"""

import os
import sys
import re
import json
import time
import io
import shutil
import subprocess
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse

# Kiểm tra thư viện nén ảnh PIL (Pillow)
try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

PORT = int(os.environ.get("API_PORT", 5000))
ADB = os.environ.get("ADB_BIN", "adb")

# Khung hình màn hình lưu trong bộ nhớ để phục vụ tức thì cho web
LATEST_PNG = None
LATEST_JPEG = None
FRAME_LOCK = threading.Lock()
FRAME_SEQ = 0

def capture_worker():
    """Luồng ngầm liên tục chụp màn hình và nén JPEG tức thì để web tải mượt mà không chớp"""
    global LATEST_PNG, LATEST_JPEG, FRAME_SEQ
    while True:
        try:
            p = subprocess.Popen([ADB, "exec-out", "screencap", "-p"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out, _ = p.communicate(timeout=3)
            if p.returncode == 0 and len(out) > 5000:
                jpeg_bytes = None
                if HAS_PIL:
                    try:
                        img = Image.open(io.BytesIO(out))
                        # Giảm nhẹ độ phân giải xuống 720x1600 để tối ưu tốc độ truyền qua web (chỉ 25-35 KB)
                        img_res = img.resize((720, 1600), Image.Resampling.BILINEAR)
                        buf = io.BytesIO()
                        img_res.save(buf, format="JPEG", quality=75, optimize=True)
                        jpeg_bytes = buf.getvalue()
                    except Exception:
                        jpeg_bytes = None

                with FRAME_LOCK:
                    LATEST_PNG = out
                    if jpeg_bytes:
                        LATEST_JPEG = jpeg_bytes
                    FRAME_SEQ += 1
        except Exception:
            pass
        time.sleep(0.06)

# Kích hoạt luồng cập nhật khung hình
capture_thread = threading.Thread(target=capture_worker, daemon=True)
capture_thread.start()

def run_adb(cmd_list, timeout=12):
    """Thực thi lệnh ADB an toàn và trả về output"""
    try:
        full_cmd = [ADB] + cmd_list
        res = subprocess.run(full_cmd, capture_output=True, text=True, timeout=timeout)
        return res.returncode == 0, res.stdout.strip(), res.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "", "Timeout sau 12 giây"
    except Exception as e:
        return False, "", str(e)

def get_device_info():
    """Lấy thông số chi tiết của điện thoại Pixel 10 Pro"""
    info = {
        "model": "Pixel 10 Pro",
        "brand": "Google",
        "android_version": "14.0",
        "api_level": "34",
        "battery": "100%",
        "charging": True,
        "screen_state": "ON",
        "current_app": "Pixel Launcher",
        "ram_total": "16 GB (Emulated)",
        "ram_free": "12.4 GB",
        "uptime": "0h 0m",
        "resolution": "1080x2400"
    }
    
    ok, out, _ = run_adb(["shell", "getprop", "ro.product.model"])
    if ok and out:
        info["model"] = out
        
    ok, out, _ = run_adb(["shell", "getprop", "ro.build.version.release"])
    if ok and out:
        info["android_version"] = out
        
    ok, out, _ = run_adb(["shell", "getprop", "ro.build.version.sdk"])
    if ok and out:
        info["api_level"] = out
        
    ok, out, _ = run_adb(["shell", "dumpsys", "battery"])
    if ok and out:
        level_m = re.search(r"level:\s*(\d+)", out)
        if level_m:
            info["battery"] = f"{level_m.group(1)}%"
        status_m = re.search(r"status:\s*(\d+)", out)
        if status_m:
            info["charging"] = status_m.group(1) in ("2", "5")
            
    ok, out, _ = run_adb(["shell", "dumpsys", "activity", "activities"])
    if ok and out:
        act_m = re.search(r"mResumedActivity:\s*ActivityRecord\{[^\s]+\s+[^\s]+\s+([^\s]+)", out)
        if act_m:
            info["current_app"] = act_m.group(1)
            
    return info

class CloudPhoneAPIHandler(BaseHTTPRequestHandler):
    def _send_json(self, data, status_code=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path in ("/", "/index.html"):
            html_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "index.html")
            if os.path.exists(html_path):
                with open(html_path, "rb") as f:
                    content = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(content)))
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()
                self.wfile.write(content)
                return
            else:
                self._send_json({"error": "index.html not found"}, 404)
                return

        if path == "/api/status":
            info = get_device_info()
            self._send_json({"success": True, "device": info})

        elif path in ("/api/screenshot", "/api/screen.jpg"):
            query = urllib.parse.parse_qs(parsed.query)
            want_hd = query.get("hd", ["0"])[0] in ("1", "true")
            want_png = query.get("format", [""])[0] == "png"

            with FRAME_LOCK:
                png_data = LATEST_PNG
                jpeg_data = LATEST_JPEG

            # Nếu yêu cầu ảnh HD hoặc chưa có JPEG, trả PNG gốc
            if (want_hd or want_png or not jpeg_data) and png_data:
                self.send_response(200)
                self.send_header("Content-Type", "image/png")
                self.send_header("Content-Length", str(len(png_data)))
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
                self.end_headers()
                self.wfile.write(png_data)
                return
            elif jpeg_data:
                # Trả JPEG siêu nhẹ (~30 KB) tức thì để web hiển thị 60fps mượt mà không chớp
                self.send_response(200)
                self.send_header("Content-Type", "image/jpeg")
                self.send_header("Content-Length", str(len(jpeg_data)))
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
                self.end_headers()
                self.wfile.write(jpeg_data)
                return
            else:
                # Fallback trực tiếp nếu cache rỗng
                p = subprocess.Popen([ADB, "exec-out", "screencap", "-p"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                out, _ = p.communicate(timeout=6)
                self.send_response(200)
                self.send_header("Content-Type", "image/png")
                self.send_header("Content-Length", str(len(out)))
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(out)
                return

        elif path == "/api/stream.mjpg":
            self.send_response(200)
            self.send_header("Content-Type", "multipart/x-mixed-replace; boundary=frame")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            last_seq = -1
            while True:
                with FRAME_LOCK:
                    cur_seq = FRAME_SEQ
                    data = LATEST_JPEG if LATEST_JPEG else LATEST_PNG
                    mime = "image/jpeg" if LATEST_JPEG else "image/png"
                if cur_seq != last_seq and data:
                    last_seq = cur_seq
                    try:
                        self.wfile.write(b"--frame\r\n")
                        self.wfile.write(f"Content-Type: {mime}\r\n".encode())
                        self.wfile.write(f"Content-Length: {len(data)}\r\n\r\n".encode())
                        self.wfile.write(data)
                        self.wfile.write(b"\r\n")
                    except Exception:
                        break
                time.sleep(0.04)
            return

        elif path == "/api/launch":
            query = urllib.parse.parse_qs(parsed.query)
            app_id = query.get("app", [""])[0]
            APP_MAP = {
                "chplay": "com.android.vending",
                "playstore": "com.android.vending",
                "chrome": "com.android.chrome",
                "youtube": "com.google.android.youtube",
                "settings": "com.android.settings",
                "gmail": "com.google.android.gm",
                "maps": "com.google.android.apps.maps",
                "photos": "com.google.android.apps.photos",
                "files": "com.google.android.documentsui",
                "camera": "com.android.camera2"
            }
            pkg = APP_MAP.get(app_id.lower(), app_id)
            ok, out, err = run_adb(["shell", "monkey", "-p", pkg, "-c", "android.intent.category.LAUNCHER", "1"])
            self._send_json({"success": ok, "app": app_id, "package": pkg, "error": err if not ok else None})
            return

        elif path == "/api/ping":
            self._send_json({"success": True, "message": "Pixel 10 Pro Cloud Gateway Online", "time": time.time()})

        else:
            self._send_json({"error": "Endpoint không tồn tại"}, status_code=404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        content_length = int(self.headers.get("Content-Length", 0))

        if path in ("/api/key", "/api/keyevent"):
            body = self.rfile.read(content_length).decode("utf-8")
            data = json.loads(body) if body else {}
            key_name = data.get("key", "").upper()
            
            KEY_MAP = {
                "HOME": 3,
                "BACK": 4,
                "POWER": 26,
                "VOLUME_UP": 24,
                "VOLUME_DOWN": 25,
                "MUTE": 164,
                "RECENTS": 187,
                "APP_SWITCH": 187,
                "MENU": 82,
                "ENTER": 66,
                "DELETE": 67,
                "BACKSPACE": 67,
                "TAB": 61,
                "SPACE": 62,
                "CAMERA": 27,
                "WAKEUP": 224,
                "SLEEP": 223
            }
            
            key_code = KEY_MAP.get(key_name, data.get("keycode", 3))
            long_press = data.get("long_press", False)
            
            if key_name == "NOTIFICATIONS":
                ok, _, err = run_adb(["shell", "cmd", "statusbar", "expand-notifications"])
            elif key_name == "QUICK_SETTINGS":
                ok, _, err = run_adb(["shell", "cmd", "statusbar", "expand-settings"])
            elif key_name == "COLLAPSE":
                ok, _, err = run_adb(["shell", "cmd", "statusbar", "collapse"])
            elif long_press:
                ok, _, err = run_adb(["shell", "input", "keyevent", "--longpress", str(key_code)])
            else:
                ok, _, err = run_adb(["shell", "input", "keyevent", str(key_code)])
                
            self._send_json({"success": ok, "key": key_name, "keycode": key_code, "error": err if not ok else None})

        elif path == "/api/text":
            body = self.rfile.read(content_length).decode("utf-8")
            data = json.loads(body) if body else {}
            raw_text = data.get("text", "")
            
            safe_text = raw_text.replace(" ", "%s").replace("&", "\\&").replace("'", "\\'").replace('"', '\\"')
            ok, _, err = run_adb(["shell", "input", "text", safe_text])
            self._send_json({"success": ok, "text": raw_text, "error": err if not ok else None})

        elif path == "/api/tap":
            body = self.rfile.read(content_length).decode("utf-8")
            data = json.loads(body) if body else {}
            x = int(data.get("x", 540))
            y = int(data.get("y", 1200))
            ok, _, err = run_adb(["shell", "input", "tap", str(x), str(y)])
            self._send_json({"success": ok, "x": x, "y": y, "error": err if not ok else None})

        elif path == "/api/swipe":
            body = self.rfile.read(content_length).decode("utf-8")
            data = json.loads(body) if body else {}
            x1 = int(data.get("x1", 540))
            y1 = int(data.get("y1", 1800))
            x2 = int(data.get("x2", 540))
            y2 = int(data.get("y2", 600))
            duration = int(data.get("duration", 250))
            ok, _, err = run_adb(["shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration)])
            self._send_json({"success": ok, "swipe": [x1, y1, x2, y2, duration], "error": err if not ok else None})

        elif path == "/api/upload":
            content_type = self.headers.get("Content-Type", "")
            if "multipart/form-data" in content_type:
                boundary = content_type.split("boundary=")[-1].encode("utf-8")
                raw_data = self.rfile.read(content_length)
                parts = raw_data.split(b"--" + boundary)
                apk_content = None
                filename = "uploaded_app.apk"
                
                for part in parts:
                    if b"Content-Disposition" in part and b'filename="' in part:
                        header_part, body_part = part.split(b"\r\n\r\n", 1)
                        apk_content = body_part.rstrip(b"\r\n")
                        m = re.search(rb'filename="([^"]+)"', header_part)
                        if m:
                            filename = m.group(1).decode("utf-8", errors="ignore")
                        break
                        
                if apk_content:
                    tmp_apk = f"/tmp/{filename}"
                    with open(tmp_apk, "wb") as f:
                        f.write(apk_content)
                    
                    ok, out, err = run_adb(["install", "-r", "-g", tmp_apk], timeout=120)
                    try:
                        os.remove(tmp_apk)
                    except Exception:
                        pass
                    
                    if ok:
                        self._send_json({"success": True, "filename": filename, "message": f"Cài đặt thành công: {out}"})
                    else:
                        self._send_json({"success": False, "filename": filename, "error": f"Lỗi cài đặt: {err or out}"}, status_code=500)
                else:
                    self._send_json({"success": False, "error": "Không tìm thấy file đính kèm"}, status_code=400)
            else:
                self._send_json({"success": False, "error": "Yêu cầu định dạng multipart/form-data"}, status_code=400)

        elif path == "/api/rotate":
            body = self.rfile.read(content_length).decode("utf-8")
            data = json.loads(body) if body else {}
            orientation = int(data.get("orientation", 0))
            run_adb(["shell", "settings", "put", "system", "accelerometer_rotation", "0"])
            ok, _, err = run_adb(["shell", "settings", "put", "system", "user_rotation", str(orientation)])
            self._send_json({"success": ok, "orientation": orientation})

        elif path == "/api/shell":
            body = self.rfile.read(content_length).decode("utf-8")
            data = json.loads(body) if body else {}
            cmd = data.get("command", "").strip()
            if not cmd:
                self._send_json({"success": False, "error": "Thiếu tham số command"}, status_code=400)
                return
            ok, out, err = run_adb(["shell", cmd])
            self._send_json({"success": ok, "command": cmd, "stdout": out, "stderr": err})

        else:
            self._send_json({"error": "Endpoint không tồn tại"}, status_code=404)

def main():
    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, CloudPhoneAPIHandler)
    print(f"🚀 [Pixel 10 Pro Gateway] API Server đang lắng nghe tại http://0.0.0.0:{PORT} (HAS_PIL={HAS_PIL})", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Đang dừng server...", flush=True)
        httpd.server_close()

if __name__ == "__main__":
    main()

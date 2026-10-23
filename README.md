# HyperMac — The Ultimate macOS All-in-One Power Utility Suite

[![Version](https://img.shields.io/badge/version-v1.2.0-blue.svg)](https://github.com/khacdai24/HyperMac)
[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-black.svg)](https://github.com/khacdai24/HyperMac)
[![Architecture](https://img.shields.io/badge/architecture-Apple%20Silicon%20(ARM64)-brightgreen.svg)](https://github.com/khacdai24/HyperMac)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

**HyperMac** là bộ siêu công cụ tất-cả-trong-một (All-in-One Super Suite) viết bằng **Swift thuần** dành riêng cho macOS Apple Silicon. Ứng dụng siêu nhẹ, mượt mà, khởi động tức thì và **hoàn toàn miễn phí**, thay thế trọn bộ 4 ứng dụng nặng nề riêng lẻ: **Rectangle**, **AltTab**, **AlDente Pro**, và **BetterDisplay**.

---

## 🚀 Các Tính Năng Chính

### 1. 🪟 Chia Cửa Sổ & Đa Màn Hình (Thay thế hoàn toàn Rectangle)
Điều khiển và bố trí cửa sổ cực nhanh bằng bàn phím với độ trễ 0ms thông qua Accessibility API:
- **`⌥ Option + ⌃ Control + ←`**: Chia cửa sổ sang **Nửa trái màn hình (Left Half)**.
- **`⌥ Option + ⌃ Control + →`**: Chia cửa sổ sang **Nửa phải màn hình (Right Half)**.
- **`⌥ Option + ⌃ Control + ↑`**: Phóng to toàn màn hình **(Maximize)**.
- **`⌥ Option + ⌃ Control + ↓`**: Đưa cửa sổ về chính giữa màn hình **(Center)**.
- **`⌥ Option + ⌘ Command + →`**: Chuyển cửa sổ hiện tại sang **Màn hình tiếp theo bên phải (Next Display)**.
- **`⌥ Option + ⌘ Command + ←`**: Chuyển cửa sổ hiện tại sang **Màn hình tiếp theo bên trái (Previous Display)**.

---

### 2. 🔄 Chuyển Đổi Cửa Sổ Thông Minh (Thay thế hoàn toàn AltTab)
Trình chuyển đổi cửa sổ trực quan thay thế thanh Dock mặc định của macOS với giao diện Liquid Glass hiện đại:
- **Phím tắt chính:** Nhấn giữ **`⌘ Command + Tab`** (hoặc `⌥ Option + Tab`).
- **Chuẩn MRU (Most Recently Used):** Đang ở App A chuyển sang App B, bấm `⌘ + Tab` nhả ra ngay sẽ **lập tức quay trở lại App A** (tương tự Windows Alt-Tab và AltTab gốc).
- **Ảnh thu nhỏ thực tế (Isolated Live Previews):** Mỗi thẻ hiển thị ảnh chụp nội dung độc lập của chính cửa sổ đó (sử dụng CoreGraphics `optionIncludingWindow: 8`), không bao giờ bị đè ảnh nền hay lẫn lộn giữa các ứng dụng.
- **Phím điều hướng nhanh:**
  - `⌘ + Tab`: Chuyển tới cửa sổ tiếp theo.
  - `⌘ + ⇧ Shift + Tab` hoặc phím **`~`**: Lùi về cửa sổ trước.
  - Phím **`W`**: Đóng nhanh cửa sổ đang chọn.
  - Phím **`Q`**: Thoát hẳn ứng dụng (`Quit Application`).
  - Phím **`⎋ Esc`**: Hủy thao tác chuyển đổi.

---

### 3. 🛡️ Bảo Vệ Pin & Phần Cứng (Thay thế AlDente Pro)
Bảo vệ cell pin máy Mac tối đa ở tầng vi điều khiển phần cứng của Apple (SMC):
- **Khóa sạc ở 80% (AC Bypass Mode):** Ghi trực tiếp vào thanh ghi SMC `CHTE = 01000000`, ngắt sạc hoàn toàn khi pin chạm ngưỡng 80%. Máy chạy điện trực tiếp từ củ sạc, triệt tiêu nguy cơ chai pin và phồng pin do sạc nhồi 100%.
- **Nút "⚡️ Sạc đầy 100% tạm thời (Top-Up)":** Bật sạc đầy 1 lần khi bạn chuẩn bị đi công tác hoặc ra ngoài.
- **Bảng đo Telemetry thời gian thực:**
  - Dung lượng thực tế (`Nominal / Design Capacity mAh`).
  - Chu kỳ sạc (`Cycle Count`).
  - Nhiệt độ pin (`°C`), điện áp (`Voltage`), dòng sạc (`Amperage`).
- **Hệ thống cảnh báo an toàn:**
  - ⚠️ Cảnh báo cắm màn hình ngoài nhưng chưa cắm sạc (tránh vắt kiệt pin).
  - 🚨 Cảnh báo pin yếu (< 20% và < 10%) để chống hiện tượng tụt áp sâu (Deep Discharge).
  - 🌡️ Cảnh báo pin quá nhiệt (> 38°C) để bảo vệ cell pin.

---

### 4. 🖥️ Điều Khiển Màn Hình & Độ Sáng (Thay thế BetterDisplay)
- **Phím tắt `F1 / F2` thông minh:** Tự động nhận diện và tăng/giảm độ sáng màn hình theo vị trí con trỏ chuột (chỉnh được cả màn hình ngoài lẫn màn hình tích hợp của MacBook Air/Pro).
- **Giao diện OSD Apple:** Hiển thị thanh trượt độ sáng bo cong trong suốt nổi trên màn hình tương ứng.
- **Soft-Disconnect:** Ngắt màn hình mềm độc lập không làm xáo trộn không gian làm việc.

---

### 5. 🖱️ Mouse Chording
- Bấm đồng thời **Chuột Trái + Chuột Phải** $\rightarrow$ Mở ngay `Mission Control (F3)` mà không cần dùng đến bàn phím.

---

## 📦 Cài Đặt & Khởi Chạy

### Cách 1: Sử dụng bộ cài dựng sẵn
Ứng dụng được cài đặt trực tiếp tại:
```bash
/Applications/HyperMac.app
```
Mở từ Spotlight (`Cmd + Space` gõ `HyperMac`) hoặc bấm vào icon `⌘` trên thanh Menu Bar.

### Cách 2: Tự biên dịch từ mã nguồn (Build from source)
Yêu cầu: macOS 14.0 trở lên, Apple Silicon Mac (M1/M2/M3/M4), Xcode Command Line Tools.

```bash
git clone https://github.com/khacdai24/HyperMac.git
cd HyperMac
./build.sh
```

---

## 🔐 Cấp Quyền Hệ Thống

Để HyperMac có thể điều khiển phím tắt và chia cửa sổ, bạn chỉ cần cấp quyền 1 lần duy nhất trong **System Settings (Cài đặt hệ thống)**:
1. **Trợ năng (Accessibility):** *System Settings > Privacy & Security > Accessibility* $\rightarrow$ Bật **HyperMac**. (Dùng cho bắt phím tắt, AltTab và chia cửa sổ).
2. **Ghi màn hình (Screen Recording):** *System Settings > Privacy & Security > Screen Recording* $\rightarrow$ Bật **HyperMac**. (Tùy chọn: dùng để hiển thị ảnh chụp nội dung thực tế bên trong thẻ AltTab).

---

## 📝 Nhật Ký Phiên Bản (Changelog)

### [v1.2.0] — 2026-10-23
- **Tính năng mới:** Tích hợp bộ chia cửa sổ và đa màn hình thông minh (Thay thế hoàn toàn Rectangle):
  - Phím tắt `⌥⌃←/→/↑/↓` chia nửa trái, nửa phải, toàn màn hình và căn giữa.
  - Phím tắt `⌥⌘←/→` chuyển cửa sổ qua lại giữa các màn hình ngoài và màn hình MacBook.
- **Gỡ bỏ hoàn toàn:** Đã gỡ bỏ sạch sẽ ứng dụng và cấu hình của `Rectangle.app`.
- **Tối ưu:** Cập nhật bảng điều khiển Menu Bar cho phép bật/tắt Window Snapping.

### [v1.1.0] — 2026-10-23
- **Tính năng mới:** Thay thế phím tắt `Option + Tab` bằng `Command + Tab` làm phím mặc định cho AltTab.
- **Sửa lỗi:** Tích hợp ngăn xếp `mruWindowIDs` chuẩn MRU: Bấm `Cmd + Tab` liên tục sẽ đảo chính xác qua lại giữa 2 cửa sổ gần nhất.
- **Sửa lỗi Preview:** Dùng CoreGraphics `optionIncludingWindow: 8` để ảnh thu nhỏ chụp đúng 100% nội dung của từng cửa sổ riêng biệt.
- **Thiết kế lại UI:** Thu gọn HUD AltTab từ 410px xuống 225px, bỏ khung review lớn, hiển thị chuẩn AltTab gốc.
- **Gỡ bỏ hoàn toàn:** Đã gỡ bỏ sạch sẽ ứng dụng và cấu hình của `AltTab.app`.

### [v1.0.0] — 2026-10-23
- Bản phát hành đầu tiên: Điều khiển độ sáng F1/F2 màn hình trong & ngoài, bảo vệ pin 80% (SMC AC Bypass), đo thông số pin thời gian thực, Mouse Chording mở Mission Control.

---

## 👤 Tác Giả & Bản Quyền
- Phát triển bởi **Nguyễn Khắc Đại** ([@khacdai24](https://github.com/khacdai24)).
- Mã nguồn phát hành dưới giấy phép MIT License.

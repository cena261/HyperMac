# HyperMac — The Ultimate macOS All-in-One Power Utility Suite

[![Version](https://img.shields.io/badge/version-v1.3.1-blue.svg)](https://github.com/khacdai24/HyperMac)
[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-black.svg)](https://github.com/khacdai24/HyperMac)
[![Architecture](https://img.shields.io/badge/architecture-Apple%20Silicon%20(ARM64)-brightgreen.svg)](https://github.com/khacdai24/HyperMac)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

**HyperMac** là bộ siêu công cụ tất-cả-trong-một (All-in-One Super Suite) viết bằng **Swift thuần** dành riêng cho macOS Apple Silicon. Ứng dụng siêu nhẹ, mượt mà, khởi động tức thì và **hoàn toàn miễn phí**, thay thế trọn bộ 4 ứng dụng nặng nề riêng lẻ: **Rectangle**, **AltTab**, **AlDente Pro**, và **BetterDisplay**.

---

## 🚀 Các Trục Tính Năng Trọng Tâm

### 🛡️ TRỤC 2: BẢO VỆ PHẦN CỨNG & GIỮ MÁY TỐI ĐA (Hardware Care & Longevity)

Thiết kế chuyên sâu dành cho người dùng kỹ tính và các dòng máy không quạt như **MacBook Air M2/M3**:

#### 1. Chống Chai Pin Cấp Độ Vi Điều Khiển (SMC AC Bypass)
- **Khóa sạc ở 80% (AC Bypass Mode):** Ghi trực tiếp vào thanh ghi SMC của Apple (`CHTE = 01000000`), ngắt sạc an toàn khi pin đạt 80%. Máy chuyển sang chạy điện trực tiếp từ củ sạc, triệt tiêu hoàn toàn hiện tượng chai pin, phồng pin do sạc nhồi 100%.
- **Sạc đầy tạm thời (Top-Up):** Nút 1-chạm sạc đầy 100% khi chuẩn bị đi công tác hoặc cần mang máy ra ngoài.
- **Tùy chọn ngưỡng khóa linh hoạt:** 70%, 80% (Khuyến nghị chuẩn), hoặc 90%.

#### 2. Sleep Guard — Chống Tụt Pin & Chống Nóng Ngầm Khi Gập Máy
- **Khóa cứng SMC khi gập máy:** Đảm bảo khi gập nắp máy lúc đang cắm sạc, phần cứng luôn duy trì lệnh ngắt sạc (Bypass), không bao giờ bị macOS sạc lố lên 100% lúc ngủ.
- **Tự động ngắt Bluetooth khi gập máy:** Loại bỏ triệt để hiện tượng chuột bluetooth hoặc AirPods xung quanh vô tình kích hoạt "Dark Wake" khiến máy hoạt động ngầm, nóng rực trong balo và tụt pin qua đêm.
- **Bật lại Bluetooth tức thì khi mở máy:** Kết nối lại liền mạch không cần thao tác thủ công.
- **Báo cáo sau giấc ngủ:** Hiển thị thời lượng gập máy và lượng pin tiêu hao (đạt chuẩn **0% hao hụt pin qua đêm**).

#### 3. Giám Sát Năng Lượng & Đóng Băng Tiến Trình (Process Energy & Freeze)
- **Đặc trị cho MacBook Air không quạt:** Phát hiện ngay các tiến trình ngốn CPU bất thường làm nóng máy (Chrome Renderer, Node, Docker, tiến trình nền bị treo).
- **Cơ chế Đóng băng (SIGSTOP):** Tạm dừng thực thi tiến trình về 0.0% CPU chỉ với 1 click. Giữ nguyên 100% dữ liệu và các tab trình duyệt trong RAM nhưng triệt tiêu hoàn toàn nhiệt lượng tỏa ra.
- **Rã đông (SIGCONT):** Tiếp tục hoạt động tức thì ngay khi cần sử dụng tiếp.
- **Cảnh báo nhiệt độ pin (> 38°C):** Cảnh báo người dùng kê thoáng máy và gợi ý đóng băng ứng dụng nặng để hạ nhiệt tức thì.

#### 4. Đặt Lịch Tự Động Hiệu Chuẩn Mạch Pin (Scheduled Texas Instruments BMS Calibration)
- Pin duy trì ở mức 80% liên tục có thể khiến chip quản lý pin BMS bị sai lệch thước đo dung lượng thực.
- **Tự động đặt lịch định kỳ:** Người dùng không cần để ý hay canh chừng. HyperMac cho phép hẹn lịch định kỳ: **Mỗi 30 ngày (Khuyến nghị chuẩn)**, **Mỗi 45 ngày** hoặc **Mỗi 60 ngày**.
- **Tiến trình tự động khép kín:** Khi đến hẹn và máy đang cắm nguồn sạc AC, HyperMac tự động tiến hành chu trình 3 bước:
  1. *Bước 1: Xả pin tự nhiên xuống 20%*.
  2. *Bước 2: Sạc liên tục lên 100% để cân bằng điện áp các cell (Cell Balancing)*.
  3. *Bước 3: Ngâm ổn định 15 phút và tự động khóa lại ở 80% SMC Bypass*.
- Hiển thị ngày hiệu chuẩn gần nhất, ngày tiếp theo, số ngày đếm ngược và trạng thái chi tiết.

#### 5. Bảng Đo Telemetry & Công Suất Watt Thời Gian Thực
- **Công suất dòng điện vào/ra pin (Wattage):**
  - Khi chạy Bypass: `0.0W (Nguồn AC trực tiếp • Pin nghỉ hoàn toàn)`.
  - Khi đang sạc: `+18.5W (Sạc nhanh)`.
  - Khi dùng pin: `-4.2W (Xả pin)`.
- **Thông tin củ sạc:** Nhận diện công suất củ sạc Apple USB-C PD (30W, 35W, 70W...) và số Serial củ sạc.
- **Độ khỏe cell chuẩn xác:** Tỷ lệ `NominalChargeCapacity / DesignCapacity` (e.g. `99.2% - 4527 / 4563 mAh`).
- **Chu kỳ sạc & IC:** Hiển thị số chu kỳ (`Cycle Count / 1000`) và chip đo áp chuyên dụng `TI bq40z651`.

---

### 🪟 TRỤC 1: TRẢI NGHIỆM THAO TÁC & ĐIỀU KHIỂN

#### 1. Chia Cửa Sổ & Đa Màn Hình (Thay thế hoàn toàn Rectangle)
Điều khiển và bố trí cửa sổ cực nhanh bằng bàn phím với độ trễ 0ms thông qua Accessibility API:
- **`⌥ Option + ⌃ Control + ←`**: Chia cửa sổ sang **Nửa trái màn hình (Left Half)**.
- **`⌥ Option + ⌃ Control + →`**: Chia cửa sổ sang **Nửa phải màn hình (Right Half)**.
- **`⌥ Option + ⌃ Control + ↑`**: Phóng to toàn màn hình **(Maximize)**.
- **`⌥ Option + ⌃ Control + ↓`**: Đưa cửa sổ về chính giữa màn hình **(Center)**.
- **`⌥ Option + ⌘ Command + →`**: Chuyển cửa sổ hiện tại sang **Màn hình tiếp theo bên phải (Next Display)**.
- **`⌥ Option + ⌘ Command + ←`**: Chuyển cửa sổ hiện tại sang **Màn hình tiếp theo bên trái (Previous Display)**.

#### 2. Chuyển Đổi Cửa Sổ Thông Minh (Thay thế hoàn toàn AltTab)
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

#### 3. Điều Khiển Màn Hình & Độ Sáng (Thay thế BetterDisplay)
- **Phím tắt `F1 / F2` thông minh:** Tự động nhận diện và tăng/giảm độ sáng màn hình theo vị trí con trỏ chuột (chỉnh được cả màn hình ngoài lẫn màn hình tích hợp của MacBook Air/Pro).
- **Giao diện OSD Apple:** Hiển thị thanh trượt độ sáng bo cong trong suốt nổi trên màn hình tương ứng.

#### 4. Mouse Chording
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

Để HyperMac có thể điều khiển phím tắt và chia cửa sổ, bạn chỉ cần cấp quyền trong **System Settings (Cài đặt hệ thống)**:
1. **Trợ năng (Accessibility):** *System Settings > Privacy & Security > Accessibility* $\rightarrow$ Bật **HyperMac**. (Dùng cho bắt phím tắt F1/F2, AltTab và chia cửa sổ).
2. **Ghi màn hình (Screen Recording):** *System Settings > Privacy & Security > Screen Recording* $\rightarrow$ Bật **HyperMac**. (Tùy chọn: dùng để hiển thị ảnh chụp nội dung thực tế bên trong thẻ AltTab).
3. **Quyền điều khiển nguồn SMC:** Bấm nút kích hoạt 1 lần bằng Touch ID / Mật khẩu trên thẻ pin để cài đặt helper `displaycontrol-power`.

---

## 📝 Nhật Ký Phiên Bản (Changelog)

### [v1.3.1] — 2026-10-23
- **Tái Cấu Trúc Toàn Diện Giao Diện Menu Bar (Tabbed Navigation - Triệt tiêu lỗi che khuất):**
  - Chuyển đổi từ bố cục cuộn dọc nguyên khối (bị tràn và che khuất nửa dưới) sang mô hình **3 Tab Độc Lập**:
    - `🛡️ Pin & Phần cứng`: Trọn vẹn bảng điều khiển nguồn SMC, Sleep Guard, Đóng băng ứng dụng và Hiệu chuẩn.
    - `🖥️ Màn hình`: Quản lý danh sách màn hình, thanh trượt độ sáng mượt mà, ngắt màn hình ảo và phím tắt F1/F2.
    - `⚡️ Phím tắt & Cửa sổ`: Cấu hình AltTab `⌘ + Tab`, bộ chia cửa sổ Rectangle `⌥⌃←/→` và Mouse Chording.
  - Tối ưu kích thước popover `380x570px`, bố cục thẻ thoáng đãng, sắc nét, đạt tỷ lệ vàng công thái học.
- **Tự Động Hóa Đặt Lịch Hiệu Chuẩn Pin (Scheduled BMS Calibration):**
  - Bổ sung tùy chọn hẹn lịch tự động định kỳ: **Mỗi 30 ngày (Khuyến nghị chuẩn)**, **Mỗi 45 ngày**, hoặc **Mỗi 60 ngày**.
  - Hiển thị ngày hiệu chuẩn gần nhất, ngày tiếp theo, số ngày đếm ngược và trạng thái kích hoạt.
  - Tự động phát hiện khi tới hẹn và đang cắm sạc AC để kích hoạt chu trình 3 bước (Xả $\rightarrow$ Cân bằng cell 100% $\rightarrow$ Tự động khóa lại ở 80% SMC Bypass) kèm thông báo hệ thống.

### [v1.3.0] — 2026-10-23
- **Hoàn thiện Trục 2: Bảo vệ Phần cứng & Giữ máy tối đa (Hardware Care & Longevity)**:
  - **Sleep Guard:** Tự động ngắt Bluetooth khi gập máy chống Dark Wake, khóa cứng lệnh SMC Bypass 80% khi ngủ, tính toán báo cáo thời lượng ngủ và mức hao pin (0% drain).
  - **Giám sát năng lượng & Đóng băng ứng dụng (Process Energy & Freeze):** Quét các tiến trình nặng ngốn CPU trên chip M2; hỗ trợ "Đóng băng" (`kill -STOP`) hạ CPU về 0% và triệt tiêu nhiệt lượng mà không mất dữ liệu, cùng nút "Rã đông" (`kill -CONT`).
  - **Hiệu chuẩn pin tự động (Texas Instruments BMS Calibration):** Quy trình 3 bước khôi phục dung lượng chuẩn và cân bằng cell pin định kỳ.
  - **Bảng đo Telemetry & Wattage:** Tính toán công suất sạc thời gian thực (0.0W ở chế độ Bypass, +Watt khi sạc, -Watt khi dùng pin), đọc thông số củ sạc Apple USB-C và vi mạch Texas Instruments `bq40z651`.
  - **Giao diện Menu Bar chuẩn Hallmark:** Bổ sung thanh điều hướng 4 phân hệ phần cứng (`Nguồn & Pin`, `Sleep Guard`, `Đóng băng`, `Hiệu chuẩn`).

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

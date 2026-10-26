# HyperMac — The Ultimate macOS All-in-One Power Utility Suite

[![Version](https://img.shields.io/badge/version-v1.4.7-blue.svg)](https://github.com/mrgoose000000-gif/HyperMac)
[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-black.svg)](https://github.com/mrgoose000000-gif/HyperMac)
[![Architecture](https://img.shields.io/badge/architecture-Apple%20Silicon%20(ARM64)-brightgreen.svg)](https://github.com/mrgoose000000-gif/HyperMac)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

**HyperMac** là bộ siêu công cụ tất-cả-trong-một (All-in-One Super Suite) viết bằng **Swift thuần** dành riêng cho macOS Apple Silicon. Ứng dụng siêu nhẹ, mượt mà, khởi động tức thì và **hoàn toàn miễn phí**, thay thế trọn bộ 5 ứng dụng nặng nề riêng lẻ: **Rectangle**, **AltTab**, **Maccy**, **AlDente Pro**, và **BetterDisplay**.

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

#### 3. Quản Lý Clipboard Thông Minh (Thay thế hoàn toàn Maccy)
Trình quản lý lịch sử sao chép với giao diện nổi Liquid Glass, tìm kiếm mờ tức thì và dán nhanh bằng bàn phím:
- **Phím tắt gọi nhanh:** Nhấn **`⌘ Command + ⇧ Shift + C`** (hoặc `⌘ + ⇧ + V`) để mở ngay bảng Clipboard nổi tại vị trí con trỏ chuột hoặc giữa màn hình.
- **Phím số `1..9` dán tức thì:** Bấm phím số từ 1 đến 9 để tự động dán ngay mục tương ứng vào ứng dụng bạn đang soạn thảo mà không cần click chuột.
- **Tìm kiếm mờ (Fuzzy Instant Search):** Gõ trực tiếp để lọc nhanh văn bản, liên kết, mã màu hoặc tên ứng dụng nguồn.
- **Nhận diện đa phương tiện thông minh:**
  - *Văn bản thuần & Định dạng (Plain Text & RTF).*
  - *Hình ảnh:* Tự tạo ảnh thu nhỏ (thumbnail) sắc nét kèm kích thước pixel.
  - *Liên kết web (URLs):* Nhận diện tên miền và biểu tượng web.
  - *Mã màu Hex/RGB:* Tự động render ô màu thực tế (color swatch) với mã màu (ví dụ `#3B82F6`).
  - *Tệp tin & Thư mục:* Nhận diện đường dẫn file kèm icon hệ thống macOS.
- **Phím tắt điều hướng nhanh:**
  - Phím **`1..9`**: Dán nhanh mục 1 tới 9.
  - Phím **`↵ Enter`**: Dán mục đang chọn.
  - Phím **`⌥ Option + P`**: Ghim / Bỏ ghim mục yêu thích lên đầu danh sách.
  - Phím **`⌥ Option + ⌫ Delete`**: Xóa nhanh mục đang chọn.
  - Phím **`⎋ Esc`**: Đóng bảng Clipboard.
- **Bảo mật tuyệt đối:** Tự động phát hiện và bỏ qua mật khẩu hoặc dữ liệu nhạy cảm được sao chép từ 1Password, Bitwarden, KeePass, Apple Keychain.

#### 4. Điều Khiển Màn Hình & Độ Sáng (Thay thế BetterDisplay)
- **Phím tắt `F1 / F2` thông minh:** Tự động nhận diện và tăng/giảm độ sáng màn hình theo vị trí con trỏ chuột (chỉnh được cả màn hình ngoài lẫn màn hình tích hợp của MacBook Air/Pro).
- **Giao diện OSD Apple:** Hiển thị thanh trượt độ sáng bo cong trong suốt nổi trên màn hình tương ứng.

#### 5. Mouse Chording
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
git clone https://github.com/mrgoose000000-gif/HyperMac.git
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

### [v1.4.7] — 2026-10-26
- **Sửa Lỗi Tự Tắt/Crash Khi Gập Màn Hình MacBook (Sleep Guard TCC Crash Fix):**
  - **Khắc phục lỗi TCC SIGABRT:** Trước đây khi gập màn hình MacBook, tính năng Sleep Guard tự động kích hoạt ngắt Bluetooth chống hao pin. Tuy nhiên do `Info.plist` thiếu trường `NSBluetoothAlwaysUsageDescription`, hệ thống bảo mật macOS TCC đã chủ động crash tiến trình với mã `SIGABRT`.
  - **Bổ sung quyền bảo mật đầy đủ:** Đã thêm `NSBluetoothAlwaysUsageDescription` và `NSBluetoothPeripheralUsageDescription` vào `Info.plist`.
  - **Bộ lọc an toàn (Safety Guard):** Bổ sung kiểm tra bundle metadata trong `BluetoothManager.swift` để không bao giờ gọi hàm Bluetooth cấp thấp nếu thiếu quyền, ngăn chặn triệt để nguy cơ crash.
- **Tối Ưu Hóa Bộ Nhớ RAM (-76% Footprint):**
  - Giảm Physical Footprint từ ~150MB xuống chỉ còn **~35MB**.
  - Tự động downsample ảnh chụp màn hình AltTab về kích thước tối đa 320px (~200KB thay vì 33MB/cửa sổ uncompressed raw).
  - Tự động thu hồi RAM khi đóng overlay AltTab (`hideOverlay`).
  - Nén ảnh clipboard sang định dạng JPEG chất lượng cao, thu nhỏ dung lượng `clipboard.json` từ 6.3MB xuống 477KB.
- **Chuyển Cửa Sổ Đa Màn Hình Chuẩn Rectangle:**
  - Hoàn thiện thuật toán tính tỷ lệ khung hình relativePositionedRect, settlement trễ 30ms cho WindowServer, giữ nguyên 100% kích thước cửa sổ khi chuyển giữa Retina và màn ngoài 1080p/2K/4K.

### [v1.4.6] — 2026-10-25
- **Sửa Lỗi: Giữ Nguyên Thẻ Màn Hình Ngoài Khi Bấm 'Ngắt Mềm' (Không Bị Mất Màn Hình):**
  - **Khắc phục lỗi biến mất thẻ:** Trước đây khi bấm "Ngắt màn ngoài", WindowServer thu nhỏ độ phân giải màn hình về $1 \times 1$ khiến bộ lọc hiểu nhầm là cổng ảo và loại bỏ khỏi danh sách, dẫn đến việc người dùng không tìm thấy nút "Bật lại".
  - **Duy trì thẻ và trạng thái rõ ràng:** Thẻ màn hình ngoài được giữ nguyên vẹn trong danh sách với nhãn `Đang ngắt mềm (Đã tắt)` cùng nút **`Bật lại`** nổi bật với biểu tượng nguồn.
  - **Cập nhật thanh QuickActionsBar:** Nút chuyển đổi nhanh tự động đổi tên và màu sắc thành `Bật màn ngoài` (màu xanh nổi bật) và `Bật tất cả màn hình` ngay khi có màn hình bị ngắt.
  - **Nhận diện chính xác tên màn hình ngoài trên Apple Silicon:** Tích hợp IOKit `AppleDisplayConnectionManager` giúp đọc đúng tên sản phẩm thực tế của màn hình (ví dụ: `U280-Pro`) thay vì chỉ hiện tên chung `External Display`.

### [v1.4.5] — 2026-10-24
- **Thử Nghiệm Tính Năng Tự Động Cập Nhật 1-Chạm (In-App Auto-Update Test Release):**
  - Bản phát hành thực tế để kiểm tra quy trình tự động cập nhật từ máy khách.
  - Tải tự động gói `HyperMac.zip` từ GitHub Release và cài đặt trực tiếp.

### [v1.4.4] — 2026-10-24
- **Tính năng mới: Kiểm Tra & Tự Động Cập Nhật 1-Chạm (In-App Auto-Update):**
  - **Tối ưu trải nghiệm chia sẻ mã nguồn mở:** Người dùng tải về từ GitHub không còn phải cập nhật thủ công mỗi khi có bản mới.
  - **Kiểm tra phiên bản tức thì:** Nút "Kiểm tra cập nhật" ở chân trang (Footer) và huy hiệu phiên bản ở đầu trang (Header) cho phép kiểm tra phiên bản mới từ GitHub Releases và tệp manifest `version.json` bất cứ lúc nào.
  - **Tự động tải & Cập nhật liền mạch (In-place Atomic Update):** Khi phát hiện bản mới, chỉ cần bấm "Cập nhật ngay", HyperMac sẽ tự động tải file `HyperMac.zip`, giải nén, ghi đè an toàn vào `/Applications/HyperMac.app`, xóa cờ cách ly bảo mật macOS (`xattr -cr`) và khởi động lại phiên bản mới trong vòng 1-2 giây.
  - **Tùy chọn tự động kiểm tra:** Tự động kiểm tra bản cập nhật mới ngầm mỗi khi mở HyperMac (có thể bật/tắt trong cài đặt cập nhật).
  - **Tự động đóng gói Release:** Lệnh `./build.sh` tự động tạo sẵn file `build/HyperMac.zip` để đính kèm lên GitHub Releases mỗi khi phát hành phiên bản mới.

### [v1.4.3] — 2026-10-23
- **Tính năng mới: Chống Sleep Màn Hình Cấp Thấp (Native Caffeinate):**
  - **Thay thế hoàn toàn lệnh `caffeinate -d` trong Terminal:** Tích hợp trực tiếp Apple IOKit Power Management (`IOPMAssertionCreateWithName` với assertion type `kIOPMAssertionTypePreventUserIdleDisplaySleep`), hoạt động thuần 100% trong tiến trình HyperMac, không cần mở Terminal và không tốn thêm tiến trình con ngầm.
  - **Các mốc thời lượng linh hoạt (Preset Durations):** Chọn nhanh `Vô hạn` (Indefinite), `15m`, `30m`, `1h`, hoặc `2h`.
  - **Đồng hồ đếm ngược trực quan:** Hiển thị thời gian còn lại theo thời gian thực trên thanh tiêu đề Menu Bar (huy hiệu cà phê phát sáng màu cam) và thẻ điều khiển Caffeinate.
  - **Tự động gửi thông báo:** Khi hết giờ hẹn, hệ thống tự động gửi thông báo macOS thông báo màn hình đã trở về cơ chế ngủ tiết kiệm năng lượng bình thường.
  - **Giải phóng an toàn:** Tự động giải phóng Power Assertion khi tắt tính năng hoặc khi đóng ứng dụng HyperMac.
- **Sửa lỗi triệt để: Lỗi áp dụng cấu hình màn hình vào WindowServer (Mã lỗi: 1001):**
  - **Nguyên nhân:** Do WindowServer lưu vết cổng hiển thị ngoại vi đã ngắt kết nối (offline phantom display ID $1 \times 1$) khi máy không cắm dây cáp màn hình ngoài. Khi bấm "Bật lại", lệnh áp dụng cấu hình đồ họa bị từ chối với mã lỗi `1001` (`kCGErrorIllegalArgument`).
  - **Khắc phục:** Tự động lọc sạch các cổng hiển thị offline / không có tín hiệu vật lý. Bổ sung cơ chế dự phòng `CGRestorePermanentDisplayConfiguration` và hiển thị thông báo hướng dẫn cắm cáp kết nối vật lý thân thiện thay vì ném lỗi mã số hệ thống khó hiểu.

### [v1.4.2] — 2026-10-23
- **Tối Ưu Trải Nghiệm AltTab (Zero Window Shuffling When Cycling):**
  - **Giữ nguyên vẹn 100% bố cục cửa sổ nền khi lướt Tab:** Loại bỏ hành vi tự động nâng cửa sổ (`kAXRaiseAction`) trong lúc người dùng đang bấm phím `Tab` duyệt danh sách.
  - **Không làm xáo trộn các cửa sổ đang mở:** Bạn có thể thoải mái lướt qua các ứng dụng trung gian mà không sợ chúng tự động nhảy lên đè mất cửa sổ đang xem (ví dụ: Chrome không bị Antigravity đè lên khi bạn đang lướt tới Finder để chuyển tệp).
  - **Kích hoạt chính xác khi xác nhận:** Chỉ khi người dùng thực sự thả tay khỏi phím `⌘ Command` (hoặc nhấp chuột) thì cửa sổ được chọn mới được kích hoạt và đưa lên trên cùng.

### [v1.4.1] — 2026-10-23
- **Tối Ưu AltTab & Clipboard Manager Đa Không Gian (Multi-Desktop Spaces Support):**
  - **Tự do di chuyển trên mọi Desktop:** Loại bỏ cờ `.stationary` (trước đó khiến HUD bị kẹt cứng ở Desktop khởi tạo ban đầu). Bảng AltTab và Clipboard Manager giờ đây lập tức xuất hiện ngay trên bất kỳ Desktop nào (Desktop 1, Desktop 2, Fullscreen Spaces) mà con trỏ chuột đang hiện diện.
  - **Hiển thị tinh gọn theo từng không gian (Focused Desktop Workspaces):** Lọc và hiển thị chính xác các cửa sổ đang hoạt động trên màn hình của Desktop hiện tại, giữ cho giao diện siêu gọn nhẹ, không lẫn lộn giữa các không gian làm việc.
  - **Hỗ trợ khôi phục ứng dụng:** Tự động unhide ứng dụng bị ẩn (`⌘H`) và khôi phục cửa sổ thu nhỏ trên Dock (`minimize`) khi chọn.

### [v1.4.0] — 2026-10-23
- **Tính năng mới: Tích hợp Trình Quản Lý Clipboard Thông Minh (Thay thế hoàn toàn Maccy):**
  - **Gỡ bỏ hoàn toàn Maccy:** Xóa sạch sẽ ứng dụng `Maccy.app`, dữ liệu Container và preferences cũ.
  - **Phím tắt toàn cầu `⌘ Command + ⇧ Shift + C` (và `⌘⇧V`):** Mở bảng Clipboard nổi Liquid Glass cực nhanh tại vị trí con trỏ chuột.
  - **Dán siêu tốc với phím số `1..9`:** Bấm số 1 đến 9 để tự động dán ngay mục vào ứng dụng đích mà không cần nhấp chuột.
  - **Nhận diện đa phương tiện:** Hỗ trợ văn bản, định dạng RTF, ảnh thumbnail, liên kết URL, danh sách tệp tin và xem trước mã màu Hex/RGB.
  - **Thao tác nhanh:** `⌥P` ghim lên đầu, `⌥⌫` xóa mục, `↵` dán, tìm kiếm mờ instant search, phân loại thẻ lọc linh hoạt.
  - **Bảo mật:** Tự động nhận diện và bỏ qua dữ liệu từ các trình quản lý mật khẩu (1Password, Bitwarden, Keychain).
  - **Bảng điều khiển Menu Bar:** Tích hợp tùy chỉnh giới hạn lưu trữ (50/100/200 mục), nút mở HUD và xóa lịch sử.

### [v1.3.3] — 2026-10-23
- **Tối Ưu Hóa Quy Trình Hiệu Chuẩn Pin (Natural Cycle & Auto Balancing):**
  - Làm rõ và hoàn thiện cơ chế xả pin: Hướng dẫn người dùng rút sạc dùng tự nhiên xuống $\le 20\%$ (an toàn nhất cho tuổi thọ hóa chất cell pin, tránh nóng mạch chuyển đổi nguồn).
  - Tự động hóa giai đoạn sạc: Khi người dùng cắm sạc trở lại ở mức $\le 20\%$, HyperMac tự động nhận diện và chuyển thẳng sang Bước 2 (Nạp đầy 100% cân bằng cell $\rightarrow$ Ngâm 15 phút $\rightarrow$ Tự động khóa lại ở 80% SMC Bypass).
  - Cập nhật thông báo hệ thống và mẹo hiển thị trực quan trong popover.

### [v1.3.2] — 2026-10-23
- **Tối Ưu Trải Nghiệm Menu Bar (Tab Màn Hình Ưu Tiên Số 1):**
  - Đưa tab `🖥️ Màn hình` lên vị trí đầu tiên (Tab 0) và mặc định mở ngay khi bấm vào icon Menu Bar, đáp ứng thói quen thao tác điều chỉnh độ sáng và màn hình thường xuyên nhất của người dùng.
  - Sắp xếp lại thứ tự 3 Tab: `🖥️ Màn hình` $\rightarrow$ `🛡️ Pin & Phần cứng` $\rightarrow$ `⚡️ Phím tắt & Cửa sổ`.

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

import SwiftUI

// MARK: - Main MenuBar View

public struct MainView: View {
    @ObservedObject var displayManager: DisplayManager
    @ObservedObject var batteryManager: BatteryManager = BatteryManager.shared

    public init(displayManager: DisplayManager) {
        self.displayManager = displayManager
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(displayManager: displayManager)

            Divider().padding(.horizontal, 14)

            // Accessibility Warning Banner (If not yet granted)
            if !displayManager.hasAccessibility {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 13))
                        Text("Cần cấp quyền Trợ năng (Accessibility)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.primary)
                    }

                    Text("Để phím F1 / F2 bắt được sự kiện và điều khiển màn hình ngoài, macOS yêu cầu bạn bật HyperMac trong Cài đặt hệ thống.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Mở Cài đặt hệ thống...") {
                        displayManager.requestAccessibility()
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .controlSize(.small)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

                Divider().padding(.horizontal, 14)
            }

            // Keyboard Control Setting
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)

                Text("F1 / F2 chỉnh màn hình theo con trỏ chuột")
                    .font(.system(size: 11, weight: .medium))

                Spacer()

                Toggle("", isOn: Binding<Bool>(
                    get: { displayManager.isCursorBased },
                    set: { displayManager.isCursorBased = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))

            Divider().padding(.horizontal, 14)

            // Mouse Chord Setting (Simultaneous Left + Right Click -> F3 / Mission Control)
            HStack(spacing: 8) {
                Image(systemName: "cursorarrow.click.2")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)

                Text("Bấm đồng thời Chuột Trái + Phải mở F3")
                    .font(.system(size: 11, weight: .medium))

                Spacer()

                Toggle("", isOn: Binding<Bool>(
                    get: { displayManager.isMouseChordEnabled },
                    set: {
                        displayManager.isMouseChordEnabled = $0
                        UserDefaults.standard.set($0, forKey: "mouse_chord_enabled")
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))

            Divider().padding(.horizontal, 14)

            // AltTab Window Switcher Setting
            HStack(spacing: 8) {
                Image(systemName: "macwindow.on.rectangle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Command + Tab chuyển đổi cửa sổ (AltTab)")
                        .font(.system(size: 11, weight: .medium))
                    Text("Giữ ⌘ Command (hoặc ⌥) + Tab để xem trước Live Preview các cửa sổ")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding<Bool>(
                    get: { WindowManager.shared.isAltTabEnabled },
                    set: { WindowManager.shared.isAltTabEnabled = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))

            // Screen Recording Permission Helper for Live Thumbnails (AltTab Genuine)
            if WindowManager.shared.isAltTabEnabled && !WindowManager.shared.hasScreenRecording {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.cyan)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Xem trước ảnh chụp cửa sổ thực tế")
                            .font(.system(size: 9.5, weight: .semibold))
                        Text("Mặc định hiển thị Icon ứng dụng. Cần quyền Ghi màn hình nếu muốn hiện ảnh chụp nội dung cửa sổ.")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Cấp quyền...") {
                        WindowManager.shared.requestScreenRecordingPermission()
                    }
                    .font(.system(size: 8.5, weight: .semibold))
                    .controlSize(.mini)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.cyan.opacity(0.08))
            }

            Divider().padding(.horizontal, 14)

            // Window Snapping & Multi-Display Movement (Rectangle Replacement)
            HStack(spacing: 8) {
                Image(systemName: "rectangle.split.2x1")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Chia cửa sổ & Đa màn hình (Rectangle)")
                        .font(.system(size: 11, weight: .medium))
                    Text("⌥⌃←/→/↑/↓: Chia cửa sổ | ⌥⌘←/→: Chuyển sang màn khác")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding<Bool>(
                    get: { WindowSnapManager.shared.isSnapEnabled },
                    set: { WindowSnapManager.shared.isSnapEnabled = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))

            Divider().padding(.horizontal, 14)

            // Scrollable Content: Displays + Battery Protection Card
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Battery Protection & Hardware Health Card
                    BatteryCardView(batteryManager: batteryManager)

                    // Display Section Header
                    HStack(spacing: 5) {
                        Image(systemName: "display.2")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                        Text("DANH SÁCH MÀN HÌNH")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 2)

                    // Display List
                    if displayManager.monitors.isEmpty {
                        EmptyStateView()
                    } else {
                        ForEach(displayManager.monitors) { monitor in
                            DisplayCardView(
                                monitor: monitor,
                                displayManager: displayManager,
                                isSelected: displayManager.selectedID == monitor.id
                            )
                        }
                    }
                }
                .padding(14)
            }
            .frame(maxHeight: 520)

            Divider().padding(.horizontal, 14)

            // Quick Actions & Status
            QuickActionsBar(displayManager: displayManager)

            Divider().padding(.horizontal, 14)

            // Footer
            FooterView()
        }
        .frame(width: 360)
        .alert(isPresented: Binding<Bool>(
            get: { displayManager.showAlert },
            set: { displayManager.showAlert = $0 }
        )) {
            Alert(
                title: Text("Thông báo"),
                message: Text(displayManager.alertMessage ?? ""),
                dismissButton: .default(Text("Đã hiểu"))
            )
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    @ObservedObject var displayManager: DisplayManager

    private var coverImage: NSImage? {
        if let path = Bundle.main.path(forResource: "cover", ofType: "jpg") {
            return NSImage(contentsOfFile: path)
        }
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Cover Artwork
            Group {
                if let img = coverImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.indigo.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 110)
            .clipped()

            // Dark gradient overlay for text legibility
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.15), location: 0.0),
                    .init(color: Color.black.opacity(0.85), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Header Content Overlay
            VStack(alignment: .leading, spacing: 0) {
                // Top status bar row
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("\(displayManager.monitors.filter { $0.isConnected }.count) MÀN ĐANG BẬT")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(.ultraThinMaterial))

                    Spacer()

                    Button {
                        displayManager.refresh()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 26, height: 26)
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(displayManager.isRefreshing ? 360 : 0))
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Làm mới danh sách màn hình")
                }

                Spacer()

                // Bottom title & version row
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HyperMac")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
                        Text("Siêu công cụ điều khiển phần cứng & cửa sổ")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }

                    Spacer()

                    Text("v2.0")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.25)))
                        .foregroundStyle(.white)
                }
            }
            .padding(12)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

// MARK: - Display Card View

struct DisplayCardView: View {
    let monitor: DisplayInfo
    @ObservedObject var displayManager: DisplayManager
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: Device Info + Selection Badge + Power Toggle
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(monitor.isConnected
                              ? (isSelected ? Color.accentColor.opacity(0.2) : Color.accentColor.opacity(0.1))
                              : Color.secondary.opacity(0.1))
                        .frame(width: 38, height: 38)

                    Image(systemName: monitor.isBuiltIn ? "laptopcomputer" : "display")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(monitor.isConnected ? Color.accentColor : Color.secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(monitor.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(monitor.isConnected ? .primary : .secondary)
                            .lineLimit(1)

                        if isSelected {
                            Text("Đang chọn")
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                                .foregroundStyle(Color.accentColor)
                        }
                    }

                    HStack(spacing: 4) {
                        Text(monitor.resolution)
                        Text("•")
                        Text(monitor.isBuiltIn ? "Màn chính" : "Màn ngoài")
                        Text("•")
                        Circle()
                            .fill(monitor.isConnected ? Color.green : Color.orange)
                            .frame(width: 5, height: 5)
                        Text(monitor.isConnected ? "Đang bật" : "Đã ngắt")
                    }
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                // Connect / Disconnect Toggle Button
                Button {
                    displayManager.toggleConnection(for: monitor)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: monitor.isConnected ? "power.circle.fill" : "power.circle")
                            .font(.system(size: 11))
                        Text(monitor.isConnected ? "Ngắt" : "Bật lại")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(monitor.isConnected ? Color.red.opacity(0.12) : Color.green.opacity(0.18))
                    )
                    .foregroundStyle(monitor.isConnected ? Color.red : Color.green)
                }
                .buttonStyle(.plain)
                .help(monitor.isConnected ? "Ngắt hoàn toàn màn hình này" : "Bật lại kết nối màn hình này")
            }

            // Row 2: Brightness Slider or Disconnected Notice
            if monitor.isConnected {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.min")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)

                        Slider(
                            value: Binding<Double>(
                                get: { monitor.brightness },
                                set: { displayManager.setBrightness($0, for: monitor) }
                            ),
                            in: 0...1
                        )
                        .controlSize(.small)

                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.accentColor)

                        Text("\(Int(monitor.brightness * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .frame(width: 38, alignment: .trailing)
                    }

                    // Quick Brightness Presets
                    HStack(spacing: 6) {
                        ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { preset in
                            Button("\(Int(preset * 100))%") {
                                displayManager.setQuickBrightness(preset, for: monitor)
                            }
                            .font(.system(size: 9, weight: .medium))
                            .buttonStyle(.plain)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            )
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "power.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("Màn hình đã ngắt kết nối hoàn toàn")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.08))
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: isSelected ? Color.accentColor.opacity(0.12) : Color.black.opacity(0.04), radius: 4, y: 1)
        )
        .opacity(monitor.isConnected ? 1.0 : 0.6)
        .contentShape(Rectangle())
        .onTapGesture {
            displayManager.selectMonitor(monitor)
        }
    }
}

// MARK: - Quick Actions Bar

struct QuickActionsBar: View {
    @ObservedObject var displayManager: DisplayManager

    var body: some View {
        HStack(spacing: 8) {
            // Disconnect Main shortcut
            if let mainMonitor = displayManager.monitors.first(where: { $0.isBuiltIn }) {
                Button {
                    displayManager.toggleConnection(for: mainMonitor)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mainMonitor.isConnected ? "laptopcomputer.slash" : "laptopcomputer")
                            .font(.system(size: 10))
                        Text(mainMonitor.isConnected ? "Ngắt màn chính" : "Bật màn chính")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!mainMonitor.isConnected && !displayManager.canDisconnect(mainMonitor))
            }

            // Disconnect External shortcut
            if let extMonitor = displayManager.monitors.first(where: { !$0.isBuiltIn }) {
                Button {
                    displayManager.toggleConnection(for: extMonitor)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: extMonitor.isConnected ? "display.slash" : "display")
                            .font(.system(size: 10))
                        Text(extMonitor.isConnected ? "Ngắt màn ngoài" : "Bật màn ngoài")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Turn on all displays button
            if displayManager.monitors.contains(where: { !$0.isConnected }) {
                Button {
                    displayManager.connectAllDisplays()
                } label: {
                    Text("Bật tất cả")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "display.trianglebadge.exclamationmark")
                .font(.system(size: 26))
                .foregroundStyle(.tertiary)
            Text("Không tìm thấy màn hình nào")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

// MARK: - Battery Protection Card View

struct BatteryCardView: View {
    @ObservedObject var batteryManager: BatteryManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row: Icon + Title + Live Status Badge
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(batteryManager.isBypassActive ? Color.cyan.opacity(0.18) : Color.accentColor.opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: batteryManager.isBypassActive ? "shield.lefthalf.filled" : (batteryManager.isPluggedIn ? "bolt.batteryblock.fill" : "battery.100"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(batteryManager.isBypassActive ? Color.cyan : (batteryManager.isCharging ? Color.green : Color.accentColor))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("CHỐNG CHAI PIN (SMC)")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.primary)

                    Text(batteryManager.statusMessage)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 5.5, height: 5.5)
                    Text(badgeText)
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(badgeColor)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(badgeColor.opacity(0.12)))
            }

            // Battery Level Bar + Target Limit Notch
            VStack(spacing: 4) {
                HStack(alignment: .lastTextBaseline) {
                    HStack(spacing: 3) {
                        Text("\(batteryManager.currentLevel)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if batteryManager.timeRemaining > 0 && !batteryManager.isPluggedIn {
                        Text("Còn ~\(batteryManager.timeRemaining / 60)h\(batteryManager.timeRemaining % 60)m")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else if batteryManager.isBypassActive {
                        Text("🛡️ Chạy điện trực tiếp")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(.cyan)
                    } else if batteryManager.isCharging {
                        Text("⚡️ Đang sạc")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                }

                // Custom Progress Bar with Lock Notch
                GeometryReader { geo in
                    let width = geo.size.width
                    let levelFraction = min(1.0, max(0.0, Double(batteryManager.currentLevel) / 100.0))
                    let limitFraction = min(1.0, max(0.0, Double(batteryManager.chargeLimit) / 100.0))

                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 8)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: batteryManager.isBypassActive
                                        ? [Color.cyan, Color.blue]
                                        : [Color.green, Color.mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, width * levelFraction), height: 8)

                        // Notch at Charge Limit (e.g. 80%)
                        if batteryManager.isProtectionEnabled {
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: 2, height: 12)
                                .offset(x: max(0, width * limitFraction - 1), y: 0)
                        }
                    }
                }
                .frame(height: 12)

                // Notch label
                if batteryManager.isProtectionEnabled {
                    HStack {
                        Spacer()
                        Text("Ngưỡng khóa: \(batteryManager.chargeLimit)%")
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }
            }

            // 3-Chip Hardware Health Metrics
            HStack(spacing: 6) {
                // Metric 1: Health %
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.pink)
                        Text("Độ khỏe pin")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(batteryManager.healthPercent)%")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("\(batteryManager.nominalCapacity)/\(batteryManager.designCapacity) mAh")
                        .font(.system(size: 7))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.04)))

                // Metric 2: Cycles
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 8))
                            .foregroundStyle(.purple)
                        Text("Chu kỳ sạc")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(batteryManager.cycleCount) lần")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Thiết kế: 1000")
                        .font(.system(size: 7))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.04)))

                // Metric 3: Temp
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                        Text("Nhiệt độ")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.1f°C", batteryManager.temperature))
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(batteryManager.temperature < 35.0 ? "Mát mẻ" : "Hơi ấm")
                        .font(.system(size: 7))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.04)))
            }

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

            // Helper Installation Banner (if not installed)
            if !batteryManager.isHelperInstalled {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Image(systemName: "shield.checkered")
                            .foregroundStyle(.blue)
                            .font(.system(size: 11))
                        Text("Cấp quyền điều khiển nguồn SMC")
                            .font(.system(size: 10, weight: .bold))
                    }
                    Text("Để chuyển sang chế độ chạy điện trực tiếp từ sạc/màn hình ngoài (không nhồi pin qua 80%), cần cấp quyền 1 lần duy nhất.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        batteryManager.installHelper()
                    } label: {
                        HStack(spacing: 4) {
                            if batteryManager.isInstallingHelper {
                                ProgressView().controlSize(.mini)
                            } else {
                                Image(systemName: "touchid")
                                    .font(.system(size: 10))
                            }
                            Text(batteryManager.isInstallingHelper ? "Đang xác thực..." : "Kích hoạt bằng Touch ID / Mật khẩu")
                                .font(.system(size: 9.5, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(batteryManager.isInstallingHelper)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.2), lineWidth: 1))
                )
            } else {
                // Controls when helper IS installed:
                VStack(spacing: 8) {
                    // Toggle: Protect at limit
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.accentColor)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Khóa sạc ở \(batteryManager.chargeLimit)% (Chạy điện trực tiếp)")
                                .font(.system(size: 10.5, weight: .medium))
                            Text("Cắm sạc liên tục không chai pin (Bypass)")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding<Bool>(
                            get: { batteryManager.isProtectionEnabled },
                            set: { batteryManager.isProtectionEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                    }

                    // Limit Selector Pills (70%, 80%, 90%)
                    if batteryManager.isProtectionEnabled {
                        HStack(spacing: 6) {
                            Text("Mức khóa:")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundStyle(.secondary)

                            ForEach([70, 80, 90], id: \.self) { val in
                                Button {
                                    batteryManager.chargeLimit = val
                                } label: {
                                    Text("\(val)%\(val == 80 ? " (Chuẩn)" : "")")
                                        .font(.system(size: 8, weight: batteryManager.chargeLimit == val ? .bold : .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(
                                            Capsule()
                                                .fill(batteryManager.chargeLimit == val ? Color.accentColor : Color.primary.opacity(0.06))
                                        )
                                        .foregroundStyle(batteryManager.chargeLimit == val ? Color.white : Color.primary)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()
                        }
                    }

                    // Top-up temporary button
                    HStack(spacing: 8) {
                        Button {
                            batteryManager.isTopUpActive.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: batteryManager.isTopUpActive ? "xmark.circle" : "bolt.fill")
                                    .font(.system(size: 8.5))
                                Text(batteryManager.isTopUpActive ? "Hủy sạc 100% (Khóa lại)" : "⚡️ Sạc đầy 100% tạm thời")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(batteryManager.isTopUpActive ? Color.orange.opacity(0.18) : Color.primary.opacity(0.06))
                            .foregroundStyle(batteryManager.isTopUpActive ? Color.orange : Color.primary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("Khi cần mang máy ra ngoài")
                            .font(.system(size: 7.5))
                            .foregroundStyle(.tertiary)
                    }

                    // Temperature safety alert toggle
                    HStack(spacing: 6) {
                        Image(systemName: "thermometer.sun.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)

                        Text("Thông báo khi pin nóng > 38°C")
                            .font(.system(size: 8.5))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Toggle("", isOn: Binding<Bool>(
                            get: { batteryManager.isTempAlertEnabled },
                            set: { batteryManager.isTempAlertEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                    }

                    // Smart Anti-Wear Alerts (External display on battery, Low battery <20%, <10%)
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.blue)

                        Text("Cảnh báo chống chai pin (Màn ngoài, pin < 20%)")
                            .font(.system(size: 8.5))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Toggle("", isOn: Binding<Bool>(
                            get: { batteryManager.isSmartAlertsEnabled },
                            set: { batteryManager.isSmartAlertsEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(batteryManager.isBypassActive ? Color.cyan.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: batteryManager.isBypassActive ? Color.cyan.opacity(0.1) : Color.black.opacity(0.03), radius: 4, y: 1)
        )
    }

    private var badgeColor: Color {
        if batteryManager.isBypassActive {
            return .cyan
        } else if batteryManager.isCharging {
            return .green
        } else if batteryManager.isPluggedIn {
            return .orange
        } else {
            return .secondary
        }
    }

    private var badgeText: String {
        if batteryManager.isBypassActive {
            return "🛡️ AC BYPASS"
        } else if batteryManager.isCharging {
            return "⚡️ ĐANG SẠC"
        } else if batteryManager.isPluggedIn {
            return "🔌 ĐÃ CẮM ĐIỆN"
        } else {
            return "🔋 DÙNG PIN"
        }
    }
}

// MARK: - Footer

struct FooterView: View {
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.green)
                Text("Open Source • Miễn phí vĩnh viễn")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Thoát") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11))
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

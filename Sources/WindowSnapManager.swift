import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

// MARK: - Window Snap Actions

public enum SnapAction {
    case leftHalf
    case rightHalf
    case maximize
    case center
    case topHalf
    case bottomHalf
}

// MARK: - Window Snap Manager (Rectangle Replacement)

@MainActor
public class WindowSnapManager: ObservableObject {
    public static let shared = WindowSnapManager()

    @Published public var isSnapEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSnapEnabled, forKey: "window_snap_enabled")
        }
    }

    private init() {
        if UserDefaults.standard.object(forKey: "window_snap_enabled") != nil {
            self.isSnapEnabled = UserDefaults.standard.bool(forKey: "window_snap_enabled")
        } else {
            self.isSnapEnabled = true
        }
    }

    // MARK: - Coordinate Conversion (Cocoa Bottom-Left to Accessibility Top-Left)

    private func axVisibleFrame(for screen: NSScreen) -> CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        let f = screen.visibleFrame // Automatically excludes Menu Bar & Dock
        let axY = primaryHeight - (f.origin.y + f.height)
        return CGRect(x: f.origin.x, y: axY, width: f.width, height: f.height)
    }

    private func screenContaining(point: CGPoint) -> NSScreen {
        // AX point has origin at top-left of primary display
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 900
        let cocoaPoint = NSPoint(x: point.x, y: primaryHeight - point.y)

        for screen in NSScreen.screens {
            if NSPointInRect(cocoaPoint, screen.frame) {
                return screen
            }
        }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    // MARK: - Get Active Focused Window

    private func getFocusedWindow() -> (element: AXUIElement, currentPos: CGPoint, currentSize: CGSize)? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElem = AXUIElementCreateApplication(frontApp.processIdentifier)
        _ = AXUIElementSetMessagingTimeout(appElem, 0.1)

        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElem, kAXFocusedWindowAttribute as CFString, &focusedRef) != .success {
            var winsRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElem, kAXWindowsAttribute as CFString, &winsRef) == .success,
               let wins = winsRef as? [AXUIElement], let first = wins.first {
                focusedRef = first
            }
        }

        guard let win = focusedRef as! AXUIElement? else { return nil }

        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posRef)
        _ = AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeRef)

        var pos = CGPoint.zero
        var size = CGSize.zero
        if let p = posRef { AXValueGetValue(p as! AXValue, .cgPoint, &pos) }
        if let s = sizeRef { AXValueGetValue(s as! AXValue, .cgSize, &size) }

        return (win, pos, size)
    }

    // MARK: - Apply Frame to Window

    private func applyFrame(to window: AXUIElement, rect: CGRect) {
        var newPos = rect.origin
        var newSize = rect.size

        if let posVal = AXValueCreate(.cgPoint, &newPos),
           let sizeVal = AXValueCreate(.cgSize, &newSize) {
            // macOS Accessibility API requires setting position then size, then re-setting position
            // to ensure windows snap properly regardless of minimum size constraints
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal)
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
        }
    }

    // MARK: - Snap Active Window (Option + Control + Arrow keys)

    public func snapActiveWindow(_ action: SnapAction) {
        guard isSnapEnabled else { return }
        guard let target = getFocusedWindow() else { return }

        let windowCenter = CGPoint(
            x: target.currentPos.x + target.currentSize.width / 2,
            y: target.currentPos.y + target.currentSize.height / 2
        )
        let screen = screenContaining(point: windowCenter)
        let visible = axVisibleFrame(for: screen)

        var newFrame = visible

        switch action {
        case .leftHalf:
            newFrame = CGRect(
                x: visible.origin.x,
                y: visible.origin.y,
                width: floor(visible.width / 2),
                height: visible.height
            )

        case .rightHalf:
            let halfW = floor(visible.width / 2)
            newFrame = CGRect(
                x: visible.origin.x + (visible.width - halfW),
                y: visible.origin.y,
                width: halfW,
                height: visible.height
            )

        case .maximize:
            newFrame = visible

        case .center:
            let w = min(floor(visible.width * 0.78), 1200)
            let h = min(floor(visible.height * 0.82), 850)
            newFrame = CGRect(
                x: visible.origin.x + (visible.width - w) / 2,
                y: visible.origin.y + (visible.height - h) / 2,
                width: w,
                height: h
            )

        case .topHalf:
            newFrame = CGRect(
                x: visible.origin.x,
                y: visible.origin.y,
                width: visible.width,
                height: floor(visible.height / 2)
            )

        case .bottomHalf:
            let halfH = floor(visible.height / 2)
            newFrame = CGRect(
                x: visible.origin.x,
                y: visible.origin.y + (visible.height - halfH),
                width: visible.width,
                height: halfH
            )
        }

        applyFrame(to: target.element, rect: newFrame)
    }

    // MARK: - Move Window to Display (Option + Command + Arrow keys)

    public func moveActiveWindowToDisplay(isNext: Bool) {
        guard isSnapEnabled else { return }
        guard let target = getFocusedWindow() else { return }

        let screens = NSScreen.screens
        guard screens.count > 1 else { return }

        let windowCenter = CGPoint(
            x: target.currentPos.x + target.currentSize.width / 2,
            y: target.currentPos.y + target.currentSize.height / 2
        )
        let currentScreen = screenContaining(point: windowCenter)

        guard let curIndex = screens.firstIndex(of: currentScreen) else { return }
        let targetIndex = isNext
            ? (curIndex + 1) % screens.count
            : (curIndex - 1 + screens.count) % screens.count

        let targetScreen = screens[targetIndex]
        let curVisible = axVisibleFrame(for: currentScreen)
        let targetVisible = axVisibleFrame(for: targetScreen)

        // Calculate relative position and scale
        let relX = (target.currentPos.x - curVisible.origin.x) / curVisible.width
        let relY = (target.currentPos.y - curVisible.origin.y) / curVisible.height
        let relW = target.currentSize.width / curVisible.width
        let relH = target.currentSize.height / curVisible.height

        var newW = min(targetVisible.width * relW, targetVisible.width)
        var newH = min(targetVisible.height * relH, targetVisible.height)

        // If window was nearly full screen or half screen, snap cleanly
        if relW > 0.95 && relH > 0.95 {
            newW = targetVisible.width
            newH = targetVisible.height
        }

        var newX = targetVisible.origin.x + (targetVisible.width * relX)
        var newY = targetVisible.origin.y + (targetVisible.height * relY)

        // Ensure window remains completely inside the new screen visible bounds
        newX = max(targetVisible.origin.x, min(newX, targetVisible.maxX - newW))
        newY = max(targetVisible.origin.y, min(newY, targetVisible.maxY - newH))

        let newFrame = CGRect(x: newX, y: newY, width: newW, height: newH)
        applyFrame(to: target.element, rect: newFrame)
    }
}

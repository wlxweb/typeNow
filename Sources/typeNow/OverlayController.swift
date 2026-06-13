import AppKit
import ApplicationServices

class OverlayController {
    private var panel: NSPanel?
    private var nameLabel: NSTextField?
    private var visualEffect: NSVisualEffectView?
    private var hideTimer: Timer?
    private var currentSize: String?

    func show(inputMethodName: String) {
        hideTimer?.invalidate()

        let size = UserDefaults.standard.string(forKey: "overlaySize") ?? "medium"
        if panel == nil || currentSize != size {
            createWindow(size: size)
            currentSize = size
        }

        nameLabel?.stringValue = inputMethodName
        applyOpacity()
        positionWindow()
        animateIn()

        let duration = UserDefaults.standard.double(forKey: "showDuration")
        let interval = duration > 0 ? duration : 1.5
        hideTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.animateOut()
        }
    }

    // MARK: - Size Presets

    private func sizePreset(_ name: String) -> (width: CGFloat, height: CGFloat, fontSize: CGFloat, radius: CGFloat) {
        switch name {
        case "small":  return (200, 56, 22, 12)
        case "large":  return (320, 100, 34, 20)
        default:       return (260, 80, 28, 16)
        }
    }

    // MARK: - Window Creation

    private func createWindow(size: String) {
        let preset = sizePreset(size)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: preset.width, height: preset.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.animationBehavior = .none
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = true

        let effect = NSVisualEffectView(frame: panel.contentView!.bounds)
        effect.autoresizingMask = [.width, .height]
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = preset.radius
        effect.layer?.masksToBounds = true

        let label = NSTextField(frame: .zero)
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: preset.fontSize, weight: .medium)
        label.textColor = NSColor.labelColor
        label.cell?.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false

        effect.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: effect.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: effect.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: effect.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: effect.trailingAnchor, constant: -16)
        ])

        panel.contentView?.addSubview(effect)
        self.panel = panel
        self.visualEffect = effect
        self.nameLabel = label
    }

    // MARK: - Opacity

    private func applyOpacity() {
        guard let effect = visualEffect else { return }
        let opacity = UserDefaults.standard.double(forKey: "opacity")
        let a = (opacity >= 0.3 && opacity <= 0.9) ? opacity : 0.7
        effect.alphaValue = CGFloat(a)
    }

    // MARK: - Positioning

    private func positionWindow() {
        guard let panel = panel,
              let screen = NSScreen.main else { return }

        let nearCursor = UserDefaults.standard.bool(forKey: "overlayNearCursor")

        if nearCursor {
            positionNearCursor(panel: panel, screen: screen)
        } else if UserDefaults.standard.object(forKey: "overlayOriginX") != nil {
            let x = UserDefaults.standard.double(forKey: "overlayOriginX")
            let y = UserDefaults.standard.double(forKey: "overlayOriginY")
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            let anchor = UserDefaults.standard.string(forKey: "screenAnchor") ?? "center"
            positionAtAnchor(panel: panel, screen: screen, anchor: anchor)
        }
    }

    private func positionAtAnchor(panel: NSWindow, screen: NSScreen, anchor: String) {
        let screenRect = screen.visibleFrame
        let panelSize = panel.frame.size
        let pad: CGFloat = 40

        let x: CGFloat
        let y: CGFloat

        switch anchor {
        case "topLeft":      x = screenRect.minX + pad;                                y = screenRect.maxY - panelSize.height - pad
        case "top":          x = screenRect.midX - panelSize.width / 2;                y = screenRect.maxY - panelSize.height - pad
        case "topRight":     x = screenRect.maxX - panelSize.width - pad;              y = screenRect.maxY - panelSize.height - pad
        case "left":         x = screenRect.minX + pad;                                y = screenRect.midY - panelSize.height / 2
        case "center":       x = screenRect.midX - panelSize.width / 2;                y = screenRect.midY - panelSize.height / 2
        case "right":        x = screenRect.maxX - panelSize.width - pad;              y = screenRect.midY - panelSize.height / 2
        case "bottomLeft":   x = screenRect.minX + pad;                                y = screenRect.minY + pad
        case "bottom":       x = screenRect.midX - panelSize.width / 2;                y = screenRect.minY + pad
        case "bottomRight":  x = screenRect.maxX - panelSize.width - pad;              y = screenRect.minY + pad
        default:             x = screenRect.midX - panelSize.width / 2;                y = screenRect.midY - panelSize.height / 2
        }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func positionNearCursor(panel: NSWindow, screen: NSScreen) {
        if let inputRect = getInputFieldRect() {
            let panelSize = panel.frame.size
            let screenRect = screen.visibleFrame

            var x = inputRect.midX - panelSize.width / 2
            var y = inputRect.minY - panelSize.height - 8

            if y < screenRect.minY {
                y = inputRect.maxY + 8
            }
            x = max(screenRect.minX, min(x, screenRect.maxX - panelSize.width))
            y = max(screenRect.minY, min(y, screenRect.maxY - panelSize.height))

            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            fallbackToMouse(panel: panel, screen: screen)
        }
    }

    private func getInputFieldRect() -> NSRect? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp) == .success,
              let app = focusedApp else { return nil }

        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue((app as! AXUIElement), kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
              let element = focusedElement else { return nil }

        let axElement = element as! AXUIElement

        if let caretRect = getCaretBounds(axElement) {
            return caretRect
        }

        var position: CFTypeRef?
        var size: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axElement, kAXPositionAttribute as CFString, &position) == .success,
              AXUIElementCopyAttributeValue(axElement, kAXSizeAttribute as CFString, &size) == .success else { return nil }

        var point = CGPoint.zero
        var cgSize = CGSize.zero
        AXValueGetValue(position as! AXValue, .cgPoint, &point)
        AXValueGetValue(size as! AXValue, .cgSize, &cgSize)

        return NSRect(x: point.x, y: point.y, width: cgSize.width, height: cgSize.height)
    }

    private func getCaretBounds(_ element: AXUIElement) -> NSRect? {
        var rangeObj: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeObj) == .success,
              let rangeValue = rangeObj else { return nil }

        var range = CFRange(location: 0, length: 0)
        guard AXValueGetValue(rangeValue as! AXValue, .cfRange, &range) else { return nil }

        let queryLen = range.length > 0 ? range.length : 1
        var queryRange = CFRange(location: range.location, length: queryLen)
        let axRange = AXValueCreate(.cfRange, &queryRange)!

        var boundsObj: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element, kAXBoundsForRangeParameterizedAttribute as CFString, axRange, &boundsObj
        ) == .success, let boundsValue = boundsObj else { return nil }

        var rect = CGRect.zero
        guard AXValueGetValue(boundsValue as! AXValue, .cgRect, &rect),
              rect.width > 0, rect.height > 0 else { return nil }

        return rect
    }

    private func fallbackToMouse(panel: NSWindow, screen: NSScreen) {
        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size
        let screenRect = screen.visibleFrame

        var x = mouseLocation.x + 18
        var y = mouseLocation.y - panelSize.height - 18

        if x + panelSize.width > screenRect.maxX {
            x = mouseLocation.x - panelSize.width - 18
        }
        if y < screenRect.minY {
            y = mouseLocation.y + 18
        }
        x = max(screenRect.minX, min(x, screenRect.maxX - panelSize.width))
        y = max(screenRect.minY, min(y, screenRect.maxY - panelSize.height))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Animation

    private func animateIn() {
        guard let panel = panel else { return }
        panel.alphaValue = 0
        panel.orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }
    }

    private func animateOut() {
        guard let panel = panel else { return }

        let nearCursor = UserDefaults.standard.bool(forKey: "overlayNearCursor")
        if !nearCursor {
            let frame = panel.frame
            UserDefaults.standard.set(frame.origin.x, forKey: "overlayOriginX")
            UserDefaults.standard.set(frame.origin.y, forKey: "overlayOriginY")
        }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }
}

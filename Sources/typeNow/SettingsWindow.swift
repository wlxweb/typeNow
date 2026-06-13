import AppKit
import ServiceManagement

class SettingsWindow {
    static let shared = SettingsWindow()

    private let window: NSWindow
    private let durationPopup = NSPopUpButton()
    private let nearCursorCheckbox = NSButton(checkboxWithTitle: "跟随输入框显示", target: nil, action: nil)
    private let sizePopup = NSPopUpButton()
    private let opacitySlider = NSSlider(value: 0.7, minValue: 0.3, maxValue: 0.9, target: nil, action: nil)
    private let opacityLabel = NSTextField(labelWithString: "")
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "开机自启", target: nil, action: nil)
    private let showStatusBarCheckbox = NSButton(checkboxWithTitle: "在菜单栏显示", target: nil, action: nil)
    private let followAppearanceCheckbox = NSButton(checkboxWithTitle: "跟随系统外观", target: nil, action: nil)
    private var positionButtons: [NSButton] = []
    private let focusCheckbox = NSButton(checkboxWithTitle: "聚焦时显示", target: nil, action: nil)
    private let inputChangeCheckbox = NSButton(checkboxWithTitle: "切换输入法时显示", target: nil, action: nil)

    private init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "typeNow 设置"
        window.isReleasedWhenClosed = false
        buildUI()
        loadSettings()
        window.center()
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "showDuration": 1.5,
            "overlayNearCursor": false,
            "overlaySize": "medium",
            "opacity": 0.7,
            "screenAnchor": "center",
            "showOnFocus": true,
            "showOnInputChange": true,
            "launchAtLogin": false,
            "showStatusBar": true,
            "followAppearance": true
        ])
    }

    func show() {
        loadSettings()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - UI Build

    private func buildUI() {
        guard let contentView = window.contentView else { return }

        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 12
        mainStack.alignment = .leading
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        mainStack.addArrangedSubview(makeHeader("显示"))
        mainStack.addArrangedSubview(makeDivider())

        buildDurationPopup()
        mainStack.addArrangedSubview(makeFormRow(label: "显示时长：", control: durationPopup))

        buildSizePopup()
        mainStack.addArrangedSubview(makeFormRow(label: "浮层大小：", control: sizePopup))

        mainStack.addArrangedSubview(makeOpacityRow())

        mainStack.addArrangedSubview(makeSeparator())

        mainStack.addArrangedSubview(makeHeader("位置"))
        mainStack.addArrangedSubview(makeDivider())

        mainStack.addArrangedSubview(makeIndentedRow(buildPositionGrid()))

        nearCursorCheckbox.target = self
        nearCursorCheckbox.action = #selector(checkboxChanged(_:))
        mainStack.addArrangedSubview(makeIndentedRow(nearCursorCheckbox))

        focusCheckbox.target = self
        focusCheckbox.action = #selector(checkboxChanged(_:))
        mainStack.addArrangedSubview(makeIndentedRow(focusCheckbox))

        inputChangeCheckbox.target = self
        inputChangeCheckbox.action = #selector(checkboxChanged(_:))
        mainStack.addArrangedSubview(makeIndentedRow(inputChangeCheckbox))

        mainStack.addArrangedSubview(makeSeparator())

        mainStack.addArrangedSubview(makeHeader("行为"))
        mainStack.addArrangedSubview(makeDivider())

        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(checkboxChanged(_:))
        mainStack.addArrangedSubview(makeIndentedRow(launchAtLoginCheckbox))

        showStatusBarCheckbox.target = self
        showStatusBarCheckbox.action = #selector(checkboxChanged(_:))
        mainStack.addArrangedSubview(makeIndentedRow(showStatusBarCheckbox))

        followAppearanceCheckbox.target = self
        followAppearanceCheckbox.action = #selector(checkboxChanged(_:))
        mainStack.addArrangedSubview(makeIndentedRow(followAppearanceCheckbox))

        mainStack.addArrangedSubview(makeSeparator())

        let resetButton = NSButton(title: "还原浮层位置", target: self, action: #selector(resetPosition))
        mainStack.addArrangedSubview(makeIndentedRow(resetButton))

        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func makeHeader(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func makeDivider() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        return box
    }

    private func makeSeparator() -> NSView {
        NSView(frame: NSRect(x: 0, y: 0, width: 0, height: 4))
    }

    private func makeFormRow(label: String, control: NSView) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY

        let labelView = NSTextField(labelWithString: label)
        labelView.alignment = .right
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.widthAnchor.constraint(equalToConstant: 120).isActive = true

        row.addArrangedSubview(labelView)
        row.addArrangedSubview(control)
        return row
    }

    private func makeIndentedRow(_ view: NSView) -> NSView {
        let container = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 128),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        return container
    }

    private func makeOpacityRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY

        let labelView = NSTextField(labelWithString: "透明度：")
        labelView.alignment = .right
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.widthAnchor.constraint(equalToConstant: 120).isActive = true

        opacitySlider.target = self
        opacitySlider.action = #selector(sliderChanged(_:))
        opacitySlider.translatesAutoresizingMaskIntoConstraints = false
        opacitySlider.widthAnchor.constraint(equalToConstant: 160).isActive = true

        opacityLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        opacityLabel.alignment = .left
        opacityLabel.translatesAutoresizingMaskIntoConstraints = false
        opacityLabel.widthAnchor.constraint(equalToConstant: 36).isActive = true

        row.addArrangedSubview(labelView)
        row.addArrangedSubview(opacitySlider)
        row.addArrangedSubview(opacityLabel)
        return row
    }

    // MARK: - Popup Builders

    private func buildDurationPopup() {
        durationPopup.removeAllItems()
        let values: [(String, Double)] = [("0.5s", 0.5), ("1.0s", 1.0), ("1.5s", 1.5), ("2.0s", 2.0), ("3.0s", 3.0)]
        for (title, _) in values {
            durationPopup.addItem(withTitle: title)
        }
        durationPopup.target = self
        durationPopup.action = #selector(durationChanged(_:))
    }

    private func buildSizePopup() {
        sizePopup.removeAllItems()
        sizePopup.addItem(withTitle: "小")
        sizePopup.addItem(withTitle: "中")
        sizePopup.addItem(withTitle: "大")
        sizePopup.target = self
        sizePopup.action = #selector(sizeChanged(_:))
    }

    // MARK: - Position Grid

    private func buildPositionGrid() -> NSView {
        let container = NSView()

        let definitions: [(String, String)] = [
            ("topLeft", "↖"), ("top", "↑"), ("topRight", "↗"),
            ("left", "←"), ("center", "·"), ("right", "→"),
            ("bottomLeft", "↙"), ("bottom", "↓"), ("bottomRight", "↘")
        ]

        var buttons: [NSButton] = []
        for (key, symbol) in definitions {
            let btn = NSButton(title: symbol, target: self, action: #selector(positionButtonClicked(_:)))
            btn.bezelStyle = .regularSquare
            btn.identifier = NSUserInterfaceItemIdentifier(key)
            btn.font = NSFont.systemFont(ofSize: 16)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 40).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
            buttons.append(btn)
        }

        let grid = NSGridView(views: [
            [buttons[0], buttons[1], buttons[2]],
            [buttons[3], buttons[4], buttons[5]],
            [buttons[6], buttons[7], buttons[8]]
        ])
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 2
        grid.columnSpacing = 2

        container.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: container.topAnchor),
            grid.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            grid.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])

        positionButtons = buttons
        return container
    }

    @objc private func positionButtonClicked(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(key, forKey: "screenAnchor")
        UserDefaults.standard.removeObject(forKey: "overlayOriginX")
        UserDefaults.standard.removeObject(forKey: "overlayOriginY")
        updatePositionButtonStates()
        postSettingsChanged()
    }

    private func updatePositionButtonStates() {
        let selected = UserDefaults.standard.string(forKey: "screenAnchor") ?? "center"
        for btn in positionButtons {
            let isSelected = btn.identifier?.rawValue == selected
            btn.state = isSelected ? .on : .off
            if isSelected {
                btn.bezelColor = .controlAccentColor
            } else {
                btn.bezelColor = nil
            }
        }
    }

    private func updatePositionGridEnabled() {
        let following = nearCursorCheckbox.state == .on
        for btn in positionButtons {
            btn.isEnabled = !following
            btn.alphaValue = following ? 0.35 : 1.0
        }
    }

    // MARK: - Load / Save

    private func loadSettings() {
        let duration = UserDefaults.standard.double(forKey: "showDuration")
        let values: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]
        if let idx = values.firstIndex(of: duration) {
            durationPopup.selectItem(at: idx)
        }

        let size = UserDefaults.standard.string(forKey: "overlaySize") ?? "medium"
        let sizeMap = ["small": 0, "medium": 1, "large": 2]
        sizePopup.selectItem(at: sizeMap[size] ?? 1)

        let opacity = UserDefaults.standard.double(forKey: "opacity")
        let displayOpacity = opacity == 0 ? 0.7 : opacity
        opacitySlider.doubleValue = displayOpacity
        opacityLabel.stringValue = "\(Int(displayOpacity * 100))%"

        launchAtLoginCheckbox.state = UserDefaults.standard.bool(forKey: "launchAtLogin") ? .on : .off
        nearCursorCheckbox.state = UserDefaults.standard.bool(forKey: "overlayNearCursor") ? .on : .off
        focusCheckbox.state = UserDefaults.standard.bool(forKey: "showOnFocus") ? .on : .off
        inputChangeCheckbox.state = UserDefaults.standard.bool(forKey: "showOnInputChange") ? .on : .off
        showStatusBarCheckbox.state = UserDefaults.standard.bool(forKey: "showStatusBar") ? .on : .off
        followAppearanceCheckbox.state = UserDefaults.standard.bool(forKey: "followAppearance") ? .on : .off

        updatePositionButtonStates()
        updatePositionGridEnabled()
    }

    // MARK: - Actions

    @objc private func durationChanged(_ sender: NSPopUpButton) {
        let values: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]
        let value = values[sender.indexOfSelectedItem]
        UserDefaults.standard.set(value, forKey: "showDuration")
        postSettingsChanged()
    }

    @objc private func checkboxChanged(_ sender: NSButton) {
        let isOn = sender.state == .on
        switch sender {
        case launchAtLoginCheckbox:
            UserDefaults.standard.set(isOn, forKey: "launchAtLogin")
            setLaunchAtLogin(isOn)
        case nearCursorCheckbox:
            UserDefaults.standard.set(isOn, forKey: "overlayNearCursor")
            updatePositionGridEnabled()
            postSettingsChanged()
        case focusCheckbox:
            UserDefaults.standard.set(isOn, forKey: "showOnFocus")
            postSettingsChanged()
        case inputChangeCheckbox:
            UserDefaults.standard.set(isOn, forKey: "showOnInputChange")
            postSettingsChanged()
        case showStatusBarCheckbox:
            UserDefaults.standard.set(isOn, forKey: "showStatusBar")
            postSettingsChanged()
        case followAppearanceCheckbox:
            UserDefaults.standard.set(isOn, forKey: "followAppearance")
            postSettingsChanged()
        default:
            break
        }
    }

    @objc private func sizeChanged(_ sender: NSPopUpButton) {
        let values = ["small", "medium", "large"]
        let value = values[sender.indexOfSelectedItem]
        UserDefaults.standard.set(value, forKey: "overlaySize")
        postSettingsChanged()
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        let value = round(sender.doubleValue * 100) / 100
        opacityLabel.stringValue = "\(Int(value * 100))%"
        UserDefaults.standard.set(value, forKey: "opacity")
        postSettingsChanged()
    }

    @objc private func resetPosition() {
        UserDefaults.standard.removeObject(forKey: "overlayOriginX")
        UserDefaults.standard.removeObject(forKey: "overlayOriginY")
        UserDefaults.standard.set("center", forKey: "screenAnchor")
        UserDefaults.standard.set(false, forKey: "overlayNearCursor")
        nearCursorCheckbox.state = .off
        updatePositionButtonStates()
        postSettingsChanged()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Launch at login error: \(error)")
            }
        }
    }

    private func postSettingsChanged() {
        NotificationCenter.default.post(name: .typeNowSettingsChanged, object: nil)
    }
}

extension Notification.Name {
    static let typeNowSettingsChanged = Notification.Name("typeNowSettingsChanged")
}

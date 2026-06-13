import AppKit

class StatusBarManager {
    private var statusItem: NSStatusItem?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "EN"
            button.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        }

        let menu = NSMenu()
        let prefsItem = NSMenuItem(title: "偏好设置...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "退出 typeNow", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu

        applyVisibility()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .typeNowSettingsChanged,
            object: nil
        )
    }

    func update(abbreviation: String) {
        statusItem?.button?.title = abbreviation
    }

    @objc private func openPreferences() {
        SettingsWindow.shared.show()
    }

    @objc private func settingsChanged() {
        applyVisibility()
    }

    private func applyVisibility() {
        let visible = UserDefaults.standard.bool(forKey: "showStatusBar")
        statusItem?.isVisible = visible
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}

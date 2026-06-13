import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = InputMonitor()
    private lazy var overlayController = OverlayController()
    private lazy var statusBarManager = StatusBarManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        SettingsWindow.registerDefaults()
        monitor.delegate = self
        monitor.start()
        statusBarManager.setup()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeAppChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func activeAppChanged(_ notification: Notification) {
        guard UserDefaults.standard.bool(forKey: "showOnFocus") else { return }
        guard let userInfo = notification.userInfo,
              let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
        let name = monitor.currentInputMethodName()
        let abbr = monitor.currentInputMethodAbbreviation()
        overlayController.show(inputMethodName: name)
        statusBarManager.update(abbreviation: abbr)
    }
}

extension AppDelegate: InputMonitorDelegate {
    func inputMonitor(_ monitor: InputMonitor, didChangeTo name: String, abbreviation: String) {
        if UserDefaults.standard.bool(forKey: "showOnInputChange") {
            overlayController.show(inputMethodName: name)
        }
        statusBarManager.update(abbreviation: abbreviation)
    }
}

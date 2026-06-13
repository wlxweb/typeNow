import Carbon
import Foundation

protocol InputMonitorDelegate: AnyObject {
    func inputMonitor(_ monitor: InputMonitor, didChangeTo inputMethodName: String, abbreviation: String)
}

class InputMonitor {
    weak var delegate: InputMonitorDelegate?

    private var previousName: String?

    func currentInputMethodName() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return "Unknown"
        }
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else {
            return "Unknown"
        }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    func start() {
        let notificationName = kTISNotifySelectedKeyboardInputSourceChanged as String
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleInputSourceChange(_:)),
            name: NSNotification.Name(notificationName),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        previousName = currentInputMethodName()
    }

    func stop() {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func currentInputMethodAbbreviation() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return "?"
        }
        guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
              let sourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String? else {
            return "?"
        }

        if sourceID.contains(".SCIM.") || sourceID.contains("Pinyin")
            || sourceID.contains("Shuangpin") || sourceID.contains("Wubi")
            || sourceID.contains("Cangjie") || sourceID.contains("Zhuyin") {
            return "中"
        }
        if sourceID.contains("Kotoeri") || sourceID.contains("Hiragana")
            || sourceID.contains("Katakana") || sourceID.contains(".Japanese") {
            return "あ"
        }
        if sourceID.contains("Korean") || sourceID.contains("Hangul") {
            return "한"
        }
        return "EN"
    }

    @objc private func handleInputSourceChange(_ notification: Notification) {
        let currentName = currentInputMethodName()
        guard currentName != previousName else { return }
        previousName = currentName
        let abbr = currentInputMethodAbbreviation()
        delegate?.inputMonitor(self, didChangeTo: currentName, abbreviation: abbr)
    }
}

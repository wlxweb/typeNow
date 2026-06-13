# typeNow 实现方案

## 目标

解决 macOS 自动切换输入法（常切换到 ABC）后用户不知情的问题。当输入法状态发生变化时，屏幕中央弹出半透明浮层，短暂显示当前输入法名称，用户一目了然。

## 技术选型

| 选项 | 说明 |
|------|------|
| 语言 | Swift 5+ |
| 框架 | AppKit + Carbon |
| 最低系统 | macOS 13 (Ventura) |
| 打包格式 | .app (可设为登录自启) |

## 核心实现路径

### 1. 监听输入法切换

macOS 通过分布式通知中心广播输入法切换事件：

```swift
// 通知名称
NSNotification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged")
```

监听方式：

```swift
DistributedNotificationCenter.default()
    .addObserver(self,
                 selector: #selector(inputSourceChanged),
                 name: NSNotification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"),
                 object: nil)
```

### 2. 获取当前输入法名称

通过 Carbon 的 `TISCopyCurrentKeyboardInputSource()` 获取，或使用 Swift 封装的 `TISInputSource`：

```swift
import Carbon

func currentInputMethodName() -> String {
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
        return "Unknown"
    }
    guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else {
        return "Unknown"
    }
    return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
}
```

### 3. 浮层展示

- 使用 `NSPanel`（`nonactivating` 风格），不抢焦点
- 窗口层级设为 `.floating`，悬浮于所有窗口之上
- 圆角半透明背景 + 大号字体 + 自动居中对齐

```swift
class OverlayWindow: NSPanel {
    init() {
        super.init(contentRect: .zero,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.7)
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
    }
}
```

### 4. 显示/消失动画

- 出现：0.15s 淡入 + 微放大
- 停留：1.5s
- 消失：0.15s 淡出

```swift
// 显示
NSAnimationContext.runAnimationGroup { ctx in
    ctx.duration = 0.15
    overlay.animator().alphaValue = 1.0
}

// 延时后消失
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
    NSAnimationContext.runAnimationGroup { ctx in
        ctx.duration = 0.15
        overlay.animator().alphaValue = 0.0
    } completionHandler: {
        overlay.orderOut(nil)
    }
}
```

### 5. 状态栏图标

- 可选，通过 `NSStatusBar` 添加一个小图标
- 右键菜单：偏好设置 / 退出
- 图标实时显示当前输入法缩写（中/EN）

## 文件结构

```
typeNow/
├── typeNow.xcodeproj
├── Sources/
│   ├── main.swift              # 入口
│   ├── AppDelegate.swift        # 应用委托
│   ├── InputMonitor.swift       # 输入法监听
│   ├── OverlayWindow.swift      # 浮层窗口
│   └── StatusBarController.swift # 状态栏
├── Resources/
│   ├── Assets.xcassets          # 图标资源
│   └── Info.plist
└── doc/
    ├── implementation-plan.md
    ├── requirements.md
    └── architecture.md
```

## 构建与运行

```bash
# 开发
open typeNow.xcodeproj

# 命令行编译
xcodebuild -project typeNow.xcodeproj -scheme typeNow -configuration Release
```

## 关键风险

| 风险 | 应对 |
|------|------|
| 分布式通知可能被系统限制 | 降级方案：0.3s 轮询 `TISCopyCurrentKeyboardInputSource()` |
| 浮层在多显示器间错位 | 使用 `NSScreen.main` 定位到当前活跃屏幕 |
| App Store 审核 | 作为非商店分发工具，无需审核 |

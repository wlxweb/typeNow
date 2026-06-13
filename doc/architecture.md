# typeNow 技术架构建议

## 架构概览

```
┌─────────────────────────────────────────────┐
│                  typeNow.app                 │
├─────────────────────────────────────────────┤
│  AppDelegate                                 │
│    │                                         │
│    ├── InputMonitor (监听层)                  │
│    │   ├── NotificationObserver              │
│    │   └── PollingFallback (降级备用)         │
│    │                                         │
│    ├── OverlayController (展示层)             │
│    │   ├── OverlayWindow (NSPanel)            │
│    │   ├── AnimationEngine (动画引擎)          │
│    │   └── ScreenLayout (多屏适配)             │
│    │                                         │
│    ├── StatusBarController (状态栏)            │
│    │   ├── NSStatusItem                       │
│    │   └── MenuBuilder (右键菜单)              │
│    │                                         │
│    └── Settings (配置)                         │
│        ├── UserDefaults                       │
│        └── LaunchAtLogin (登录自启)            │
└─────────────────────────────────────────────┘
```

## 模块职责

### 1. InputMonitor — 输入法监听

**职责**：感知输入法变化，输出当前输入法名称。

**两种策略**：

| 策略 | 实现 | 优点 | 缺点 |
|------|------|------|------|
| 通知驱动 | 监听 `DistributedNotificationCenter` 的 `TISNotifySelectedKeyboardInputSourceChanged` | 实时、省资源 | 极少数场景可能丢通知 |
| 轮询兜底 | 0.5s 间隔用 `TISCopyCurrentKeyboardInputSource()` 比对 | 绝不漏检 | 额外 CPU 开销 |

**推荐实现**：通知为主，轮询为辅。检测到通知超过 2s 未收到时自动切换到轮询模式。

```swift
protocol InputMonitorDelegate: AnyObject {
    func inputMonitor(_ monitor: InputMonitor, didChangeTo name: String)
}

class InputMonitor {
    weak var delegate: InputMonitorDelegate?
    private var currentName: String?
    private var lastNotificationTime: Date?
    private var pollingTimer: Timer?

    func start() { /* 注册通知 + 启动兜底轮询 */ }
    func stop()  { /* 移除通知 + 停止轮询 */ }
}
```

### 2. OverlayController — 浮层展示

**职责**：接收输入法名称，创建并管理浮层窗口的生命周期。

**关键设计决策**：

- **窗口类型**：`NSPanel` + `nonactivatingPanel` 风格 → 不激活应用、不抢焦点
- **窗口层级**：`NSWindow.Level.floating` → 悬浮于普通窗口之上，低于屏保/模态弹窗
- **跨空间**：`.canJoinAllSpaces` — 用户切换桌面空间时浮层跟随显示

**动画时序**：

```
通知到达
    │
    ├── 0.0s: 创建/复用 NSPanel，设置文字，alpha = 0
    ├── 0.0s: 定位到屏幕中央
    ├── 0.15s: alpha → 1.0 (淡入)
    ├── 1.5s: 等待，用户阅读
    ├── 1.65s: alpha → 0.0 (淡出)
    └── 1.8s: orderOut，窗口隐藏
```

**复用策略**：始终维护一个 `OverlayWindow` 实例，避免频繁创建销毁窗口。新通知到达时：
- 如果窗口正在显示 → 立即用当前 alpha 状态平滑过渡到新文字并重置定时器
- 如果窗口已隐藏 → 走完整显示流程

### 3. StatusBarController — 状态栏

**职责**：提供用户交互入口（设置、退出）。

**行为**：
- 默认显示（用户可在设置中隐藏）
- 左键点击：手动触发一次显示（用于确认当前状态）
- 右键点击：菜单 [⚙ Preferences / Quit typeNow]

### 4. Settings — 配置管理

**存储方式**：`UserDefaults` 或 `@AppStorage`

**键值清单**：

| Key | 类型 | 默认值 | 说明 |
|-----|------|--------|------|
| `showDuration` | Double | 1.5 | 浮层显示秒数 |
| `overlayPosition` | String | "center" | center / cursor / custom |
| `overlaySize` | String | "medium" | small / medium / large |
| `opacity` | Double | 0.7 | 背景透明度 |
| `launchAtLogin` | Bool | false | 是否开机自启 |
| `showStatusBar` | Bool | true | 是否显示状态栏图标 |
| `followAppearance` | Bool | true | 是否跟随系统暗色模式 |

## 数据流

```
系统输入法切换
       │
       ▼
DistributedNotificationCenter
       │
       ▼
InputMonitor.handleNotification()
       │
       ├── 获取当前输入法名称
       │
       ▼
delegate.inputMonitor(_:didChangeTo:)
       │
       ▼
OverlayController.show(inputMethodName:)
       │
       ├── 取消上一次的定时器
       ├── 更新 OverlayWindow 文字
       ├── 执行淡入动画
       └── 设置自动淡出定时器
```

## 关键技术考虑

### 多显示器

使用 `NSApplication.shared.keyWindow?.screen ?? NSScreen.main` 定位到当前活跃屏幕，确保浮层出现在用户正在看的那块屏幕上。

### 性能

- `TISCopyCurrentKeyboardInputSource()` 调用开销极小（< 1ms），无需缓存
- 窗口绘制采用 Core Animation 层，GPU 加速
- 空闲时应用处于休眠状态，无 timer、无轮询

### 安全与权限

- 不需要辅助功能权限（Accessibility）
- 不需要屏幕录制权限
- 不需要网络权限
- 仅需：正常运行即可

### 分发方式

| 方式 | 说明 |
|------|------|
| GitHub Release | 打包 .app 放入 .dmg，免费分发 |
| Homebrew Cask | 提交到 homebrew-cask，用户 brew install 安装 |
| 自建 Sparkle 更新 | 集成 Sparkle 框架实现自动更新检测 |

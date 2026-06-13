# typeNow

输入法状态实时提示工具。切换输入法时，屏幕弹出半透明浮层，显示当前输入法名称，让你一目了然。

## 为什么做这个

macOS 在使用第三方输入法（如搜狗、鼠须管等）时，经常悄无声息地自动切回 ABC 输入法。等你打完一串英文才发现——刚才的输入全白打了。typeNow 在每次输入法变化时弹出一个短暂浮层，让你立刻知道当前是什么输入法，再也不用来回盯着菜单栏确认。

## 功能

- 监听 macOS 输入法切换，实时弹出浮层提示
- 浮层自动淡入淡出，1.5 秒后消失，不抢焦点
- 状态栏显示当前输入法缩写：`中` / `EN` / `あ` / `한`
- 支持拖动浮层，自动记忆位置
- 可跟随输入框位置显示（基于 Accessibility API）
- 切换应用时自动提示当前输入法
- 完整的偏好设置面板

## 系统要求

- macOS 13 (Ventura) 或更高版本
- Intel / Apple Silicon

## 安装

```bash
cd typeNow
make app
```

将生成的 `typeNow.app` 拖入 `/Applications` 即可。

## 辅助功能授权

若启用「跟随输入框显示」，需在 **系统设置 → 隐私与安全性 → 辅助功能** 中添加 `typeNow.app`。未授权时自动降级为鼠标定位。

## 开发

```bash
# 运行
make run

# 编译
make build

# 打包 .app
make app

# 清理
make clean
```

## 项目结构

```
typeNow/
├── Sources/typeNow/
│   ├── main.swift              # 入口
│   ├── AppDelegate.swift       # 应用委托，组装模块
│   ├── InputMonitor.swift      # 输入法监听（分布式通知）
│   ├── OverlayController.swift # 浮层控制（NSPanel + 动画）
│   ├── SettingsWindow.swift    # 偏好设置窗口
│   └── StatusBarManager.swift  # 状态栏管理
├── Resources/
│   └── Info.plist
├── Package.swift
├── Makefile
└── README.md
```

## 设置项

| 设置 | 说明 | 默认值 |
|------|------|--------|
| 显示时长 | 浮层停留时间 | 1.5s |
| 浮层大小 | 小 / 中 / 大 | 中 |
| 透明度 | 30% ~ 90% | 70% |
| 九宫格位置 | 屏幕九个锚点任选 | 居中 |
| 跟随输入框显示 | 通过辅助功能定位输入框 | 关 |
| 聚焦时显示 | 切换应用时弹出提示 | 开 |
| 开机自启 | 登录时自动启动 | 关 |
| 在菜单栏显示 | 状态栏图标显隐 | 开 |
| 跟随系统外观 | 适配暗色/亮色模式 | 开 |

## 技术栈

- Swift 5.9+
- AppKit + Carbon + ApplicationServices
- 分布式通知中心 + 辅助功能 API

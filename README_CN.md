# Transly

一款原生 macOS 菜单栏翻译应用，使用 SwiftUI 构建。

## 功能特性

### 四种翻译模式

| 模式 | 快捷键 | 说明 |
|------|--------|------|
| 输入翻译 | `⌥A` | 手动输入文本进行翻译 |
| 划词翻译 | `⌥D` | 选中文字后自动翻译 |
| 截图翻译 (OCR) | `⌥S` | 截取屏幕区域并识别文字翻译 |
| 剪贴翻译 | `⌥V` | 翻译剪贴板中的内容 |

### 核心特性

- **多翻译服务支持** - 可同时使用多个翻译服务并对比结果
- **OCR 文字识别** - 使用 Apple Vision 框架识别屏幕文字
- **翻译历史记录** - 保存翻译历史，方便查阅
- **自动语言检测** - 支持自动检测源语言
- **窗口置顶** - 翻译窗口可置顶显示
- **自动复制** - 翻译结果可自动复制到剪贴板

### 支持的翻译服务

| 服务 | 特点 | 配置要求 |
|------|------|----------|
| Google 翻译 | 免费，无需 API Key | 无 |
| Apple 翻译 | 系统原生，离线可用 (macOS 15+) | 需下载语言包 |
| DeepSeek | 高质量 AI 翻译 | API Key |
| OpenAI | 强大语言理解，支持自定义端点 | API Key + 端点 + 模型 |
| Ollama | 完全本地运行，隐私安全 | 端点 + 模型 |

### 支持的语言

自动检测、中文、英语、日语、韩语、法语、德语、西班牙语、俄语、葡萄牙语、意大利语

## 系统要求

- macOS 14.0 或更高版本
- Xcode 16+（从源码构建）

## 安装方式

### 下载发布版本

从 [Releases](../../releases) 下载最新 DMG 安装包。

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/icuxika/Transly.git
cd Transly

# 安装 Tuist（如未安装）
brew install tuist

# 生成 Xcode 项目
tuist generate

# 构建发布版本
./build-release.sh

# 构建并安装到 /Applications
./build-release.sh --install
```

### 创建 DMG 安装包

```bash
# 使用 hdiutil（系统内置）
./package.sh

# 使用 create-dmg（需先执行：brew install create-dmg）
./package-dmg.sh
```

## 权限说明

Transly 需要以下系统权限：

1. **辅助功能权限** - 用于划词翻译功能，获取选中的文本
2. **屏幕录制权限** - 用于 OCR 翻译功能，捕获屏幕内容

请在 **系统设置 → 隐私与安全性** 中授权。

## 技术栈

- **开发语言**: Swift 6.0
- **UI 框架**: SwiftUI + AppKit
- **构建工具**: [Tuist](https://tuist.io/)
- **无第三方依赖** - 纯原生框架实现

### 系统框架

- `Vision` - OCR 文字识别
- `NaturalLanguage` - 语言检测
- `Translation` - Apple 系统翻译 (macOS 15+)
- `Carbon` - 全局快捷键注册

## 项目结构

```
Transly/
├── Transly/
│   ├── Resources/
│   │   └── Assets.xcassets/
│   └── Sources/
│       ├── Core/                    # 核心功能
│       │   ├── OCR/                 # OCR 服务和截图捕获
│       │   ├── Selection/           # 文字选择服务
│       │   └── HotkeyManager.swift  # 全局快捷键管理
│       ├── Models/                  # 数据模型
│       ├── Services/                # 服务层
│       │   └── Providers/           # 翻译服务提供者
│       ├── UI/                      # 用户界面
│       │   ├── Components/
│       │   └── Views/
│       ├── ViewModels/              # 视图模型
│       └── TranslyApp.swift         # 应用入口
├── Project.swift                    # Tuist 项目配置
├── build-release.sh                 # 发布构建脚本
├── package.sh                       # DMG 打包脚本 (hdiutil)
└── package-dmg.sh                   # DMG 打包脚本 (create-dmg)
```

## 许可证

MIT License

## 贡献

欢迎提交 Pull Request！

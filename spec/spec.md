# Transly - 划词翻译软件规范文档

## 项目概述

Transly 是一款 macOS 原生划词翻译软件，使用 SwiftUI 开发，专注于轻量、快速、高效的翻译体验。

### 核心特性

1. **手动输入翻译** - 用户手动输入文本进行翻译
2. **划词翻译** - 选中文本自动触发翻译
3. **OCR翻译** - 截图识别文字并翻译

### 技术要求

- **轻量**: 应用体积小，内存占用低
- **快速**: 启动快，响应快，翻译快
- **原生**: 纯 SwiftUI + Swift 并发，无重型依赖

---

## 系统架构

### 模块划分

```
Transly/
├── App/                    # 应用入口
│   ├── TranslyApp.swift
│   └── AppDelegate.swift
├── Core/                   # 核心业务
│   ├── Translation/        # 翻译服务
│   ├── Selection/          # 划词监听
│   └── OCR/               # OCR识别
├── UI/                     # 用户界面
│   ├── Views/             # 视图组件
│   ├── ViewModels/        # 视图模型
│   └── Components/        # 可复用组件
├── Models/                 # 数据模型
├── Services/               # 服务层
├── Utils/                  # 工具类
└── Resources/              # 资源文件
```

### 依赖选择

| 功能 | 依赖 | 原因 |
|------|------|------|
| 网络请求 | 原生 URLSession | 轻量，无第三方依赖 |
| JSON解析 | 原生 Codable | Swift 原生支持 |
| OCR | Vision Framework | Apple 原生，免费 |
| 划词监听 | Accessibility API | 系统原生支持 |
| 存储 | UserDefaults | 轻量配置存储 |

---

## 开发阶段

### 阶段一：基础框架与手动翻译

**目标**: 搭建应用骨架，实现手动输入翻译功能

**功能点**:
- 应用基础架构搭建
- 翻译API服务集成（使用免费翻译API）
- 手动输入翻译界面
- 翻译历史记录
- 基本设置（源语言/目标语言选择）

**技术要点**:
- SwiftUI MVVM 架构
- Swift Concurrency (async/await)
- 原生 URLSession 网络请求
- 翻译API: 使用 MyMemory 免费API 或 LibreTranslate

---

### 阶段二：划词翻译

**目标**: 实现选中文本自动翻译

**功能点**:
- 全局划词监听（Accessibility API）
- 悬浮翻译窗口
- 快捷键触发翻译
- 翻译结果自动复制

**技术要点**:
- AXUIElement API 监听选择变化
- NSPanel 创建悬浮窗口
- 全局快捷键（KeyboardShortcuts 或原生）
- 权限申请（辅助功能权限）

---

### 阶段三：OCR翻译

**目标**: 实现截图识别翻译

**功能点**:
- 截图功能
- Vision OCR 文字识别
- 识别结果翻译
- 图片预览与文字高亮

**技术要点**:
- ScreenCaptureKit 截图
- Vision Framework OCR
- 图片文字区域定位
- CGWindow 渲染

---

### 阶段四：优化与完善

**目标**: 性能优化与用户体验提升

**功能点**:
- 启动优化
- 内存优化
- 翻译缓存
- 离线词典支持（可选）
- 多翻译源切换
- 用户偏好设置完善

---

## 翻译API方案

### 主选方案: MyMemory API

- **免费额度**: 每天10000字符
- **无需注册**: 基础使用无需API Key
- **支持语言**: 200+ 语言对
- **API格式**: RESTful

```
GET https://api.mymemory.translated.net/get?q=Hello&langpair=en|zh
```

### 备选方案

1. **LibreTranslate** - 开源自托管
2. **DeepL Free** - 高质量但有限制
3. **Google Translate** - 需要API Key

---

## UI/UX 设计原则

### 窗口设计

- **主窗口**: 紧凑、简洁
- **悬浮窗口**: 毛玻璃效果、圆角、阴影
- **状态栏图标**: 快速访问入口

### 交互设计

- **划词即译**: 选中文本后自动弹出翻译
- **快捷操作**: Cmd+Shift+T 唤起主窗口
- **拖拽支持**: 拖拽文本到窗口翻译

### 视觉风格

- **系统原生**: 遵循 macOS Human Interface Guidelines
- **暗色模式**: 完整支持
- **动画**: 轻量、流畅

---

## 性能指标

| 指标 | 目标值 |
|------|--------|
| 应用体积 | < 5MB |
| 冷启动时间 | < 1秒 |
| 内存占用 | < 50MB (空闲) |
| 翻译响应时间 | < 2秒 |
| OCR识别时间 | < 1秒 |

---

## 权限需求

| 权限 | 用途 | 阶段 |
|------|------|------|
| 网络访问 | 翻译API请求 | 阶段一 |
| 辅助功能 | 划词监听 | 阶段二 |
| 屏幕录制 | 截图OCR | 阶段三 |

---

## 文件结构规划

```
Transly/
├── Sources/
│   ├── App/
│   │   ├── TranslyApp.swift
│   │   └── AppDelegate.swift
│   ├── Core/
│   │   ├── Translation/
│   │   │   ├── TranslationService.swift
│   │   │   ├── TranslationProvider.swift
│   │   │   └── Models/
│   │   │       ├── TranslationRequest.swift
│   │   │       └── TranslationResponse.swift
│   │   ├── Selection/
│   │   │   ├── SelectionMonitor.swift
│   │   │   └── SelectionManager.swift
│   │   └── OCR/
│   │       ├── OCRService.swift
│   │       └── ScreenshotCapture.swift
│   ├── UI/
│   │   ├── Views/
│   │   │   ├── MainView.swift
│   │   │   ├── TranslationView.swift
│   │   │   ├── HistoryView.swift
│   │   │   └── SettingsView.swift
│   │   ├── ViewModels/
│   │   │   ├── TranslationViewModel.swift
│   │   │   └── HistoryViewModel.swift
│   │   └── Components/
│   │       ├── LanguagePicker.swift
│   │       ├── TranslationResult.swift
│   │       └── FloatingPanel.swift
│   ├── Models/
│   │   ├── Language.swift
│   │   ├── TranslationHistory.swift
│   │   └── AppSettings.swift
│   ├── Services/
│   │   ├── NetworkService.swift
│   │   ├── StorageService.swift
│   │   └── ClipboardService.swift
│   └── Utils/
│       ├── Extensions/
│       └── Helpers/
└── Resources/
    └── Assets.xcassets/
```

---

## Git Commit 规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/) 标准：

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Type 类型

- `feat`: 新功能
- `fix`: Bug修复
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具相关

### Scope 范围

- `core`: 核心功能
- `ui`: 用户界面
- `translation`: 翻译服务
- `selection`: 划词功能
- `ocr`: OCR功能
- `build`: 构建配置

### 示例

```
feat(translation): add MyMemory API integration

- Implement TranslationService with async/await
- Add error handling for network failures
- Support language pair configuration

Closes #1
```

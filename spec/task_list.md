# Transly 开发任务列表

## 阶段一：基础框架与手动翻译

### 1.1 项目结构重构
- [ ] 创建模块化目录结构
- [ ] 配置 Tuist 依赖和项目设置
- [ ] 添加必要的权限配置

### 1.2 核心模型
- [ ] 创建 Language 语言模型
- [ ] 创建 TranslationRequest/TranslationResponse 模型
- [ ] 创建 TranslationHistory 历史记录模型
- [ ] 创建 AppSettings 设置模型

### 1.3 网络服务
- [ ] 实现 NetworkService 基础网络层
- [ ] 实现 TranslationService 翻译服务
- [ ] 集成 MyMemory API
- [ ] 添加错误处理和重试机制

### 1.4 存储服务
- [ ] 实现 StorageService 配置存储
- [ ] 实现历史记录持久化

### 1.5 UI界面
- [ ] 创建 MainView 主界面
- [ ] 创建 TranslationView 翻译界面
- [ ] 创建 HistoryView 历史记录界面
- [ ] 创建 SettingsView 设置界面
- [ ] 创建 LanguagePicker 语言选择组件
- [ ] 创建 TranslationResult 翻译结果组件

### 1.6 ViewModel
- [ ] 实现 TranslationViewModel
- [ ] 实现 HistoryViewModel

### 1.7 测试与提交
- [ ] 编写单元测试
- [ ] 功能验证测试
- [ ] Git commit: `feat(core): implement basic translation framework`

---

## 阶段二：划词翻译

### 2.1 划词监听
- [ ] 实现 SelectionMonitor 选择监听
- [ ] 实现 SelectionManager 选择管理
- [ ] 添加辅助功能权限检查和引导

### 2.2 悬浮窗口
- [ ] 创建 FloatingPanel 悬浮面板组件
- [ ] 实现 NSPanel 配置
- [ ] 实现窗口位置智能定位

### 2.3 快捷键
- [ ] 实现全局快捷键监听
- [ ] 添加快捷键设置

### 2.4 剪贴板
- [ ] 实现 ClipboardService 剪贴板服务
- [ ] 添加自动复制翻译结果功能

### 2.5 测试与提交
- [ ] 划词功能测试
- [ ] 权限流程测试
- [ ] Git commit: `feat(selection): implement word selection translation`

---

## 阶段三：OCR翻译

### 3.1 截图功能
- [ ] 实现 ScreenshotCapture 截图服务
- [ ] 添加屏幕录制权限检查
- [ ] 实现截图区域选择

### 3.2 OCR识别
- [ ] 实现 OCRService 文字识别
- [ ] 集成 Vision Framework
- [ ] 实现多语言OCR

### 3.3 OCR翻译
- [ ] 实现OCR结果到翻译的流程
- [ ] 创建OCR结果展示界面
- [ ] 实现文字区域高亮

### 3.4 测试与提交
- [ ] OCR识别测试
- [ ] 截图功能测试
- [ ] Git commit: `feat(ocr): implement OCR translation feature`

---

## 阶段四：优化与完善

### 4.1 性能优化
- [ ] 启动时间优化
- [ ] 内存使用优化
- [ ] 网络请求缓存

### 4.2 用户体验
- [ ] 添加应用图标
- [ ] 完善暗色模式支持
- [ ] 添加动画效果
- [ ] 添加状态栏图标

### 4.3 设置完善
- [ ] 添加多翻译源支持
- [ ] 添加开机自启动选项
- [ ] 添加翻译历史管理

### 4.4 最终测试与提交
- [ ] 完整功能测试
- [ ] 性能测试
- [ ] Git commit: `perf: optimize application performance and UX`

---

## 任务统计

| 阶段 | 任务数 | 预计完成度 |
|------|--------|-----------|
| 阶段一 | 20 | 0% |
| 阶段二 | 10 | 0% |
| 阶段三 | 9 | 0% |
| 阶段四 | 10 | 0% |
| **总计** | **49** | **0%** |

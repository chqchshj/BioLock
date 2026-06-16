# BioLock

**Face ID / Touch ID / 密码 应用锁** — 适用于 iOS 15+ rootless 越狱（Dopamine）

基于 [BatuBey5G/BioLock](https://github.com/BatuBey5G/BioLock) 重构，针对 iOS 16 + Dopamine 越狱进行了深度适配和功能增强。

---

## 功能特性

- 🔒 **Face ID / Touch ID / 密码保护** — 打开受保护应用时需要生物认证
- 📱 **应用选择** — 从已安装应用列表中选择要保护的应用
- 🔍 **搜索功能** — 应用列表顶部搜索栏，快速定位应用
- ⚡ **开关控制** — 每个应用独立开关，即时生效
- 🎛️ **灵活配置** — 启用/禁用插件、允许密码验证、失败震动
- 📋 **应用缓存** — Tweak 自动扫描已安装应用并缓存，设置页直接读取

---

## 适用环境

| 项目 | 要求 |
|------|------|
| **设备** | iPhone / iPad（A8 及以上芯片） |
| **系统** | iOS 15.0 - 16.6.1 |
| **越狱** | Dopamine（rootless 模式） |
| **依赖** | mobilesubstrate (>= 0.9.5000)、preferenceloader |
| **注入** | ElleKit（Dopamine 内置，替代 Cydia Substrate） |

### 已验证设备

| 设备 | 系统 | 越狱 | 状态 |
|------|------|------|------|
| iPhone 13 Pro Max (A15) | iOS 16.0 | Dopamine 2.x | ✅ 正常工作 |

---

## 安装方式

### 方式一：从 Releases 下载（推荐）

1. 前往 [Releases](https://github.com/chqchshj/BioLock/releases) 页面
2. 下载最新版本的 `.deb` 文件
3. 使用 Filza 文件管理器打开并安装
4. 重启 SpringBoard（Respring）

### 方式二：从源码编译

```bash
# 克隆仓库
git clone https://github.com/chqchshj/BioLock.git
cd BioLock

# 安装 Theos（如果没有）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 编译
export THEOS=$HOME/theos
export PATH="$THEOS/bin:$PATH"
make package FINALPACKAGE=1

# deb 包在 packages/ 目录下
```

### 方式三：GitHub Actions 自动编译

Push 到 `main` 分支会自动触发 CI 编译，产物在 Actions → Artifacts 中下载。

---

## 使用方法

1. **安装后首次使用**：先打开任意一个 App，触发 Tweak 初始化应用缓存
2. **进入设置**：设置 → BioLock → 选择应用
3. **选择要保护的应用**：通过搜索栏查找，打开对应开关
4. **测试**：打开被保护的应用，应该会弹出 Face ID / 密码验证

### 设置选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| **启用插件** | 总开关，关闭后所有应用不再需要验证 | 开启 |
| **允许使用密码** | 允许使用设备密码替代生物识别 | 开启 |
| **失败时震动** | 验证失败时设备震动提醒 | 开启 |

---

## 项目结构

```
BioLock/
├── Makefile                          # 主 Makefile（Tweak + 子项目）
├── control                           # deb 包元数据
├── BioLock.plist                     # Tweak 注入过滤器（com.apple.springboard）
├── Tweak.x                           # SpringBoard hook 核心逻辑
├── biolockprefs/                     # Preference Bundle（设置面板）
│   ├── Makefile                      # Bundle 编译配置
│   ├── BLPRootListController.h/m     # 根设置页控制器
│   ├── BLPAppListController.h/m      # 应用列表页控制器（UITableViewController）
│   └── Resources/
│       ├── Root.plist                # 设置页 UI 定义
│       ├── BioLockIcon.png           # 图标 @1x (29×29)
│       ├── BioLockIcon@2x.png        # 图标 @2x (58×58)
│       ├── BioLockIcon@3x.png        # 图标 @3x (87×87)
│       └── Info.plist                # Bundle 元数据
├── layout/
│   └── Library/PreferenceLoader/Preferences/
│       └── com.batues.biolock.plist  # PreferenceLoader 入口
└── .github/workflows/build.yml       # CI 编译配置
```

---

## 技术架构

### Tweak（SpringBoard 注入）

```
用户点击 App 图标
    │
    ▼
SpringBoard 调用 activateApplication:...
    │
    ▼
BioLock hook 拦截
    │
    ├── 不在保护列表 → %orig 放行
    │
    └── 在保护列表
        │
        ▼
    LAContext 弹出 Face ID / 密码验证
        │
        ├── 成功 → 重新调用 activateApplication（放行）
        └── 失败 → 震动提示，不放行
```

- **Hook 点**：`SBUIController` 的 `activateApplication:fromIcon:location:activationSettings:actions:`
- **初始化**：懒加载模式（`EnsureInitialized()`），首次 hook 调用时初始化
- **应用缓存**：`LSApplicationWorkspace` 扫描所有已安装应用，写入 plist 缓存文件

### 设置面板（Preference Bundle）

- **根页面**：PSButtonCell + PSSwitchCell（原生 Preferences 框架）
- **应用列表**：UITableViewController（非 PSListController，避免 iOS 16 崩溃）
- **数据源**：读取 Tweak 缓存的 `com.batues.biolock.applist.plist`
- **搜索**：UISearchBar + NSPredicate 实时过滤

---

## 关键设计决策

### 为什么不用 AltList？

上游 BioLock 使用 [AltList](https://github.com/opa334/AltList) 框架来显示应用选择页面。但在 iOS 16 + Dopamine 环境下，AltList 的 `ATLApplicationListMultiSelectionController` 会导致 Preferences 进程崩溃。

**解决方案**：完全移除 AltList 依赖，使用自定义 `UITableViewController` + `UISwitch` 实现应用选择功能。

### 为什么不用 PSListController 子类？

V10 版本使用 `PSListController` 子类作为应用列表页，但在 iOS 16 上 `viewDidLoad` 阶段会崩溃（`_sendViewDidLoadWithAppearanceProxyObjectTaggingEnabled`）。

**解决方案**：改用 `UITableViewController`，完全避开 PSListController 的初始化时序问题。

### 为什么 Tweak 用懒加载而不是 %ctor 初始化？

Dopamine 的 ElleKit 注入机制下，dyld 阶段过早调用 Objective-C 方法可能导致 `EXC_BAD_ACCESS` 崩溃（进入安全模式）。

**解决方案**：`%ctor` 保持为空，所有初始化通过 `EnsureInitialized()` 在首次 hook 调用时执行。

---

## 开发历史

| 版本 | 变更 |
|------|------|
| v1-v3 | 修复 SpringBoard 崩溃：LoadPrefs() 从 dyld constructor 移到首次 hook 调用 |
| v4-v5 | 修复应用列表空白：简化 LSApplicationWorkspace 过滤逻辑 |
| v6 | 尝试嵌入 AltList stub 框架（失败） |
| v7 | 修复 arm64e 编译：CI 改用 macOS runner |
| v8 | 架构重写：移除 AltList，Tweak 写缓存 + 设置读缓存 |
| v9 | 升级图标尺寸，添加搜索栏 |
| v10 | 修复 PSLinkCell 崩溃：改用 PSButtonCell + 手动 push |
| v12 | 合并 v8 基础 + v10 图标（错误引入 AltList） |
| v14 | 基于 V8 架构完全重写，UITableViewController 替代 PSListController |
| v14.5 | 修复图标二进制编码，搜索功能确认可用 |

---

## 常见问题

### Q: 安装后设置里看不到 BioLock？
A: 确认已安装 `preferenceloader` 包。重启 SpringBoard 后再查看。

### Q: 选择应用页面是空白的？
A: 需要先打开任意一个 App 触发 Tweak 写入应用缓存。打开一个 App 后返回设置页面刷新。

### Q: 验证弹窗不出现？
A: 检查设置中"启用插件"开关是否打开。确认应用已在"选择应用"列表中开启。

### Q: 设备进入安全模式？
A: 可能是 Tweak 与其他插件冲突。尝试在 Sileo 中卸载 BioLock，或使用 Choicy 禁用 BioLock 对特定进程的注入。

---

## 致谢

- [BatuBey5G/BioLock](https://github.com/BatuBey5G/BioLock) — 原始项目
- [Dopamine](https://github.com/opa334/Dopamine) — iOS 15-16 rootless 越狱
- [Theos](https://theos.dev/) — iOS 越狱开发工具链
- [ElleKit](https://github.com/evelyneee/ellekit) — Hook 框架

---

## 许可证

MIT License — 基于上游 [BatuBey5G/BioLock](https://github.com/BatuBey5G/BioLock) 的 MIT 许可证。

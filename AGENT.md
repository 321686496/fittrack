# AGENT.md — FitTrack (health_training)

> 本文件为 AI 助手在本工程中工作的操作指南与约束。**AGENT.md 中的指令优先级高于默认行为**，请严格遵守。

---

## 0. 强制约束（每次对话必读）

### 0.1 强制执行 superpowers skill

- **每次对话开始时，第一个动作必须是通过 Skill 工具调用 `using-superpowers` 技能**，然后再进行任何其他操作（澄清问题、探索代码、读文件、回答等）。
- 此约束优先级高于其他所有规则，不可违反。
- 调用后按技能指引执行：若有其他相关流程技能（如 brainstorming、systematic-debugging）也应先行调用。

### 0.2 HarmonyOS 开发必须参考官方文档

当任务涉及 **HarmonyOS / OHOS / ArkTS / ArkUI（`.ets` 文件、`ohos/` 目录、桌面卡片、代理提醒、原生桥接等）** 开发时，**必须参考以下华为官方文档**，以官方 API、语法与最佳实践为准，不得凭记忆臆造 API：

- 文档总入口：https://developer.huawei.com/consumer/cn/doc/
- ArkTS 快速入门：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-get-started
- ArkTS 语言概述：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-overview
- ArkUI 框架概述：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview

> 遇到不确定的 OHOS API / 组件 / 权限 / 生命周期时，先查阅上述文档再动手。

---

## 1. 工程概述

- **应用名**：FitTrack（燃力）— 健身训练追踪应用，纯本地单机架构（数据不上云）。
- **仓库根目录**：`d:\app\projects\health_training`
- **当前主工程**：`./fittrack_flutter`（功能最全的主力版本）。
- **技术栈**：Flutter（Dart，SDK 约束 `>=2.19.6 <3.0.0`）+ go_router 路由 + SQLite/SharedPreferences 混合存储 + HarmonyOS 原生 ArkTS 扩展。
- **主要目标平台**：HarmonyOS (OHOS)、Android；其余平台（iOS/macOS/Windows/Linux/Web）为 Flutter 脚手架壳。
- **其他子项目**：
  - `fittrack_flutter2/` — 精简 Flutter 版（仅 SharedPreferences，无 SQLite/go_router）
  - `FitTrackHarmony/` — 原生 HarmonyOS 版（ArkTS，独立实现）

> 完整架构说明见 `./CODE_WIKI.md`。

---

## 2. 主工程目录结构（fittrack_flutter/lib/）

```
lib/
├── main.dart                 入口：初始化 Storage / 权限 / 通知 / 卡片，构建 FitTrackApp
├── router.dart               go_router 路由 + AppShell（IndexedStack 底部导航）
├── data/
│   ├── storage.dart          混合持久化层（内存缓存 + SQLite + SharedPreferences）
│   ├── database_helper.dart  SQLite 管理（plans / records / gym_cards）
│   └── mock_data.dart        静态 Mock 数据
├── pages/                    15 个页面（splash/onboarding/home/training/stats/... ）
├── services/                 rest_notification / form_kit / ohos_reminder / permission / user_profile_generator
├── themes/app_themes.dart    7 套主题 + FitTrackColors ThemeExtension
└── widgets/                  bottom_nav / common_widgets / page_header

平台目录：fittrack_flutter/{android, ios, ohos, macos, windows, linux, web}/
OHOS 原生代码：fittrack_flutter/ohos/entry/src/main/ets/
  ├── entryability/EntryAbility.ets
  ├── formability/FitTrackFormExtension.ets
  └── pages/{FitTrackWidget.ets, Index.ets}
```

---

## 3. 架构与关键约定

- **状态管理**：未引入 Provider/Bloc/Riverpod。采用 `Storage` 内存缓存 + `ValueNotifier`（`Storage.dataChanged`、`currentTabIndex`）+ `setState` 组合。修改数据时走 `Storage` 的同步方法（更新缓存 + 异步落盘）。
- **数据分流**：
  - 结构化数据（Plans / Records / GymCards）→ SQLite（`fittrack.db` v2）。
  - 轻量键值（Settings / Stats / BodyData）→ SharedPreferences（JSON 字符串）。
- **路由**：集中在 `router.dart`（`go_router`）。带底部导航的页面在 `ShellRoute` 下（home/plan/records/stats/profile）；training/exercise/settings 等为 root navigator 独立路由。`AppShell` 用 `IndexedStack` 缓存 Tab。
- **主题**：通过 `Theme.of(context).extension<FitTrackColors>()!` 访问色板，**不要硬编码颜色**。主题切换经 `main.dart` 的 `onThemeChanged` 回调统一处理。
- **平台判断**：OHOS 专属逻辑用 `if (Platform.isOhos) { ... }` 包裹（桌面卡片、代理提醒）。

---

## 4. HarmonyOS (OHOS) 相关要点

- 原生代码位于 `fittrack_flutter/ohos/entry/src/main/ets/`。
- **权限**（`ohos/entry/src/main/module.json5` 已声明）：`INTERNET`、`PUBLISH_AGENT_REMINDER`（后台代理提醒）、`VIBRATE`。新增权限需同步更新此文件。
- **Flutter ↔ 原生通信**：MethodChannel（桌面卡片 form 通道、reminder 通道）。对应 Dart 侧：`services/form_kit_service.dart`、`services/ohos_reminder_service.dart`。
- 修改卡片 / 提醒 / ArkTS 代码前，务必查阅 [第 0.2 节] 的华为官方文档。

---

## 5. 常用命令

```bash
# 进入主工程
cd d:\app\projects\health_training\fittrack_flutter

flutter pub get              # 安装依赖
flutter analyze             # 静态检查（遵循 analysis_options.yaml / flutter_lints）
flutter test                # 运行 test/widget_test.dart

# 运行 / 构建
flutter run                 # 默认设备（Android/桌面）
flutter build apk           # Android 包
flutter run -d ohos         # HarmonyOS（需 Flutter OHOS 工具链 + DevEco 环境）
flutter build hap           # HarmonyOS 包
```

---

## 6. 编码规范

- 遵循 `analysis_options.yaml`（`package:flutter_lints/flutter.yaml`）；提交前跑 `flutter analyze` 保持无警告。
- 命名/风格与现有代码保持一致；页面放 `pages/`，可复用 UI 放 `widgets/`，业务能力放 `services/`，数据访问统一走 `data/storage.dart`。
- 新增第三方依赖需评估 OHOS 兼容性（部分包依赖 gitcode 上的 OHOS 定制分支，见 `pubspec.yaml`）。
- 不新增无关文件；优先编辑既有文件，不主动创建文档类文件（除非用户明确要求）。

---

## 7. 参考

- 项目代码百科：`./CODE_WIKI.md`
- 后台代理提醒权限说明：`./fittrack_flutter/后台代理提醒权限申请说明.txt`
- HarmonyOS 官方文档：见 [第 0.2 节]

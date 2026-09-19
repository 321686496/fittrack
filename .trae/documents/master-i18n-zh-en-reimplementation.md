# 在 master 上重新实现中英双语 i18n

## Context（背景）

- 远程 `feature/i18n-zh-en` 分支基于 6月29日 的旧代码（`6eb802b`），master 已独立演进约 2.5 个月并完成目录重构（`fittrack_flutter2` → `fittrack_flutter`），直接 merge 产生 150+ 冲突（几乎全为 add/add），无法干净合并。
- 已与用户确认：**不合并分支，在 master 上重新实现 i18n**，借鉴分支的自定义 i18n 架构。
- 架构方案（分支已验证）：**中文源串作 key + 运行时查表**，不依赖 gen_l10n/intl。
  - 代码仍写中文：`Text(tr(context, '首页'))`；英文模式按「中→英」词典翻译；缺词条回落中文不崩。
  - `tr(context, s)` 注册依赖自动重建；`trn(s)` 用于无 context 的数据/服务层；`LocaleMemo<T>` 解决 `static final` 数据冻结。
- 复用资产（与代码结构解耦，可直接搬）：
  - `lib/l10n/i18n.dart`、`lib/l10n/locale_controller.dart`（语言控制器 + InheritedNotifier）
  - `lib/l10n/strings_en.dart`（3467 行，3300+ 条英译词典，自包含）
  - `scripts/`：i18n_scan.py（抽中文串）、i18n_codemod.py（批量包裹）、gen_i18n_dict.py（生成词典）、i18n_check_frozen.py / i18n_check_lifecycle.py / i18n_fix_*.py（检查修复）、i18n_coverage.py（覆盖率）
  - 分支测试：i18n_locale_test.dart、settings_language_test.dart、英文布局测试、flutter_test_config.dart 中文基线

## 规模评估

- master `lib/` 约 2.4 万处中文字符串（含 tutorial_content.dart 7000+ 行等内容数据），涉及 100+ 文件。分阶段实施，每阶段独立可验证。

## 实施阶段

### Phase 1：基础设施接入（独立可验证，先行交付）

1. 从分支取回资产（保留在 master 工作树）：
   `git checkout origin/feature/i18n-zh-en -- fittrack_flutter/lib/l10n fittrack_flutter/scripts`
2. `lib/main.dart` 接入：
   - `main()` 中 `Storage.init()` 之后调用 `await LocaleController.instance.init()`；
   - `MaterialApp.router` 外层包 `LocaleScope(controller: LocaleController.instance, child: ...)`；
   - 配置 `supportedLocales`、`localizationsDelegates`、`locale`、`localeResolutionCallback`（使用分支提供的 `zhLocale/enLocale` 与 `localeResolutionCallback`）。
3. `lib/data/storage.dart` 默认设置新增 `'languageCode': 'system'`。
4. `lib/pages/settings_page.dart` 新增「语言 / Language」设置行：跟随系统 / 简体中文 / English，调用 `LocaleController.instance.setLanguage(...)`。
5. 移植 `test/flutter_test_config.dart` 中文基线（锁定 zh，避免既有测试断言中文失败）。
6. 验证：`flutter analyze` 无新增问题；既有 `flutter test` 通过；手动运行可在设置页切语言并全局生效。

### Phase 2：文案包裹（分批、脚本辅助 + 人工审查）

1. `python scripts/i18n_codemod.py --dry` 预演 → 实际执行。规则：`pages/ widgets/ main.dart router.dart` 用 `tr(context, ...)`，其余（data/services/models）用 `trn(...)`；自动去 const、补 `../l10n/i18n.dart` import。
2. `i18n_check_lifecycle.py`：修复 `initState` 中误用 `tr(context)`（规则一），0 处为止。
3. `i18n_check_frozen.py` / `i18n_fix_frozen.py --dry-run` → `--apply`：把 `static final` / 顶层常量中的 `trn()` 改写成 `LocaleMemo` + getter（规则二）。
4. `i18n_fix_logic.py`：处理身份标识/持久化字段误翻译（规则三：数据键保持中文，仅渲染时翻译）。
5. 按模块分批人工审查 + `flutter analyze` 清零：
   - 导航与外壳：bottom_nav、shell、router
   - 设置/主题/评分/夜间相关页
   - 首页/统计/我的/身体数据
   - 计划模块（计划库/详情/搜索/海报）
   - 训练/记录/最大重量
   - 教学/课程/笔记
   - 邀请/积分/商城/皮肤
   - 内容数据（tutorial_content/course_content/mock_data 等，量最大，最后处理）
6. 每批提交一次，确保中间态可回退。

### Phase 3：词典扩充

- 直接复用分支 `strings_en.dart`（已覆盖大量通用词条）。
- `i18n_scan.py` 重新扫描 master 全部中文串 → `build/i18n/strings.json`；未命中词典的串按批（`build/i18n/batches/out_*.json`）补译；`gen_i18n_dict.py` 合并生成新词典。
- `i18n_coverage.py` 报告覆盖率，目标高覆盖（新 UI 文案全覆盖；长内容数据允许部分回落中文）。

### Phase 4：测试与验证

- 移植并适配 i18n 测试：`i18n_locale_test.dart`（切换/跟随系统/持久化）、`settings_language_test.dart`、`i18n_english_layout_test.dart`（英文布局无溢出）。
- `flutter analyze` 0 issue；`flutter test` 全部通过。
- 手动验收：切英文后主要页面（首页/计划/设置/教学/记录/邀请）无布局溢出、无乱码，词典未覆盖处回落中文不崩。

## 关键文件

- 新增：`fittrack_flutter/lib/l10n/{i18n,locale_controller,strings_en}.dart`、`fittrack_flutter/scripts/*.py`
- 修改：
  - `fittrack_flutter/lib/main.dart`（LocaleScope + MaterialApp locale 配置）
  - `fittrack_flutter/lib/pages/settings_page.dart`（语言设置行）
  - `fittrack_flutter/lib/data/storage.dart`（languageCode 默认值）
  - `fittrack_flutter/test/flutter_test_config.dart`（中文基线）
  - `fittrack_flutter/lib/pages/**`、`lib/widgets/**`、`lib/data/**`、`lib/services/**`（分批包裹）

## 分支清理

- 重实现完成并验证通过后，与用户确认再删除 origin/github 的 `feature/i18n-zh-en` 远程分支。

## 验证方式

- 每阶段：`cd fittrack_flutter && flutter analyze && flutter test`（Windows 本机）。
- 整体：设置页切「English」→ 检查首页/计划/设置/教学/记录等页面英文渲染与布局；切回中文确认无回归。

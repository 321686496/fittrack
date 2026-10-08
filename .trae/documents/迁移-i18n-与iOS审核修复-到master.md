# 迁移 i18n(全量) + iOS 审核隐私清单 到 master

## Context（背景与目标）

`feature/i18n-zh-en`（12 提交，含中英双语 i18n + iOS 隐私清单 + OHOS 修复）与 `origin/master`（不含 i18n，代码已大幅演进）从同一基 `6eb802b1` 深度分叉：feature 相对 origin/master 独有 12 提交，origin/master 相对 feature 独有 338 提交。逐提交 rebase/merge 会撞上百 add/add 冲突，且产物会丢掉 master 新功能或 i18n 包装，错误率高。

用户决策：**以 `origin/master` 为主干，只迁移两类改动**：
1. **i18n 全量覆盖** — 补 l10n 基础设施 + 复跑 codemod 把 master 全量 lib/ 字符串包成 tr/trn，实现全应用中英双语。
2. **线上审核修复** — cherry-pick `9551a771`『ios: ITMS-91061 缺少隐私清单——构建期注入官方 PrivacyInfo.xcprivacy』。

**无需额外迁移项**（已甄别）：
- `ios扫一扫异常`：经逐文件比对，`qr_scan_page.dart`/`scan_import_page.dart` 在 feature 与 master 的差异**全部是 i18n 包装所致**（为运行时翻译去掉 `const`），相机权限三项（NSCameraUsageDescription 等）master 的 `ios/Runner/Info.plist` 已有，OHOS ScanKit 兼容两层分支都在。无独立 iOS 扫码修复可迁，随 i18n 一并覆盖。
- OHOS 修复 `3584c714`：master 上已被用户自己的 `fdd55a79`（导入/提醒/海报/休息提醒四处）+ `23c2181b` 修复覆盖，冗余，不迁。

## 关键事实（调研结论）

- i18n 基础设施（feature 版）：`lib/l10n/{i18n,locale_controller,strings_en}.dart`。`LocaleScope`(InheritedNotifier) 提供 `tr()`；`trn()` 走单例 `LocaleController.instance`；语言存 `Storage.getSettings()['languageCode']`；设备语言不支持回退中文。
- `i18n_codemod.py` 可重跑（批量包中文字面量，支持 `--dry`）；配套 `i18n_scan/coverage/fix_*` 脚本。
- 基底必须用 `origin/master`。当前本地 `master` 引用指向旧合并 `b18ff0b1`，且工作区正停在**被暂停的无用 rebase**（大量文件带冲突标记）——所以第一步先清场。

---

## 实施步骤

### Step 0 — 清场（git 根目录）
```bash
git rebase --abort          # 丢弃无用 rebase，清掉工作区冲突标记
git branch -f master origin/master   # 重指本地 master（旧引用 b18ff0b1 已无价值）
git fetch origin github     # 同步两个远端
git status                  # 确认干净
```

### Step 1 — 建立迁移分支
```bash
git checkout -b migrate/i18n-privacymanifest origin/master
```

### Step 2 — i18n 落地（cwd = fittrack_flutter）
1. **基础设施（拷贝，不手写）**：
   ```bash
   git checkout feature/i18n-zh-en -- fittrack_flutter/lib/l10n fittrack_flutter/scripts
   ```
   得到 `lib/l10n/{i18n,locale_controller,strings_en}.dart` 与全部 `scripts/i18n_*`。
2. **pubspec.yaml**：`dependencies:` 加 `flutter_localizations: sdk: flutter`。**保留**现有 `dependency_overrides`：`flutter_local_notifications` OHOS git fork(ref: master) 不动；补/保 `win32: 3.1.4` 覆盖。SDK 保持 `>=2.19.6 <3.0.0`。`flutter pub get`。
3. **master 版 `lib/main.dart` 接线**（对照 feature 版 `lib/main.dart`）：
   - `Storage.init()` 之后 `await LocaleController.instance.init();`
   - MaterialApp 加 `localizationsDelegates: GlobalMaterialLocalizations.delegates`（含 GlobalWidgets/GlobalCupertino）、`supportedLocales`；
   - `_LiftTrackAppState` 加 `addListener(_onLocaleChanged)`，语言切换时 `setState` 重建，`dispose` remove。
4. **master 版 `lib/pages/settings_page.dart` 加语言切换入口**（对照 feature 版）：在合适菜单分组加"语言/跟随系统"（`AppLanguage.system/zh/en` 三选），持久化走 LocaleController.setLanguage。
5. **词典 + codemod（顺序：先词典后 codemod）**：
   - 用 feature 版 `strings_en.dart` 作基词典（已覆盖绝大多数）；
   - ```bash
     python scripts/i18n_codemod.py --dry   # 先统计
     python scripts/i18n_codemod.py         # 落盘
     ```
   - 修复链（按 feature README 顺序）：`i18n_fix_const.py` → `fix_const_call` → `fix_context` → `fix_logic` → `fix_nested` → `fix_frozen`；再 `i18n_check_frozen.py`、`i18n_check_lifecycle.py`。
   - **master 独有新字符串**（contact_info、system_plan_library 等）：`i18n_coverage.py --detail --root .` 列出英文下仍显示中文的条目，逐条补入 `strings_en.dart`。
6. **覆盖率目标**：`i18n_coverage.py` 未命中 = 0；`i18n_scan.py` 复核无裸中文字面量（l10n 除外）。

### Step 3 — iOS 审核修复
```bash
git cherry-pick 9551a771      # ios/ 侧，预计无冲突
```
验证：`ios/Runner/PrivacyInfo.xcprivacy`、`ios/scripts/inject_privacy_manifests.sh`、`.gitattributes` 存在，Podfile/project.pbxproj 含注入引用。Windows 本地不能编 iOS → 由 macos CI workflow 验证或 mac 上 `flutter build ipa --no-codesign`。

### Step 4 — 合回 master 并推送
```bash
git checkout master
git merge --no-ff migrate/i18n-privacymanifest
git push origin master    # 先 gitee/origin
git push github master    # 确认后再 github，逐个推避免双失败
```

### Step 5 — 验证（cwd=fittrack_flutter）
- `flutter analyze` 0 error；
- `flutter build apk --debug`（Android）、OHOS 编译（沿用 CI）；
- `flutter test`（i18n 相关 + widget_test）；
- 人工：设置页切中/英即时生效、重启后语言持久化、扫描页中英文下可唤起。

---

## 风险与取舍
- 重跑 codemod 对 master 全量改动：master 新增文件/新流程若无词典条目会漏翻，需逐条覆盖核验。
- master 与 feature 的 main.dart 顶层逻辑已一致，差异集中在 build 区；settings 菜单结构可能分叉，`_buildOtherMenu` 归属需人工确认。
- **本地 master 旧引用必须重指**（Step 0），别误 push 旧合并引用。

## 复用与关键文件
- 复用 feature 版工具链：`fittrack_flutter/scripts/i18n_codemod.py`、`i18n_scan.py`、`i18n_coverage.py`、`i18n_fix_*.py`、`i18n_check_*.py`。
- 需改动的文件：`lib/main.dart`、`lib/pages/settings_page.dart`、`pubspec.yaml`；新增 `lib/l10n/*`、`scripts/i18n_*`（拷贝自 feature）。
- 参考 feature 版来源（`git show feature/i18n-zh-en:<path>`）：`lib/main.dart`、`lib/pages/settings_page.dart`。
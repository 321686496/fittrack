# FitTrack 多语言（中 / 英）维护说明

## 一、方案概述

采用「中文源串作 key + 运行时查表」的轻量 i18n 方案，不依赖 gen_l10n / ARB 文件。

- 代码里仍然写中文：`Text(tr(context, '首页'))`
- 切到英文时，运行时按 `中文 → 英文` 词典翻译
- 词典缺词条时**原样返回中文**（不会崩、不会显示空白）

核心文件：

| 文件 | 作用 |
| --- | --- |
| `lib/l10n/locale_controller.dart` | 语言枚举 `AppLanguage`（system / zh / en）、SharedPreferences 持久化、生效 Locale 计算、语言代次 `generation` |
| `lib/l10n/i18n.dart` | `LocaleScope`（InheritedNotifier）、`tr(context, s)`、`trn(s)`、`LocaleMemo` |
| `lib/l10n/strings_en.dart` | 英译词典（3300+ 条），由脚本生成，**请勿手工编辑** |

## 二、两个翻译入口怎么选

```dart
// 1) 有 BuildContext 的 UI 代码 —— 用 tr()，会注册依赖，切换语言时自动重建
Text(tr(context, '训练'))

// 2) 没有 context 的地方（数据层、service、静态常量）—— 用 trn()
//    注意：trn() 不会触发重建，需要上层 Widget 重建后才刷新
String title = trn('已完成');
```

带参数（占位符）：

```dart
tr(context, '第{day}天', {'day': 3})     // 第3天 / Day 3
```

> 占位符用 `{name}` 形式。Dart 原生插值 `${xxx}` 也支持（词典会按模板匹配），
> 但翻译是按整串匹配的，**插值内部内容变了会导致匹配失败并回落中文**。

### 2.1 三条硬规则（踩过坑，务必遵守）

**规则一：`initState()` 里不能用 `tr(context, ...)`。**

`initState` 完成前访问 InheritedWidget 会抛 `FlutterError`
（"dependOnInheritedWidgetOfExactType() … was called before …initState() completed"），
debug 包直接红屏。三种正确写法：

```dart
// ① 用 trn()（不注册依赖）
String _title = trn('今日训练');

// ② 把初始化挪到 didChangeDependencies()
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _title = tr(context, '今日训练');
}

// ③ 只在 build() 里翻译
Text(tr(context, _titleKey))
```

自动检查：

```bash
python scripts/i18n_check_lifecycle.py lib   # 必须输出「命中 0 处」
```

**规则二：`trn()` 不能写在字段 / 顶层的初始化位置。**

`static final`、`final`、顶层变量只求值一次，里面的 `trn()` 会被**冻结在首次访问时的语言**——
用户切到英文后，课程正文、教学文案、动作名仍然是中文。

```dart
// 错误 —— 语言被冻结
static final List<Course> courses = [Course(title: trn('新手增肌入门'))];

// 正确 —— 按语言代次缓存，切语言后自动重建
static List<Course> get courses => _coursesMemo.value;
static final LocaleMemo<List<Course>> _coursesMemo = LocaleMemo(() => [
  Course(title: trn('新手增肌入门')),
]);
```

> 方法体里的 `final x = trn('...')` 每次调用都重新求值，**不是**冻结，不用改。

自动检查 / 批量修复：

```bash
python scripts/i18n_check_frozen.py            # 必须输出「0 处」
python scripts/i18n_fix_frozen.py --dry-run    # 先看清单
python scripts/i18n_fix_frozen.py --apply      # 再写盘（改完务必 flutter analyze）
```

**规则三：身份标识（数据键）一律保持中文字面量，只在渲染时翻译。**

会持久化、或参与相等判断 / map key / 筛选的值，**不要**包 `trn()` 或 `tr()`：

```dart
// 错误 —— 英文模式下 trn('三分化') 变成 'Three-day split'，
//          与持久化的 plan['type']（中文）对不上，模板匹配与选中态全部失效
List<String> _planTypes = [trn('三分化'), trn('四分化')];
String _selectedType = trn('三分化');

// 正确 —— 数据键保持中文，展示处翻译
List<String> _planTypes = ['三分化', '四分化'];
String _selectedType = '三分化';
Text(tr(context, type))              // 展示时翻译
```

已踩过的坑用 `scripts/i18n_fix_logic.py` 批量修正过（119 处）。

## 三、新增中文文案的流程

1. 直接写中文即可，但**记得包一层 `tr(context, ...)` / `trn(...)`**：

   ```dart
   Text(tr(context, '新增的动作名称'))
   ```

2. 跑扫描脚本，收集所有中文串：

   ```bash
   python scripts/i18n_scan.py
   # 产出 build/i18n/strings.json
   ```

3. 把新词条（对比 `lib/l10n/strings_en.dart` 里已有的）交给翻译，
   结果按批写入 `build/i18n/batches/out_XX.json`，格式：

   ```json
   [{"zh": "首页", "en": "Home"}, ...]
   ```

4. 重新生成词典：

   ```bash
   python scripts/gen_i18n_dict.py
   # 覆盖写入 lib/l10n/strings_en.dart
   ```

   脚本会自动做两类校验，不通过的词条直接剔除（回落中文，安全）：
   - 占位符集合不一致（译文改动了插值内部）
   - 首尾空格不一致

5. 验证：

   ```bash
   flutter analyze
   flutter test
   ```

## 四、批量改造脚本（一次性迁移用，已执行过，留档）

| 脚本 | 用途 |
| --- | --- |
| `i18n_scan.py` | Dart 词法扫描，抽取含中文的字符串字面量 |
| `i18n_codemod.py` | 批量给中文串包 `tr(context, ...)` / `trn(...)`，自动补 import |
| `i18n_fix_nested.py` | 修复 `${}` 内嵌套字面量被重复包裹、相邻字符串拼接 |
| `i18n_fix_const.py` | 清理包了 `tr()` 后失效的 `const`（`const` → `final`） |
| `i18n_fix_context.py` | 把无 context 处的 `tr(context, X)` 降级为 `trn(X)` |
| `i18n_fix_const_call.py` | 按 analyze 报错移除调用点上的 `const` |
| `i18n_fix_logic.py` | 还原被误包成 `trn()` 的**逻辑串**（判断 / 匹配 / 关键词表） |
| `gen_i18n_dict.py` | 合并翻译批次 → 生成 `strings_en.dart` |
| `i18n_coverage.py` | 统计英文覆盖率，列出「英文模式下仍显示中文」的串及位置 |

持续自检（改动 i18n 相关代码后建议全跑一遍）：

| 脚本 | 检查什么 | 期望结果 |
| --- | --- | --- |
| `i18n_check_lifecycle.py lib` | `initState` 内误用 `tr(context)`（见 §2.1 规则一） | 命中 0 处 |
| `i18n_check_frozen.py` | 字段 / 顶层初始化位置里的 `trn()`（规则二） | 0 处 |
| `i18n_fix_frozen.py` | 把上面这类声明改写成 `LocaleMemo` + getter | 自动改写，需人工复核 SKIP 清单 |
| `i18n_coverage.py --detail` | 词典缺哪些串、在哪一行 | 缺失 0～2 条 |
| `i18n_coverage.py --lint` | 词典质量（空译文 / 残留中文 / 全角标点 / 占位符不一致…） | 3 条以内 |

补翻译后想确认效果：

```bash
python scripts/i18n_coverage.py --detail   # 缺哪些串、在哪一行
python scripts/i18n_coverage.py --lint     # 词典自检
```

`--lint` 会检查：译文为空、译文与原文相同、译文里残留中文、首尾空格不一致、
占位符数量不一致、英文里出现全角标点、重复 key 译文冲突。

迁移规模：122 个文件、4729 处中文串包裹，词典 3318 条，英文覆盖率 99.96%。

### 4.1 词典匹配不到的两类串

- 含 `${}` 嵌套引号的长串（如 `'已导入「${planData['name']}」'`）：`i18n_coverage.py`
  已自动过滤这类正则截断片段，不再误报。
- 插值本身带格式化的串（如 `'${(v / 10000).toStringAsFixed(1)}万'`、
  `'${t.difficulty.label} · ${t.equipment ?? "无器械"}'`）：按整串精确匹配拿不到译文，
  运行时由模板规则兜底，属固有情况，可接受。

## 五、重要规则：不要用 `trn()` 包逻辑用的中文串

`trn()` 会真的把中文替换成英文。如果某串是**匹配 / 判断 / 存储值**，翻译后
就会和持久化下来的中文数据对不上，导致分类、筛选、判断全部失效：

```dart
// 错误 —— 英文模式下 gender 是 '女'，trn('女') 变成 'Female'，永远不相等
if (gender == trn('女')) ...

// 正确 —— 逻辑判断保持原始中文
if (gender == '女') ...

// 展示时才翻译
Text(tr(context, gender))
```

同理，关键词表、map key、switch case、以及 `contains/startsWith/endsWith`
的参数都不能翻译。

已经踩过一次的坑已用 `scripts/i18n_fix_logic.py` 批量修正（119 处），
新增代码请自行遵守。需要二次清理时运行：

```bash
python scripts/i18n_fix_logic.py --dry   # 先看清单
python scripts/i18n_fix_logic.py         # 再写盘
```

## 六、用户手动切换语言的位置

设置页 → 「语言」区块，三个选项：跟随系统 / 简体中文 / English。
选择后写入 SharedPreferences（`settings.languageCode`），下次启动自动恢复。

## 七、测试

跑测试请用：

```bash
no_proxy=localhost,127.0.0.1 flutter test -j 1
```

两个参数都是必须的：

- `no_proxy=localhost,127.0.0.1`：本机有 HTTP 代理，会劫持 flutter_tester 的
  localhost WebSocket，不设会全部报 `Unable to connect to flutter_tester process`。
- `-j 1`：多个测试文件共用同一个 sqlite 文件，并行跑会互相抢锁报
  `database is locked`。

与多语言相关的用例：

| 文件 | 覆盖点 |
| --- | --- |
| `test/i18n_locale_test.dart` | `tr()`/`trn()` 中英取值、词典未命中回落、占位符、切换后自动重建、locale 映射与回落规则 |
| `test/settings_language_test.dart` | 设置页语言区块渲染三个选项、点击后整页切换中英 |
| `test/i18n_english_layout_test.dart` | 设置页 / 引导页 / 推荐横幅 在 zh、en 下无布局溢出 |
| `test/i18n_english_layout_pages_test.dart` | 26 个页面 × zh/en 批量布局冒烟（见下） |

`test/flutter_test_config.dart` 会把测试语言锁定为**简体中文**。

原因：flutter_test 默认 locale 是 en_US，而既有用例断言的都是中文文案，
不锁定会大面积失败。需要验证英文的用例可自行覆盖：

```dart
LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
```

### 7.1 英文布局溢出测试

英文文案普遍比中文长 30%~50%，中文不溢出不代表英文不溢出。
`i18n_english_layout_pages_test.dart` 在 iPhone 14 逻辑尺寸（390×844）下
逐页渲染 zh / en 两遍，断言没有抛异常（含 RenderFlex overflow）。

`flutter_test` 用等宽测试字体，拉丁字母按 1em 计宽，**比真机更宽**，
所以这是一条悲观断言：能过，真机基本不会溢出。

已排除的页面（依赖原生插件，非布局问题）：

- `qr_scan_page` / `scan_import_page`：依赖 `RomAdaptationService` 原生通道
- `notification_test_page`：依赖本地通知插件

页面在 initState 里读 sqlite 的（成就页、笔记列表页等），测试需要：

```dart
setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  sqflite_utils.lockWarningDuration = null;  // 关掉锁等待 Timer，否则残留 pending Timer
});
```

### 7.2 修英文溢出的通用套路

最常见的形态是 **`Row` 里 `Icon + Text`，Text 没有 `Expanded` / `Flexible`**：

```dart
// 溢出
Row(children: [
  Icon(Icons.link, size: 14),
  SizedBox(width: 6),
  Text(tr(context, '绑定训练记录')),
  Spacer(),
  ...
])

// 修好：标题用 Flexible 收缩，尾部文案也加 Flexible + 单行省略
Row(children: [
  Icon(Icons.link, size: 14),
  SizedBox(width: 6),
  Flexible(child: Text(tr(context, '绑定训练记录'))),
  Spacer(),
  Flexible(child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis)),
])
```

其它常见处理：

| 场景 | 处理 |
| --- | --- |
| 标题后面跟着 `Spacer()` | 标题包 `Flexible` |
| 行内只有 `Icon + 标题` | 标题包 `Expanded` |
| 一排标签 / 徽章 | `Row` → `Wrap`（`spacing` + `runSpacing`），放不下自动换行 |
| 固定高度卡片里的多行文案 | 加 `maxLines: 1, overflow: TextOverflow.ellipsis` |
| 三个统计项等分 | 各自包 `Expanded`，内部文字加 `maxLines: 1` + `textAlign: center` |

定位溢出位置：布局测试的 `takeException()` 只拿到 `details.exception`，
**丢失了 creator / 文件行号**。需要精确位置时，临时写个探针，
用 `FlutterError.onError` 收 `details.toString()`（里面才有
"The relevant error-causing widget was: … xxx.dart:123:45"）。

## 八、已知取舍

- **数据层文案已按语言代次缓存**（`LocaleMemo`），切换语言后会重建，不再冻结。
- **写库的文案跟随写入时的语言**：例如在英文模式下保存一条训练记录，记录里
  存的动作名就是英文；之后切回中文，该记录仍显示英文。这是"展示文案即数据"
  的固有取舍——换来的好处是英文用户能看到全英文的动作名 / 课程内容。
- **身份键一律中文**：计划类型、难度、部位、问卷选项等会持久化或参与判断的值
  保持中文字面量（见 §2.1 规则三），因此切换语言不会让已选中的选项错位。
- 未翻译词条回落中文（当前覆盖率 99.96%，仅剩 2 条插值拼接串）。
- Material 内置组件（返回按钮、日期选择器等）的文案由 `flutter_localizations` 提供，
  已在 `main.dart` 注册三个 Global delegate，缺失会断言失败，不要删。

## 九、验证清单（改完 i18n 相关代码后照着跑）

```bash
no_proxy=localhost,127.0.0.1 flutter analyze          # 期望 0 error / 0 warning
no_proxy=localhost,127.0.0.1 flutter test -j 1        # 期望 All tests passed
python scripts/i18n_check_lifecycle.py lib            # 期望「命中 0 处」
python scripts/i18n_check_frozen.py                   # 期望「0 处」
python scripts/i18n_coverage.py --detail              # 期望缺失 ≤ 2
python scripts/i18n_coverage.py --lint                # 期望问题 ≤ 3
```

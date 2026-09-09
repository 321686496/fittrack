# 邀请有礼流程详情页 + 奖励链路修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 邀请页流程卡片可点击进入流程详解详情页（双视角完整流程），并修复奖励链路的误导 Toast 与积分明细页邀请标签缺口。

**Architecture:** 服务层 `InvitationService.recordReferralActivation` 返回值由 `ReferralMilestone?` 改为结构化 `ReferralRecordOutcome`（成功/累计人数/本次积分/里程碑）；新增纯静态 `InvitationFlowDetailPage` 注册 go_router 路由 `/invitation/flow`；积分明细页补齐 `invite_milestone_*` 标签、图标与「邀请」筛选匹配。

**Tech Stack:** Flutter 3.7.12 / Dart >=2.19.6 <3.0.0（禁用 Records/Pattern 语法）、go_router、flutter_test + sqflite_common_ffi

**Spec:** `docs/superpowers/specs/2026-09-09-invitation-flow-detail-design.md`

## Global Constraints

- Dart SDK 约束 `>=2.19.6 <3.0.0`：测试与实现中禁止 Records（`(a, b)` 元组）、switch 表达式等 Dart 3 语法
- 所有页面/卡片颜色必须使用 `LiftTrackColors`（`Theme.of(context).extension<LiftTrackColors>()!`），禁止新增自定义颜色
- 图标使用 Material `Icons.*`（与 `InvitationPage` 现有用法一致）
- 测试环境需 `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` + `SharedPreferences.setMockInitialValues({})` + `Storage.init()`（Storage 依赖 SQLite）
- `PointsService.addPoints` 触发 SoundService（AudioPlayer MethodChannel），测试需 mock `xyz.luan/audioplayers` 通道
- Shell 命令工作目录：`d:\app\projects\health_training\fittrack_flutter`
- 提交信息风格：`feat:`/`fix:` + 中文描述（与 git log 现有风格一致）

---

### Task 1: Service 层 ReferralRecordOutcome 结构化返回值

**Files:**
- Modify: `fittrack_flutter/lib/services/invitation_service.dart:31-44`（新增结果类）、`:342-409`（recordReferralActivation / _recordByReceipt / _grantMilestone）
- Test: `fittrack_flutter/test/invitation_service_test.dart`

**Interfaces:**
- Consumes: 现有 `ReferralMilestone` 枚举、`Storage.getSettings()`、`PointsService.addPoints`
- Produces: `class ReferralRecordOutcome { final bool success; final int totalReferrals; final int pointsEarned; final ReferralMilestone? milestone; }`；`Future<ReferralRecordOutcome> recordReferralActivation(String inviteeCode)` —— Task 3 的 `_recordReceipt` 依赖此签名

- [ ] **Step 1: 修改测试断言（先失败）**

在 `test/invitation_service_test.dart` 中做以下修改：

① 文件顶部无需新 import（`ReferralRecordOutcome` 与 service 同文件导出）。

② 测试「累计邀请 5 人应解锁限定皮肤 skin_ambassador」（约 61-86 行）中，循环与断言改为：

```dart
      ReferralRecordOutcome? lastOutcome;
      for (final code in codes) {
        lastOutcome = await InvitationService.instance.recordReferralActivation(code);
      }
      expect(lastOutcome!.success, true);
      expect(lastOutcome.milestone, ReferralMilestone.fiveActivations);
      expect(lastOutcome.pointsEarned, 600);
      expect(lastOutcome.totalReferrals, 5);
```

（原 `ReferralMilestone? lastMilestone;` 声明与 `expect(lastMilestone, ReferralMilestone.fiveActivations);` 删除）

③ 测试「邀请人累计积分应为 100+300+600=1000（前3档）」（约 88-101 行）循环内返回值未使用，无需改动。

④ 测试「达标识别码入账并发放首次里程碑」（约 207-222 行）改为：

```dart
    test('达标识别码入账并发放首次里程碑', () async {
      // 被邀请人（有训练）
      useDeviceId('invitee_loop_seed_1');
      insertValidTraining();
      final receipt = InvitationService.instance.generateActivationReceipt();

      // 邀请人
      useDeviceId('inviter_loop_main');
      final outcome =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(outcome.success, true);
      expect(outcome.milestone, ReferralMilestone.firstActivation);
      expect(outcome.pointsEarned, 100);
      expect(outcome.totalReferrals, 1);
      expect(PointsService.instance.points, 100);

      final myList = (Storage.getSettings()['myReferralCodes'] as List).cast<String>();
      expect(myList, contains(receipt));
    });
```

⑤ 测试「未达标识别码不入账」（约 224-236 行）中段改为：

```dart
      final outcome =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(outcome.success, false);
      expect(outcome.totalReferrals, 0);
      expect(PointsService.instance.points, 0);
```

（后续 `myReferralCodes` isEmpty 断言保留）

⑥ 测试「输入自己的识别码不入账（防自邀）」（约 238-249 行）中段改为：

```dart
      final outcome =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(outcome.success, false);
```

⑦ 测试「同一识别码重复入账被去重」（约 251-266 行）改为：

```dart
    test('同一识别码重复入账被去重', () async {
      useDeviceId('invitee_loop_seed_3');
      insertValidTraining();
      final receipt = InvitationService.instance.generateActivationReceipt();

      useDeviceId('inviter_loop_main4');
      final first =
          await InvitationService.instance.recordReferralActivation(receipt);
      final second =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(first.success, true);
      expect(second.success, false);
      expect(PointsService.instance.points, 100); // 只发一次
      expect(
        (Storage.getSettings()['myReferralCodes'] as List).length,
        1,
      );
    });
```

⑧ 在 group `'识别码入账闭环'` 末尾新增测试：

```dart
    test('第 2 次入账非里程碑档位：成功但 0 积分', () async {
      // 两个不同被邀请人的达标识别码
      useDeviceId('invitee_loop_seed_4');
      insertValidTraining();
      final receipt1 = InvitationService.instance.generateActivationReceipt();
      useDeviceId('invitee_loop_seed_5');
      insertValidTraining();
      final receipt2 = InvitationService.instance.generateActivationReceipt();

      useDeviceId('inviter_loop_main5');
      final first =
          await InvitationService.instance.recordReferralActivation(receipt1);
      expect(first.success, true);
      expect(first.pointsEarned, 100); // 第 1 人命中首档
      expect(first.totalReferrals, 1);

      final second =
          await InvitationService.instance.recordReferralActivation(receipt2);
      expect(second.success, true);
      expect(second.totalReferrals, 2);
      expect(second.pointsEarned, 0); // 第 2 人非里程碑档位
      expect(second.milestone, isNull);
      expect(PointsService.instance.points, 100); // 总积分不变
    });
```

- [ ] **Step 2: 运行测试验证失败**

```bash
flutter test test/invitation_service_test.dart
```

预期：编译错误 `The value of type 'ReferralMilestone?' can't be assigned...` / `ReferralRecordOutcome` 未定义（Result: FAIL）。

- [ ] **Step 3: 实现 ReferralRecordOutcome 并改造三个方法**

在 `lib/services/invitation_service.dart` 的 `ReceiptValidationResult` 类之后（约 61 行后）新增：

```dart
/// recordReferralActivation 结构化结果
class ReferralRecordOutcome {
  final bool success; // 是否成功入账（新识别码/邀请码）
  final int totalReferrals; // 入账后累计人数（失败时为当前累计值）
  final int pointsEarned; // 本次发放积分（非里程碑档位为 0）
  final ReferralMilestone? milestone; // 命中的里程碑（非档位为 null）

  const ReferralRecordOutcome({
    required this.success,
    required this.totalReferrals,
    this.pointsEarned = 0,
    this.milestone,
  });
}
```

将 `recordReferralActivation`（约 350 行起）、`_recordByReceipt`、`_grantMilestone` 三个方法整体替换为：

```dart
  /// 记录一次"被邀请人激活"事件（邀请人视角，本地层面）
  ///
  /// 入参支持两种格式：
  /// - `FIT-INV-` 邀请码：纯 HMAC 签名验证（历史路径）
  /// - `FIT-ACT-` 激活识别码：解密使用数据 → 达标判定（有效训练 ≥ 1）
  ///   → 防自邀（身份哈希 ≠ 当前用户）→ 去重 → 入账
  ///
  /// 返回结构化结果：入账是否成功、累计人数、本次积分、命中里程碑。
  Future<ReferralRecordOutcome> recordReferralActivation(String inviteeCode) async {
    final code = inviteeCode.trim().toUpperCase();
    if (code.startsWith('FIT-ACT-')) {
      return _recordByReceipt(code);
    }
    if (!_verifySignature(code)) return _currentOutcome();
    return _grantMilestone(code);
  }

  /// 识别码分支：达标 + 防自邀 + 去重后才入账
  Future<ReferralRecordOutcome> _recordByReceipt(String code) async {
    final validation = validateActivationReceipt(code);
    if (validation.result != ReceiptResult.validReached) {
      return _currentOutcome();
    }
    // 防自邀：识别码身份 = 当前用户身份
    if (validation.identity.isNotEmpty &&
        validation.identity == _computeMyIdentity()) {
      return _currentOutcome();
    }
    return _grantMilestone(code);
  }

  /// 失败分支：返回当前累计状态（success=false）
  ReferralRecordOutcome _currentOutcome() {
    final settings = Storage.getSettings();
    final myList = (settings['myReferralCodes'] as List?)?.cast<String>() ?? [];
    return ReferralRecordOutcome(
      success: false,
      totalReferrals: myList.length,
    );
  }

  /// 公共入账：写入 myReferralCodes（去重）+ 里程碑积分/徽章/皮肤发放
  Future<ReferralRecordOutcome> _grantMilestone(String code) async {
    final settings = Storage.getSettings();
    final myList = (settings['myReferralCodes'] as List?)?.cast<String>() ?? [];
    if (myList.contains(code)) {
      return ReferralRecordOutcome(
        success: false,
        totalReferrals: myList.length,
      );
    }
    myList.add(code);
    settings['myReferralCodes'] = myList;
    Storage.saveSettings(settings);
    // 通知数据变更：邀请进度已变化（非里程碑档位无积分入账，
    // 不会走 PointsService.addPoints 的通知路径，必须在此显式通知）
    Storage.dataChanged.value = !Storage.dataChanged.value;

    final count = myList.length;
    // 按里程碑发放积分（每达成新档位发放对应积分，不累加同档位）
    // 1 人 → +100, 3 人 → +300, 5 人 → +600, 10 人 → +1200
    int reward = 0;
    if (count == 1) {
      reward = 100;
    } else if (count == 3) {
      reward = 300;
    } else if (count == 5) {
      reward = 600;
    } else if (count == 10) {
      reward = 1200;
    }
    if (reward > 0) {
      await PointsService.instance.addPoints(reward, 'invite_milestone_$count');
    }

    if (count >= 1) _unlockBadge('referral_first');
    if (count >= 3) _unlockBadge('referral_three');
    if (count >= 5) {
      _unlockBadge('referral_five');
      _unlockOpponentSkin(); // 累计5人解锁限定皮肤
    }
    if (count >= 10) _unlockBadge('referral_ten');

    return ReferralRecordOutcome(
      success: true,
      totalReferrals: count,
      pointsEarned: reward,
      // 仅命中档位（1/3/5/10）时返回里程碑，非档位次数为 null
      milestone: reward > 0 ? _currentMilestone(count) : null,
    );
  }
```

注意：`_unlockOpponentSkin`、`_unlockBadge`、`_currentMilestone`、`getReferralProgress` 等其余方法保持不变。`lib/pages/invitation_page.dart` 的 `_recordReceipt` 此时会对 `ReferralRecordOutcome` 调用 `if (milestone != null)`——Task 3 修复；为保持本任务可编译，Task 1 结束前需将 `_recordReceipt` 中的临时兼容一并最小化处理：将

```dart
    final milestone =
        await InvitationService.instance.recordReferralActivation(code);
```

临时改为

```dart
    final outcome =
        await InvitationService.instance.recordReferralActivation(code);
    final milestone = outcome.milestone;
```

（后续逻辑 `if (milestone != null) {...}` 不动，Toast 分支化留给 Task 3。）

- [ ] **Step 4: 运行测试验证通过**

```bash
flutter test test/invitation_service_test.dart
```

预期：全部 PASS（含新增「第 2 次入账非里程碑档位」测试）。

- [ ] **Step 5: 静态检查**

```bash
flutter analyze lib/services/invitation_service.dart lib/pages/invitation_page.dart test/invitation_service_test.dart
```

预期：No issues found。

- [ ] **Step 6: Commit**

```bash
git add fittrack_flutter/lib/services/invitation_service.dart fittrack_flutter/lib/pages/invitation_page.dart fittrack_flutter/test/invitation_service_test.dart
git commit -m "feat: 邀请成果记录返回结构化 ReferralRecordOutcome（成功/累计/积分/里程碑）"
```

---

### Task 2: InvitationFlowDetailPage 流程详解页 + 路由 + 卡片入口

**Files:**
- Create: `fittrack_flutter/lib/pages/invitation_flow_detail_page.dart`
- Modify: `fittrack_flutter/lib/router.dart:39`（import）、`:378-382`（路由）
- Modify: `fittrack_flutter/lib/pages/invitation_page.dart:1-14`（import）、`:646-672`（_buildFlowCard）
- Test: `fittrack_flutter/test/invitation_flow_detail_page_test.dart`（新建）

**Interfaces:**
- Consumes: `PageHeader(title, subtitle, onBack)`、`CardWidget(child, onTap)`、`LiftTrackColors`
- Produces: `class InvitationFlowDetailPage extends StatelessWidget`（const 构造）；路由路径 `/invitation/flow`（Task 3 无依赖，仅页面跳转入口）

- [ ] **Step 1: 编写失败的平台渲染测试**

新建 `fittrack_flutter/test/invitation_flow_detail_page_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/themes/app_themes.dart';
import '../lib/pages/invitation_flow_detail_page.dart';

void main() {
  testWidgets('邀请流程详解页渲染双视角、奖励对照与规则说明', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme('vitality-sport'),
        home: const Scaffold(body: InvitationFlowDetailPage()),
      ),
    );
    await tester.pump();

    // 双视角区段
    expect(find.text('邀请人视角'), findsOneWidget);
    expect(find.text('被邀请人视角'), findsOneWidget);

    // 邀请人 6 步标题
    expect(find.text('分享邀请码'), findsOneWidget);
    expect(find.text('好友激活邀请码'), findsOneWidget);
    expect(find.text('好友完成首次训练'), findsOneWidget);
    expect(find.text('好友出示激活凭证'), findsOneWidget);
    expect(find.text('你确认记录成果'), findsOneWidget);
    expect(find.text('奖励自动到账'), findsOneWidget);

    // 被邀请人 4 步标题
    expect(find.text('获取好友邀请码'), findsOneWidget);
    expect(find.text('输入激活'), findsOneWidget);
    expect(find.text('完成首次训练'), findsOneWidget);
    expect(find.text('出示激活凭证'), findsOneWidget);

    // 奖励对照与规则说明
    expect(find.text('奖励对照'), findsOneWidget);
    expect(find.text('规则说明'), findsOneWidget);
    expect(find.text('累计邀请 5 人'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
flutter test test/invitation_flow_detail_page_test.dart
```

预期：编译错误 `invitation_flow_detail_page.dart` 不存在（Result: FAIL）。

- [ ] **Step 3: 创建 InvitationFlowDetailPage**

新建 `fittrack_flutter/lib/pages/invitation_flow_detail_page.dart`，完整内容：

```dart
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 邀请流程详解页面（双视角完整流程）
///
/// 依据：docs/superpowers/specs/2026-09-09-invitation-flow-detail-design.md
/// 从邀请页「邀请流程」卡片进入，展示从分享邀请码到双方获得全部奖励的
/// 完整链路：邀请人 6 步 + 被邀请人 4 步 + 奖励对照 + 规则说明。
class InvitationFlowDetailPage extends StatelessWidget {
  const InvitationFlowDetailPage({super.key});

  // 邀请人视角：完整 6 步
  static const List<_FlowStepData> _inviterSteps = [
    _FlowStepData(
      icon: Icons.share,
      title: '分享邀请码',
      desc: '复制邀请码或生成邀请海报，通过微信/QQ 发给好友。邀请码永久有效',
    ),
    _FlowStepData(
      icon: Icons.person_add,
      title: '好友激活邀请码',
      desc: '好友在「输入邀请码」中输入你的邀请码完成激活。一码一绑，激活后不可更换',
      reward: '好友 +50 积分',
    ),
    _FlowStepData(
      icon: Icons.fitness_center,
      title: '好友完成首次训练',
      desc: '好友完成至少 1 组动作的有效训练，训练数据将加密写入激活凭证',
    ),
    _FlowStepData(
      icon: Icons.qr_code_2,
      title: '好友出示激活凭证',
      desc: '好友在「我的激活凭证」生成 FIT-ACT 识别码发给你。凭证含加密签名的训练数据快照，可放心展示',
    ),
    _FlowStepData(
      icon: Icons.verified,
      title: '你确认记录成果',
      desc: '在「记录邀请成果」中扫码或输入好友的识别码，系统自动校验训练达标与防自邀',
    ),
    _FlowStepData(
      icon: Icons.card_giftcard,
      title: '奖励自动到账',
      desc: '按累计邀请档位自动发放积分、徽章与皮肤，无需手动领取',
      reward: '1/3/5/10 人档位：最高 1200 积分',
    ),
  ];

  // 被邀请人视角：4 步
  static const List<_FlowStepData> _inviteeSteps = [
    _FlowStepData(
      icon: Icons.redeem,
      title: '获取好友邀请码',
      desc: '向好友索取 FIT-INV-XXXXXX 格式的邀请码',
    ),
    _FlowStepData(
      icon: Icons.input,
      title: '输入激活',
      desc: '在「输入邀请码」中输入邀请码，激活后立即到账',
      reward: '你 +50 积分',
    ),
    _FlowStepData(
      icon: Icons.fitness_center,
      title: '完成首次训练',
      desc: '完成至少 1 组动作的有效训练，满足凭证达标条件',
    ),
    _FlowStepData(
      icon: Icons.qr_code_2,
      title: '出示激活凭证',
      desc: '生成 FIT-ACT 识别码发给邀请你的好友。好友确认后，双方奖励全部到账',
    ),
  ];

  // 奖励对照（与邀请页奖励规则档位一致）
  static const List<_RewardTierData> _rewardTiers = [
    _RewardTierData(count: 1, inviter: '100 积分 + 引路人徽章', invitee: '50 积分'),
    _RewardTierData(count: 3, inviter: '300 积分 + 布道者徽章', invitee: '50 积分'),
    _RewardTierData(count: 5, inviter: '600 积分 + 传道者徽章 + 限定对手皮肤', invitee: '50 积分'),
    _RewardTierData(count: 10, inviter: '1200 积分 + LiftTrack 大使称号', invitee: '50 积分'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: '邀请流程详解',
            subtitle: '从分享到双方获奖的完整链路',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineCard(colors, '邀请人视角', Icons.person, _inviterSteps),
                  const SizedBox(height: 16),
                  _buildTimelineCard(colors, '被邀请人视角', Icons.group, _inviteeSteps),
                  const SizedBox(height: 16),
                  _buildRewardTableCard(colors),
                  const SizedBox(height: 16),
                  _buildRulesCard(colors),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 视角时间线卡片（标题 + 竖向步骤）
  Widget _buildTimelineCard(
      LiftTrackColors colors, String title, IconData titleIcon, List<_FlowStepData> steps) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            return _buildTimelineItem(
                colors, entry.value, entry.key == steps.length - 1);
          }),
        ],
      ),
    );
  }

  /// 单个时间线节点（圆形图标 + 连接线 + 内容）
  Widget _buildTimelineItem(LiftTrackColors colors, _FlowStepData step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, color: colors.accentGlow, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: colors.borderColor),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.desc,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (step.reward != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.accentGlow.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
                      ),
                      child: Text(
                        step.reward!,
                        style: TextStyle(
                          color: colors.accentGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 奖励对照卡片：4 档 ×（邀请人 / 被邀请人）两列
  Widget _buildRewardTableCard(LiftTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '奖励对照',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._rewardTiers.map((t) => _buildRewardTierItem(colors, t)),
        ],
      ),
    );
  }

  Widget _buildRewardTierItem(LiftTrackColors colors, _RewardTierData t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${t.count}',
                    style: TextStyle(
                      color: colors.accentGlow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '累计邀请 ${t.count} 人',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('邀请人', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        t.inviter,
                        style: TextStyle(color: colors.textPrimary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('被邀请人', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        t.invitee,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 规则说明卡片
  Widget _buildRulesCard(LiftTrackColors colors) {
    const rules = [
      '邀请码永久有效，格式 FIT-INV-XXXXXX',
      '一码一绑：每位用户仅能激活一个邀请码，激活后不可更换',
      '防自邀：不能激活自己的邀请码或确认自己的凭证',
      '激活凭证每次生成均反映最新训练数据',
      '邀请奖励为档位制：累计 1/3/5/10 人时分别发放，非每人均有积分',
    ];
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '规则说明',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: colors.accentGlow, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _FlowStepData {
  final IconData icon;
  final String title;
  final String desc;
  final String? reward;

  const _FlowStepData({
    required this.icon,
    required this.title,
    required this.desc,
    this.reward,
  });
}

class _RewardTierData {
  final int count;
  final String inviter;
  final String invitee;

  const _RewardTierData({
    required this.count,
    required this.inviter,
    required this.invitee,
  });
}
```

- [ ] **Step 4: 注册路由**

`fittrack_flutter/lib/router.dart`：

① 在 `import 'pages/invitation_page.dart';`（39 行）后新增：

```dart
import 'pages/invitation_flow_detail_page.dart';
```

② 在 `/invitation` 路由（378-382 行）后新增：

```dart
      GoRoute(
        path: '/invitation/flow',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const InvitationFlowDetailPage(),
      ),
```

- [ ] **Step 5: 流程卡片接入点击入口**

`fittrack_flutter/lib/pages/invitation_page.dart`：

① 文件顶部 `import 'package:flutter/services.dart';` 后新增：

```dart
import 'package:go_router/go_router.dart';
```

② `_buildFlowCard` 中 `return CardWidget(` 改为：

```dart
    return CardWidget(
      onTap: () => context.push('/invitation/flow'),
      child: Column(
```

③ 标题 Row（`Text('邀请流程', ...)` 之后、Row 结束前）追加尾部入口提示：

```dart
              Text(
                '邀请流程',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '查看详情',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              Icon(Icons.chevron_right, color: colors.textMuted, size: 16),
```

- [ ] **Step 6: 运行测试验证通过**

```bash
flutter test test/invitation_flow_detail_page_test.dart
```

预期：PASS（渲染无布局溢出异常，双视角与奖励对照断言全部命中）。

- [ ] **Step 7: 静态检查**

```bash
flutter analyze lib/pages/invitation_flow_detail_page.dart lib/router.dart lib/pages/invitation_page.dart test/invitation_flow_detail_page_test.dart
```

预期：No issues found。

- [ ] **Step 8: Commit**

```bash
git add fittrack_flutter/lib/pages/invitation_flow_detail_page.dart fittrack_flutter/lib/router.dart fittrack_flutter/lib/pages/invitation_page.dart fittrack_flutter/test/invitation_flow_detail_page_test.dart
git commit -m "feat: 邀请流程卡片新增流程详解详情页（双视角完整链路）"
```

---

### Task 3: 记录成果 Toast 分支提示 + 积分明细邀请标签/筛选修复

**Files:**
- Modify: `fittrack_flutter/lib/pages/invitation_page.dart:944-960`（_recordReceipt）
- Modify: `fittrack_flutter/lib/pages/points_detail_page.dart:51-68`（_matchSource）、`:75-120`（_sourceLabel）、`:147-171`（_sourceIcon）
- Test: `fittrack_flutter/test/points_detail_page_test.dart`（新建）

**Interfaces:**
- Consumes: Task 1 的 `ReferralRecordOutcome`（`success` / `pointsEarned` / `totalReferrals` 字段）
- Produces: 无对外新接口（页面内私有方法修复）

- [ ] **Step 1: 编写失败的积分明细测试**

新建 `fittrack_flutter/test/points_detail_page_test.dart`：

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/data/storage.dart';
import '../lib/themes/app_themes.dart';
import '../lib/pages/points_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Storage.getSettings 依赖 SQLite，测试环境需初始化 ffi databaseFactory
  // （与 invitation_service_test.dart 等项目测试保持一致）
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Future<void> pumpPage(WidgetTester tester) async {
    // 页面回调使用 go_router（context.push/pop），用最小路由包装
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PointsDetailPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.getTheme('vitality-sport'),
      ),
    );
    await tester.pump();
  }

  testWidgets('邀请里程碑与被邀请奖励显示友好标签', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.clearAll();
    Storage.saveSettings(<String, dynamic>{});
    await Storage.init();

    final now = DateTime.now().millisecondsSinceEpoch;
    final settings = Storage.getSettings();
    settings['pointsLog'] = jsonEncode([
      {'time': now, 'delta': 300, 'source': 'invite_milestone_3', 'balance': 400},
      {'time': now, 'delta': 50, 'source': 'invited', 'balance': 100},
    ]);
    Storage.saveSettings(settings);

    await pumpPage(tester);

    // 修复前：invite_milestone_3 显示原始字符串
    expect(find.text('邀请里程碑（第 3 人）'), findsOneWidget);
    // invited 显示为「邀请好友」（积分获取途径区段也含同名文案，≥2 处）
    expect(find.text('邀请好友'), findsWidgets);
  });

  testWidgets('「邀请」筛选器匹配 invited 与 invite_milestone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.clearAll();
    Storage.saveSettings(<String, dynamic>{});
    await Storage.init();

    final now = DateTime.now().millisecondsSinceEpoch;
    final settings = Storage.getSettings();
    settings['pointsLog'] = jsonEncode([
      {'time': now, 'delta': 300, 'source': 'invite_milestone_3', 'balance': 400},
      {'time': now, 'delta': 50, 'source': 'invited', 'balance': 100},
      {'time': now, 'delta': 10, 'source': 'checkIn', 'balance': 10},
    ]);
    Storage.saveSettings(settings);

    await pumpPage(tester);

    // 切换到「邀请」筛选
    await tester.tap(find.text('邀请'));
    await tester.pump();

    // 修复前：invite 分支不匹配 invited/invite_milestone_* → 空列表
    expect(find.text('暂无该类型记录'), findsNothing);
    expect(find.text('邀请里程碑（第 3 人）'), findsOneWidget);
    expect(find.text('邀请好友'), findsWidgets);
    // checkIn 条目被过滤（「每日签到」仅剩积分获取途径区段的同名文案 1 处）
    expect(find.text('每日签到'), findsOneWidget);
  });
}
```

注意「每日签到」断言：积分获取途径区段固定渲染 1 处「每日签到」（`_buildWayItem`），修复前筛选「邀请」后列表中的签到条目也消失 → 命中 1 处；若筛选失效未过滤 checkIn → 命中 2 处，断言失败。

- [ ] **Step 2: 运行测试验证失败**

```bash
flutter test test/points_detail_page_test.dart
```

预期：第 1 个测试 FAIL（找不到 `邀请里程碑（第 3 人）`，实际渲染原始字符串 `invite_milestone_3`）；第 2 个测试 FAIL（`暂无该类型记录` 出现或「每日签到」命中 2 处）。

- [ ] **Step 3: 修复积分明细标签/筛选/图标**

`fittrack_flutter/lib/pages/points_detail_page.dart`：

① `_matchSource` 的 invite 分支（约 56-58 行）：

```dart
      case 'invite':
        return source == 'invite' ||
            source == 'invited' ||
            source.startsWith('invite_milestone_');
```

② `_sourceLabel`：在 `if (map.containsKey(source)) return map[source]!;` 之后、`if (source.startsWith('unlock_plan_'))` 之前插入：

```dart
    // 邀请里程碑：invite_milestone_<N> → 友好标签
    if (source.startsWith('invite_milestone_')) {
      final n = source.substring('invite_milestone_'.length);
      return '邀请里程碑（第 $n 人）';
    }
```

③ `_sourceIcon` 的收入 switch（约 147-168 行）中，`case 'invite':` 改为：

```dart
        case 'invite':
        case 'invited':
          return Icons.card_giftcard;
```

并在 switch 之前（`if (isIncome) {` 之后、`switch (source) {` 之前）插入里程碑前缀处理：

```dart
    if (isIncome) {
      // 邀请里程碑与邀请奖励共用图标
      if (source.startsWith('invite_milestone_')) {
        return Icons.card_giftcard;
      }
      switch (source) {
```

- [ ] **Step 4: 修复 _recordReceipt Toast 分支**

`fittrack_flutter/lib/pages/invitation_page.dart` 的 `_recordReceipt`（约 944-960 行，注意 Task 1 已将头部改为 `final outcome = ...; final milestone = outcome.milestone;` 的临时形态）整体替换为：

```dart
  Future<void> _recordReceipt() async {
    final code = _receiptController.text.trim().toUpperCase();
    setState(() => _recording = true);
    final outcome =
        await InvitationService.instance.recordReferralActivation(code);
    if (!mounted) return;
    setState(() => _recording = false);

    if (outcome.success) {
      if (outcome.pointsEarned > 0) {
        FitToast.success(context, '记录成功！+${outcome.pointsEarned} 积分已到账');
      } else {
        FitToast.success(
            context, '记录成功！已累计邀请 ${outcome.totalReferrals} 人');
      }
      _receiptController.clear();
      setState(() => _receiptValidation = null);
      _loadData();
    } else {
      FitToast.error(context, '记录失败：识别码无效、未达标或已记录过');
    }
  }
```

- [ ] **Step 5: 运行测试验证通过**

```bash
flutter test test/points_detail_page_test.dart
flutter test test/invitation_service_test.dart
```

预期：全部 PASS。

- [ ] **Step 6: 全量回归 + 静态检查**

```bash
flutter test
flutter analyze lib/pages/points_detail_page.dart lib/pages/invitation_page.dart test/points_detail_page_test.dart
```

预期：全部测试 PASS（注意：本仓库历史测试基线如有与本任务无关的既有失败，记录失败清单并确认不含本任务涉及文件）；analyze No issues found。

- [ ] **Step 7: 手动验证清单（模拟器）**

- 邀请页 →「邀请流程」卡片点击 → 进入 `/invitation/flow` 详情页，双视角时间线、奖励对照、规则说明渲染正常
- 详情页返回按钮回邀请页
- 「记录邀请成果」录入第 2 个有效识别码 → Toast 显示「记录成功！已累计邀请 2 人」
- 积分明细页 → 筛选「邀请」→ 里程碑与被邀请奖励条目可见且显示友好标签

- [ ] **Step 8: Commit**

```bash
git add fittrack_flutter/lib/pages/invitation_page.dart fittrack_flutter/lib/pages/points_detail_page.dart fittrack_flutter/test/points_detail_page_test.dart
git commit -m "fix: 邀请成果 Toast 按档位分支提示，积分明细补齐邀请里程碑标签与筛选"
```

---

## Self-Review 结论

1. **Spec 覆盖**：详情页双视角 6+4 步（Task 2）、奖励对照（Task 2）、规则说明（Task 2）、卡片入口（Task 2 Step 5）、结构化返回值与 Toast 分支（Task 1 + Task 3 Step 4）、积分明细标签/筛选（Task 3 Step 3）——全部覆盖。
2. **占位符扫描**：所有步骤含完整代码/命令，无 TBD。
3. **类型一致性**：`ReferralRecordOutcome` 字段名（success/totalReferrals/pointsEarned/milestone）在 Task 1 定义、Task 3 消费处一致；`recordReferralActivation` 返回类型两任务一致；`InvitationFlowDetailPage` 类名/路由路径在 Task 2 内部一致。

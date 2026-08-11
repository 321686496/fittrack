# 激活识别码（FIT-ACT）验证闭环设计

- **作者**：AI 协作
- **日期**：2026-08-11
- **状态**：Draft
- **覆盖**：修复 v1 教学裂变体系「邀请人侧激励永远无法触发」的闭环断点——新增被邀请人「激活识别码」（含使用数据、加密签名），邀请人输入校验达标后入账里程碑奖励

---

## 1. 背景

v1 教学裂变体系（[01_迭代方案.md](../../versions/v1-获客留存版/01_迭代方案.md) §2.3）已实现：

- 邀请码生成 `FIT-INV-XXXXXX`（HMAC 本地验证）
- 被邀请人激活 → +50 积分（一码一绑 `activatedInvitationCode`）
- 邀请人里程碑激励逻辑 `recordReferralActivation()`（100/300/600/1200 分 + 徽章 + 大使皮肤），但**全项目无任何 UI/调用方**，`myReferralCodes` 永远为空

闭环断点分析：

1. **邀请人侧激励断点（致命）**：设计文档写明「邀请人主动输入被邀请人激活的码（反向验证）」，但入口从未实现。直接后果：里程碑积分/徽章/皮肤永远拿不到；专题教学包（≥3 人解锁）被永久锁死。
2. **deeplink 拉起断点**：`fittrack://invite?code=XXX` 走通原生层后 `go('/home?inviteCode=$code')`，但 `/home` 路由 builder 不读取 `inviteCode`，码被丢弃（本设计不覆盖，另立任务）。

本设计解决断点 1，并按用户要求将「反向验证」升级为**带使用数据的加密签名识别码**：

- 被邀请人激活后，app 生成「激活识别码」，内含有效训练次数、训练总时长等使用数据
- 识别码加密与签名处理，保证数据安全性与真实性
- 邀请人在 app 中输入识别码，app 解密校验数据，判断被邀请人是否真实使用过 app（防止刷量）
- 绑定约束：**一个用户只能绑定一个邀请码**（已有），**一个邀请码可被多个用户绑定**（已有）

## 2. 设计目标

- 邀请人侧可验证被邀请人「确实激活并完成首次训练」，而非纯凭口头/伪造码
- 识别码携带使用数据（有效训练次数、训练总时长），防刷量
- 识别码加密 + HMAC 签名，防篡改、防伪造
- 复用现有里程碑/去重/一码一绑机制，最小侵入

## 3. 识别码格式（方案 A：定长 Base32 紧凑码）

```
FIT-ACT-XXXXXXXXXX-XXXXXXX
```

格式：`FIT-ACT-` 前缀 + **17 位** Base32 紧凑码，总长 24 字符（不含分隔）。

| 段 | 位数 | 位宽 | 内容 | 编码范围 |
|---|---|---|---|---|
| 身份哈希 | 4 | 20 bit | 与邀请码同源的 deviceId HMAC 前 4 位 | Base32 字母 |
| 有效训练次数 | 3 | 15 bit | 有效训练记录数 | 0–32767 |
| 训练总时长 | 4 | 20 bit | 有效训练时长总和（分钟） | 0–1048575 |
| 激活天数 | 2 | 10 bit | 自激活起的自然天数 | 0–1023 |
| HMAC 签名 | 4 | 20 bit | 覆盖上述全部明文段 | Base32 字母 |

- Base32 字母表：复用邀请码的 `23456789ABCDEFGHJKLMNPQRSTUVWXYZ`（去除易混淆字符 0/O/1/I）
- 数字段采用定长 Base32 数字编码（大端序），解码可还原数据供展示与达标判定
- HMAC-SHA256 独立密钥：`fitTrack_receipt_secret_v1_2026`（与邀请码 `fitTrack_invitation_secret_v1_2026`、兑换码、分享码完全隔离）
- 签名段 = HMAC(身份‖次数‖时长‖天数) 取前 4 字节 mod 32 映射

**兼容性**：`FIT-ACT-` 前缀与 `FIT-INV-`、`FITT-` 互不冲突，各自正则独立。

## 4. 数据来源与达标判定

### 4.1 有效训练定义

从 `Storage.getRecords()` 统计 **`totalSets > 0`** 的记录（即实际完成了训练组的训练）。排除跨天未完成的空记录（`_autoSaveAsIncomplete` 落库时 `totalSets` 可能为 0）。

- **有效训练次数** = `totalSets > 0` 的记录数
- **训练总时长（分钟）** = 上述记录的 `duration` 字段求和

### 4.2 达标判定（邀请人侧）

**有效训练次数 ≥ 1** 即视为「激活 + 首次训练」成功，允许记录为一次有效邀请。

未达标（次数 = 0）时提示「好友尚未完成首次训练」，不记录、不发奖。

## 5. 双端交互流程

### 5.1 被邀请人侧（生成）

入口：邀请页（`InvitationPage`）激活成功后新增「生成我的激活凭证」卡片/按钮。

流程：

1. 点击「生成我的激活凭证」
2. 动态抓取最新数据快照：身份哈希（`_computeMyIdentity`）+ 有效训练次数 + 训练总时长 + 激活天数
3. 编码 + 签名 → 生成 `FIT-ACT-` 识别码
4. 弹窗展示识别码（大号 SelectableText）+「一键复制」按钮 + 说明文案（"将此码发给邀请你的好友，好友确认后双方得奖励"）
5. 每次点击均重新生成（动态快照，反映最新训练数据）

### 5.2 邀请人侧（输入验证）

入口：邀请页新增「记录邀请成果」输入区（与「输入邀请码」区并列，区分两个输入框用途）。

流程：

1. 输入识别码（`FIT-ACT-` 格式）
2. 格式校验 → 签名校验 → 解密出数据
3. 展示校验结果卡片：「该好友已训练 N 次、总时长 M 分钟、激活 X 天」
4. 达标（次数 ≥ 1）→ 显示「确认记录」按钮 → 入账（去重 + 里程碑发奖）→ 成功提示
5. 未达标 → 显示「好友尚未完成首次训练」，记录按钮禁用
6. 签名无效/格式错误 → 明确报错提示

## 6. 服务接口变更（`lib/services/invitation_service.dart`）

| 接口 | 类型 | 说明 |
|---|---|---|
| `String generateActivationReceipt()` | 新增 | 被邀请人侧生成识别码（动态快照） |
| `ReceiptValidationResult validateActivationReceipt(String code)` | 新增 | 邀请人侧校验：格式/签名/解密/达标判定 |
| `Future<ReferralMilestone?> recordReferralActivation(String inviteeCode)` | 增强 | 支持识别码入账：仅达标（次数≥1）才记录；纯签名路径保留 |

新增数据结构：

```dart
enum ReceiptResult {
  validReached,      // 校验通过且达标（训练次数 ≥ 1）
  validNotReached,   // 校验通过但未达标（次数 = 0）
  invalidFormat,
  invalidSignature,
}

class ReceiptValidationResult {
  final ReceiptResult result;
  final int trainingCount;     // 有效训练次数
  final int totalDurationMin;  // 训练总时长（分钟）
  final int daysSinceActivation;
}
```

`recordReferralActivation` 入账逻辑（识别码分支）：

1. 解密识别码 → 若签名无效直接返回 null
2. **防自邀**：识别码身份哈希 = 当前用户 `_computeMyIdentity()` → 不记录，返回 null（现有方法无自邀检查，识别码分支必须显式比对）
3. 若训练次数 < 1 → 不记录，返回 null
4. 去重：`myReferralCodes` 已含该码 → 返回 null
5. 写入 + 里程碑发放（与现有逻辑一致）

## 7. 安全与防重放

- **防篡改**：HMAC 签名覆盖全部明文数据段，改任意一位签名即失效
- **防伪造**：密钥独立硬编码（Phase 2 本地架构可接受，Phase 3 服务器下发时移除，与邀请码密钥处理一致）
- **隐私**：码内不含 deviceId 明文，仅身份哈希（20 bit），不可逆推设备
- **一用户一码**：`activatedInvitationCode` 已有，被邀请人只能激活一次
- **一码多人**：`myReferralCodes` 列表已有，一个邀请码可被多个用户绑定
- **同码重放**：同一识别码在 `myReferralCodes` 中已存在时拒绝，避免重复入账
- **单机版损耗**：无法全局防止同一识别码被多个邀请人各自记录（无服务器），接受损耗（[01_迭代方案.md](../../versions/v1-获客留存版/01_迭代方案.md) §2.3 已声明联网版根治）

## 8. 页面/UI 变更（`lib/pages/invitation_page.dart`）

1. 激活成功后新增「生成我的激活凭证」入口（含已激活识别码展示 + 复制）
2. 新增「记录邀请成果」输入区（`FIT-ACT-` 识别码输入 + 校验结果卡片 + 确认记录按钮）
3. 校验结果卡片复用现有 `CardWidget` / `FitToast` / 主题色，不新增自定义颜色

## 9. 测试

更新 `test/invitation_service_test.dart`：

- 编码/解码往返：生成 → 校验 → 数据一致
- 签名篡改：改任意数据位 → `invalidSignature`
- 达标判定：次数 0 → `validNotReached`；次数 ≥ 1 → `validReached`
- 格式错误：非 `FIT-ACT-` → `invalidFormat`
- 去重：同一识别码两次入账，第二次返回 null
- 防自邀兼容：识别码身份 = 当前用户身份 → 不记录（复用现有 selfInvite 逻辑）

## 10. 范围边界（不在本设计内）

- deeplink `fittrack://invite` 丢码问题（`/home` 路由不读 `inviteCode`）——另立任务
- 剪贴板一键激活横幅——已可用，不改
- 服务器端防刷量（多设备/多邀请人全局去重）——Phase 3 联网版

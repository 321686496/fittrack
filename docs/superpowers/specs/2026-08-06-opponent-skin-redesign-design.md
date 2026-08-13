# 对手皮肤系统 方案A 重新设计（训练哲学系列）

- **作者**：AI 协作
- **日期**：2026-08-06
- **状态**：Implemented
- **覆盖**：将原 4 个皮肤（健身小白/钢铁战士/赛博忍者/燃力大使）重新设计为「训练哲学系列」（晨光起步者/熔铁匠人/风行游侠/传承导师），并用 Seedream 重新生成全部 12 张精灵素材

---

## 1. 背景

原皮肤系统已实现完整的渲染管线（CustomPainter + 贴图合成 + 动作动画），见 [2026-07-27-opponent-skin-system-design.md](2026-07-27-opponent-skin-system-design.md)。本次仅替换皮肤主题/命名/配色/文案/精灵素材，**保留皮肤 ID 与渲染管线不变**，确保已购用户存档兼容。

## 2. 设计目标

- 用「训练哲学」主题替代原有的角色扮演主题，更贴合健身 App 语境
- 4 档皮肤具备 Morandi 友好的柔和高级配色
- 招式名称与训练偏好天然映射（孤立动作→晨光弯举 / 复合动作→熔炉深蹲 / 有氧→疾风连斩 / 均衡→传承裁决）
- 工程层面：仅替换配置数据与 PNG 素材，不改核心类与渲染逻辑

## 3. 工具限制说明

| 工具 | 状态 | 备注 |
|---|---|---|
| Seedream (GenerateImage) | ✅ 可用 | 输出 1920×1920 JPG，需后处理抠图 |
| Seedance (GenerateVideo) | ❌ 工具集中不可用 | 本会话无法调用，视频生成待后续手动执行 |

由于 Seedream 输出 JPG（无 alpha 通道），采用「纯色键背景 + Python 色键抠图」方案：
1. 生成时在 prompt 中要求纯色背景（实测为红/玫红/洋红系，非纯 #FF00FF）
2. 用 [scripts/cutout_opponent_sprites.py](../../../scripts/cutout_opponent_sprites.py) 做 chroma key 抠图
3. 算法：四角采样取中位数背景色 → 按到背景色的欧氏距离生成软过渡 alpha → 半透明边缘反预乘去污 + 邻近去饱和 → alpha 轻微腐蚀去红边
4. 输出 512×512 RGBA PNG，覆盖旧素材（旧素材自动备份至 `_backup_old/`）

## 4. 4 个皮肤的新设定

### 4.1 skin_beginner → 晨光起步者

| 字段 | 旧值 | 新值 |
|---|---|---|
| 名称 | 健身小白 | 晨光起步者 |
| 主题 | 入门萌系 | 晨光初现的起步者 |
| 配色 primary | #FFB87A 浅橙 | #A8D8B9 薄荷绿 |
| 配色 secondary | #FFE3C2 | #F5EBDC 米白 |
| 配色 accent | #FF6B35 亮橙 | #E8956D 暖橙点缀 |
| 光圈色 | #FF8C5A 暖橙 | #B5D8C2 柔和薄荷 |
| 招式 | 活力弯举 | 晨光弯举 |
| 徽章 emoji | 🐣 | 🌱 |
| 训练偏好 | 孤立 0.5（保持） | 孤立 0.5（保持） |
| 文案风格 | 鼓励型（保持调性） | 晨光鼓励型：「晨光初现，一起开始吧！」 |

### 4.2 skin_iron_warrior → 熔铁匠人

| 字段 | 旧值 | 新值 |
|---|---|---|
| 名称 | 钢铁战士 | 熔铁匠人 |
| 主题 | 力量派战士 | 熔炉淬炼的匠人 |
| 配色 primary | #9B2C2C 深红 | #4A5568 石墨灰 |
| 配色 secondary | #4A5568 | #2D3748 深炭黑 |
| 配色 accent | #F56565 亮红 | #C05621 熔岩橙（深） |
| 光圈色 | #FF4E50 火红 | #FF6B35 熔岩橙（亮） |
| 招式 | 裂地深蹲 | 熔炉深蹲 |
| 徽章 emoji | 🤖 | ⚒ |
| 训练偏好 | 复合 0.6（保持） | 复合 0.6（保持） |
| 文案风格 | 力量派（保持调性） | 匠人淬炼型：「炉火已起，开工」 |

### 4.3 skin_cyber_ninja → 风行游侠

| 字段 | 旧值 | 新值 |
|---|---|---|
| 名称 | 赛博忍者 | 风行游侠 |
| 主题 | 赛博朋克忍者 | 风中行走的游侠 |
| 配色 primary | #9B5DE5 霓虹紫 | #7BA7BC 青瓷蓝 |
| 配色 secondary | #00F5FF 霓虹青 | #D4DCE1 银白 |
| 配色 accent | #F15BB5 粉 | #5A6B7C 月灰 |
| 光圈色 | #9B5DE5 紫 | #7BA7BC 青瓷蓝 |
| 招式 | 闪影连斩 | 疾风连斩 |
| 徽章 emoji | 🥷 | 🍃 |
| 训练偏好 | 有氧 0.5（保持） | 有氧 0.5（保持） |
| 文案风格 | 神秘型（保持调性） | 风行冷静型：「风起，行动」 |

### 4.4 skin_ambassador → 传承导师（限定款）

| 字段 | 旧值 | 新值 |
|---|---|---|
| 名称 | 燃力大使 | 传承导师 |
| 主题 | 黑金奢华王者 | 传承衣钵的导师 |
| 配色 primary | #1A1A1A 黑 | #3D4F3F 墨绿 |
| 配色 secondary | #FFD700 金 | #B08D57 古铜金 |
| 配色 accent | #FFA500 橙 | #D8C9A6 米色 |
| 光圈色 | #FFD700 金 | #B08D57 古铜金 |
| 招式 | 王者裁决 | 传承裁决 |
| 徽章 emoji | 👑 | 📜 |
| 训练偏好 | 均衡（保持） | 均衡（保持） |
| 文案风格 | 王者型 | 导师传承型：「后生可畏，共勉之」 |

## 5. 素材清单（12 张 PNG，512×512 RGBA）

```
fittrack_flutter/assets/opponent/
├── face_beginner.png       # 晨光起步者面部（薄荷绿发带）
├── face_iron.png           # 熔铁匠人面部（炭灰发，forge soot）
├── face_ninja.png          # 风行游侠面部（青瓷蓝兜帽+银面具）
├── face_ambassador.png     # 传承导师面部（墨绿导师帽+白须）
├── outfit_beginner.png     # 薄荷绿短袖+米白慢跑裤+暖橙运动鞋
├── outfit_iron.png         # 石墨灰背心+深棕举重腰带+熔岩橙训练裤
├── outfit_ninja.png        # 青瓷蓝游侠束腰+银护臂+月灰围巾
├── outfit_ambassador.png   # 墨绿导师长袍+古铜金边+米色内层
├── prop_beginner.png       # 小哑铃（薄荷绿柄+米白配重）
├── prop_iron.png           # 20kg 杠铃（石墨灰杆+熔岩橙配重片）
├── prop_ninja.png          # 双匕首（银蓝刃+青瓷蓝缠柄）
├── prop_ambassador.png     # 导师杖（青铜杖身+顶端绿宝石）
└── _backup_old/            # 旧素材自动备份（12 张原 PNG）
```

## 6. 抠图处理流程

1. **生成阶段**：Seedream 生成 1920×1920 JPG，背景为纯色（红/玫红/洋红系）
   - prompt 显式要求 "solid pure magenta (#FF00FF) flat fill, fully saturated, no gradient, no texture - chroma key background for cutout"
   - 实测背景像素 R∈[199,254], G∈[16,100], B∈[84,233]，有渐变但均在红/玫红/洋红色域
2. **抠图阶段**：[scripts/cutout_opponent_sprites.py](../../../scripts/cutout_opponent_scripts.py) 用 numpy+Pillow 处理
   - 四角区域取中位数颜色作为背景色（每张独立检测，抗渐变/色偏）
   - 按到背景色的欧氏距离生成 alpha：容差内全透明，容差-羽化带线性过渡
   - 半透明边缘反预乘恢复前景色（覆盖率足够时），低覆盖率像素完全去饱和
   - 完全不透明但贴近背景的像素按距离去饱和（清除残余红色描边）
   - alpha 做 1-2 像素腐蚀，彻底移除最外圈背景残留
   - LANCZOS 重采样至 512×512
3. **验证**：12 张 PNG 透明占比 70-93%（面部 70-83% / 服饰 76-86% / 道具 82-93%），边界品红残留率从 30-60% 降至约 0%，符合预期

## 7. 代码改动清单

| 文件 | 改动 |
|---|---|
| [opponent_skin_config.dart](../../../fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart) | 4 个皮肤的 name/palette/dialogStyle/signatureMove/cardTheme 全部更新 |
| [virtual_goods.dart](../../../fittrack_flutter/lib/data/virtual_goods.dart) | 4 个皮肤的 name/emoji 更新 |
| [invitation_page.dart](../../../fittrack_flutter/lib/pages/invitation_page.dart) | 第 565 行硬编码「燃力大使」→「传承导师」 |
| [opponent_skin_config_test.dart](../../../fittrack_flutter/test/opponent_skin_config_test.dart) | 4 个皮肤名称断言更新 |
| [virtual_goods_test.dart](../../../fittrack_flutter/test/virtual_goods_test.dart) | skin_iron_warrior 名称断言更新 |
| [scripts/cutout_opponent_sprites.py](../../../scripts/cutout_opponent_sprites.py) | 新增色键抠图脚本 |
| fittrack_flutter/assets/opponent/*.png | 12 张 PNG 替换（旧素材备份在 `_backup_old/`） |
| fittrack_flutter/assets/opponent/_gen/*.jpg | 12 张 Seedream 原始生成 JPG（保留作为重抠图源） |

## 8. 未改动项（明确保留）

- 皮肤 ID（`skin_beginner/iron_warrior/cyber_ninja/ambassador`）不变 → 已购用户存档兼容
- 渲染管线（OpponentRenderer / 4 个 Painter / MotionSpec）不变
- 训练偏好权重（compound/isolation/cardio/core）不变 → dailyAdvance 行为不变
- 动作动画帧（idleMotion / trainingMotion）不变
- 价格与解锁条件不变（100/300/600 积分 + 邀请 5 人解锁）
- 邀请页「燃力大使称号」（title_ambassador）不变 → 这是称号不是皮肤

## 9. 验证结果

- ✅ `flutter analyze` 13 个 issue 全部为 info 级别 lint 提示（const 优化），无新增 error
- ✅ `flutter test test/opponent_skin_config_test.dart test/virtual_goods_test.dart` 14 个测试全部通过
- ✅ 12 张 PNG 抠图成功，透明占比合理
- ✅ 旧素材已备份至 `_backup_old/`

## 10. 待办（视频生成）

Seedance 视频生成本会话不可用（GenerateVideo 工具未在工具集中）。建议后续手动执行：
1. 为 4 个皮肤各生成 3-5 秒展示视频（待机+训练动作循环）
2. 视频可作为详情页「皮肤预览」或商店页轮播素材
3. 视频内容建议：Q 版角色在 Morandi 色背景中执行 signatureMove，配合对应光圈色脉动

## 11. 回滚方案

如需回滚至旧皮肤：
1. 恢复 `fittrack_flutter/assets/opponent/_backup_old/*.png` 至 `opponent/` 目录
2. `git checkout HEAD~1 -- fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart fittrack_flutter/lib/data/virtual_goods.dart`
3. 删除 `scripts/cutout_opponent_sprites.py` 与 `_gen/` 目录

# 计划导入导出优化 + 音效系统 设计文档

> 日期：2026-07-23
> 状态：已确认，转入实现

## 一、导入内容缺失 Bug 修复

### 根因

1. `attachAuthorSignature` 返回值被丢弃（share_code_page.dart:249）
2. 浅拷贝导致嵌套结构共享引用
3. 导入时 `currentDayIndex` 未重置为 0
4. JSON 反序列化后类型未归一化（`List<dynamic>` vs `List<Map<String, dynamic>>`，`int` vs `double`）

### 修复

- **导出侧**：修复 `attachAuthorSignature` 赋值；移除 `currentDayIndex`
- **导入侧**：深拷贝 + 类型归一化；重置 `currentDayIndex=0`、`progress=0`、`status='active'`
- **服务层**：新增 `deepNormalizePlan()` 递归归一化嵌套类型

## 二、计划页快捷分享 + 二维码 + 扫码导入

### 计划页快捷分享按钮

plan_page.dart 每个计划卡片右侧添加分享图标，点击弹出底部菜单：
- 生成分享码 → 跳转 ShareCodePage 并预选
- 生成二维码 → 跳转 PlanQrCodePage
- 生成海报 → 跳转 PlanPosterPage

### 二维码导出（PlanQrCodePage）

- 使用 `qr_flutter` 依赖生成二维码
- 二维码内容 = `FITT-XXXXXX|base64(json)` 分享串
- 对大计划做 gzip 压缩，超限则提示用文本分享
- 展示二维码 + 分享码文本 + 复制/保存按钮

### 扫码导入（ScanImportPage）

- 新增 `mobile_scanner` 依赖
- 扫码结果传入 `ShareCodeService.importFromString()` 复用导入逻辑
- 入口：ShareCodePage 导入区 + plan_page 顶部

## 三、海报式计划导出

### PlanPosterWidget

- 尺寸 1080×1920，复用 PosterGenerator + PosterPreviewDialog 体系
- 布局：顶部计划信息 + 中部训练日列表（含休息日样式）+ 底部二维码+分享码
- 入口：plan_page 快捷菜单 + ShareCodePage 生成结果区

## 四、音效系统

### 依赖

`audioplayers: ^5.0.0`（三端支持），备选 SystemSound + MethodChannel

### 音效素材（8 个，合成生成）

| 文件 | 场景 |
|------|------|
| complete_set.mp3 | 完成一组 |
| complete_training.mp3 | 训练完成 |
| rest_start.mp3 | 休息开始 |
| rest_end.mp3 | 休息结束 |
| tick.mp3 | 倒计时最后3秒 |
| achievement.mp3 | 成就解锁 |
| points.mp3 | 积分增加 |
| button_tap.mp3 | 按钮点击 |

### SoundService

- 单例，init() 预加载，play(SoundType) 播放
- setEnabled(bool) 开关，持久化到 settings['soundEnabled']
- 集成到 training_page、rest_notification_service、achievement_service、points_service

### 设置页

新增"音效开关"项，与"振动开关"并列

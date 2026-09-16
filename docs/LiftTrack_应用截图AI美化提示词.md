# LiftTrack 应用截图 · AI 美化提示词说明（真实截图版）

> 用途：你提供 **8 张真实 App 截图**（`assets/1.png ~ 8.png`），把本文件对应的**单张提示词**连同该真实截图一起喂给 AI 图像工具（Seedream / 即梦 / 可图 / Midjourney 等）。
> **核心原则：AI 只能美化截图外围（背景、标题文案、手机外框、装饰、光影），绝对不得重绘、改动你截图里的 App 界面内容。**
> 每张配一个"美化主题"想让外围呈现的氛围，提示词已内置"保持截图原样"的强约束。

***

## 〇、最重要：先读这一段（决定你能不能成功）

文生图工具对"参考图"有两种模式，务必区分：

- ✅ **图片参考 / 垫图 / 局部重绘（Inpaint）模式**：把 `assets/1.png` 等作为"要保留的内容/垫底图"，AI 围绕它加元素 → **用这个**。

- ❌ 直接把它当抽样风格参考（Style Reference）→ 界面会被重绘 → 不要用。

在工具里上传真实截图后，提示词开头统一贴这句**保真约束**（强烈建议每张都带上）：

> **保真约束（Every shot, paste this first）：**
> `I will provide a real app screenshot as a reference. Keep its screen content 100% identical — do NOT redraw, modify, reskin or regenerate anything inside the phone screen. Only design the decorative frame, background, headline text, glass/lighting and surrounding layout AROUND the screenshot. The screenshot must be placed intact, edge to edge inside the phone screen with no cropping.`

***

## 一、统一美术规范（外围美化可选用的元素，8 张共享同一品牌）

**品牌配色（外围装饰用，勿改截图内部）**

- 主色活力橙 `#FF6B35`、浅橙点缀 `#FF8C5A`、成功绿 `#22C55E`（仅勾选/已完成）。

- 背景走 App 本色：暖白 `#FAFAFA` → 浅杏 `#FFF4EE` 渐变（除深色页可独立设计）。

- 主标题近黑 `#222222`、副标题中灰 `#555555`、弱文字 `#999999`。

- 卡片白底、圆角、淡橙描边 `#1AFF6B35`、浅橙影。

- 勿引入灰蓝、青绿、莫兰迪等非 App 色。

**外围通用元素（Leader 可自由组合）**

- 顶部大标题 + 副标题（中文简体，粗体）。

- 大号品牌数字/奖章/成就徽章（如 7/12 组、2520kg、88s）。

- 光晕、径向渐变、星星/横线/圆点等抽象装饰，不盖住截图。

- 现代智能手机外框：圆角、细边框、顶部灵动岛、边缘高光、投影。

***

## 二、逐张美化提示词

> 用法：把「该张真实截图」上传为参考图，再粘贴「该张提示词」。括号 `( )` 内是给 AI 的指令，不用读出。

***

### 截图 1 —— 首页（今日训练 · 票根/收据式设计）

- **真实截图**：`assets/1.png`（首页：问候语、今日训练"全身A"、开始训练按钮、底部导航）

- **美化主题**：把截图衬成一张"健身房训练票据"，突出"今天该练、别记错组"。

- **主标题**：`练到第几组，不用记`

- **副标题**：`今天练哪、练了几组、休息多久，全替你记牢`

- **可粘贴提示词**：
  `[保真约束见上]. Create a 9:19 app-store banner. Place my screenshot intact as the phone screen. Design AROUND it a warm off-white to peach (#FAFAFA→#FFF4EE) ticket-style composition: a faint dashed ticket border and punched notch, a bold near-black headline "练到第几组，不用记" at the top, with a smaller grey subtitle "今天练哪、练了几组、休息多久，全替你记牢". Add a small orange badge "今日训练", a perforated divider line, and a bottom row of three ticket stubs labeled 7/12 组 · 60min · 4 动作 in orange accents. Soft studio lighting, rounded phone frame with thin orange (#FF6B35) glow, no clutter, everything only around the phone, screen unmodified.`

***

### 截图 2 —— 休息倒计时（深色呼吸式设计）

- **真实截图**：`assets/2.png`（深色组间休息页：超大倒计时 88、高位下拉、休息 90秒）

- **美化主题**：保持截图的深色氛围，外围做成"深夜健身房"的呼吸感，突出超大倒计时数字。

- **主标题**：`休息多久，它替你数`

- **副标题**：`每组结束自动倒计时，到点震动提醒「该练下一组」`

- **可粘贴提示词**：
  `[保真约束见上]. This reference is a dark rest-timer screen. Create a 9:19 app-store banner with a DARK dramatic gym-at-night mood. Place my screenshot intact as the phone screen. Design AROUND it: deep charcoal background (#0e0b09), a glowing orange (#FF6B35) ring/aura behind the phone, huge breathable white-to-orange typography "休息多久，它替你数" at top with a smaller grey subtitle "每组结束自动倒计时，到点震动提醒「该练下一组」", and a large soft-glow numeral "88 s" echoing the timer. Soft particle light, thin orange phone glow, everything only around the phone, screen unmodified.`

***

### 截图 3 —— 首页（今日训练入口 · 抽屉式设计）

- **真实截图**：`assets/3.png`（首页：问候语、今日训练"全身A · 待开始"、开始训练按钮、当前计划、本周统计、底部导航）

- **美化主题**：和第 1 张"记录角度"区分，这张主打"打开 App 就知道今天练什么、一键开练"。做成"今天要练的抽屉卡"设计，突出「全身A · 开始训练」入口。

- **主标题**：`打开就是今天要练的`

- **副标题**：`今日练哪、几个动作、要多久，进 App 一眼看清，直接开练`

- **可粘贴提示词**：
  `[保真约束见上]. Create a 9:19 app-store banner, warm off-white to peach (#FAFAFA→#FFF4EE). Place my screenshot intact as the phone screen. Design AROUND it as a "today's workout drawer" presentation: a bold near-black headline "打开就是今天要练的" at the top, a smaller grey subtitle "今日练哪、几个动作、要多久，进 App 一眼看清，直接开练", a label "今日训练 · 全身A · 60min · 4 动作" in orange (#FF6B35), and a prominent orange "开始训练" call-to-action ring wrapping under the phone. Clean flat minimal decoration with a couple of abstract exercise-glyph circles, soft shadows, everything only around the phone, screen unmodified.`

***

### 截图 4 —— 增肌计划库（货架/菜单式设计）

- **真实截图**：`assets/4.png`（增肌计划列表：筛选标签 + 多张计划卡 + 免费/精品积分）

- **美化主题**：把计划列表衬成"精选货架 / 菜单"，突出可选、适合新手。

- **主标题**：`不知练什么？计划库任你选`

- **副标题**：`新手全身 / 增肌塑形 / 居家零器械，跟着练就行`

- **可粘贴提示词**：
  `[保真约束见上]. Create a 9:19 app-store banner, warm neutral minimal (#F6F3EF→#EFE9E2). Place my screenshot intact as the phone screen. Design AROUND it as a curated "shelf/menu" presentation: a bold near-black headline "不知练什么？计划库任你选", smaller grey subtitle "新手全身 / 增肌塑形 / 居家零器械，跟着练就行", a light wood-grey shelf bar under the phone, three small category chips 新手·三分化 / 增肌·四分化 / 居家·零器械, and a faint orange (#FF6B35) tag "精选计划". Clean product-shelf light and soft shadows, everything only around the phone, screen unmodified.`

***

### 截图 5 —— 教学中心（杂志课程表式设计）

- **真实截图**：`assets/5.png`（教学中心：为你推荐、系统课程、基础教学列表）

- **美化主题**：办成"健身杂志课程目录"，加页码/卷号，突出体系化教学。

- **主标题**：`动作不会？手把手教`

- **副标题**：`图文教程 + 系统课程，练得安全、练得明白`

- **可粘贴提示词**：
  `[保真约束见上]. Create a 9:19 app-store banner in an editorial magazine style (#fff→#FFF4EC). Place my screenshot intact as the phone screen. Design AROUND it: a large translucent issue-number "No.05" behind, an upper kicker "COURSE CATALOG · 课程目录", bold near-black headline "动作不会？手把手教", smaller grey subtitle "图文教程 + 系统课程，练得安全、练得明白", and a thin bottom caption strip "从器材使用到饮食计划 · 5 章闭环". Editorial serif accents, thin orange rules, everything only around the phone, screen unmodified.`

***

### 截图 6 —— 虚拟对手 PK（擂台式设计 · 已生成）

- **真实截图**：`assets/6.png`（含本周 PK 对垒页：你 vs 对手、训练次数对比）

- **美化主题**：做成竞技擂台海报，放大"你vs对手"的对垒感。此张你已生成，以下提示词留存备用。

- **主标题**：`有个对手，陪你坚持`

- **副标题**：`为你匹配虚拟对手，练完还分胜负`

- **可粘贴提示词**：
  `[保真约束见上]. Create a 9:19 app-store banner with a DARK arena mood (#1A232E→#141C24). Place my screenshot intact as the phone screen. Design AROUND it: a top kicker "PK ARENA", bold white headline "练完，分个胜负", smaller blue-grey subtitle "每一次训练，都在和对手较劲", a bright glowing VS emblem with an orange (#FF6B35) to peach gradient between the headline area, spot arena lighting from above, subtle floor reflection, orange rim-light on the phone, everything only around the phone, screen unmodified.`

***

### 截图 7 —— 训练完成海报（杂志封面式设计）

- **真实截图**：`assets/7.png`（训练完成：LiftTrack 海报卡、2520kg 总重量、分享按钮）

- **美化主题**：把训练完成页衬成"人生封面"，突出成就数字与分享。

- **主标题**：`练完一张，晒出突破`

- **副标题**：`一键生成训练海报，记录每一次进步`

- **可粘贴提示词**：
  `[保真约束见上]. Create a 9:19 app-store banner in a premium editorial cover style (#F7EFE9→#F0DDD2). Place my screenshot intact as the phone screen. Design AROUND it: a strong magazine-cover frame with a white border, a bold near-black headline "练完一张，晒出突破", smaller grey subtitle "一键生成训练海报，记录每一次进步", a large printed number "2520" with "kg 总重量" in terracotta-orange as an award flourish, and a small caption "TODAY'S ACHIEVEMENT". Editorial serif + orange accents, everything only around the phone, screen unmodified.`

***

### 截图 8 —— 邀请有礼（领奖台式设计）

- **真实截图**：`assets/8.png`（邀请有礼：邀请码 FIT-INV-P2Y3XL、复制/分享、进度、奖励规则）

- **美化主题**：做成"领奖台/福利庆典"，突出邀请奖励。

- **主标题**：`叫上朋友，一起拿礼`

- **副标题**：`邀请好友解锁进阶教程、专属皮肤与奖励`

- **可粘贴提示词**：
  `[保真约束见上]. Create a 9:19 app-store banner in a warm festive palette (#FDF3E7→#FBE6CF). Place my screenshot intact as the phone screen. Design AROUND it: a trophy 🏆 accent, bold near-black headline "叫上朋友，一起拿礼", smaller sepia subtitle "邀请好友解锁进阶教程、专属皮肤与奖励", a light three-step podium with tiers labeled 1/3/5 人, small gift boxes and confetti dots in orange (#FF6B35) and gold, everything only around the phone, screen unmodified.`

***

### 截图 9 —— 多种主题皮肤任你选（画廊/图鉴式设计）

- **真实素材**：`assets/9a.png ~ 9h.png`（你提供的 **8 套不同主题皮肤**在首页的展示效果图，各一张）

- **作用**：把 8 张主题首页做成一张"皮肤图鉴/画廊"，传达"App 外观随你换"，针对在意个性化、在意颜值的用户。

- **重要：这张是"多图拼贴"，别用普通单张参考模式。**

- **美化主题**：做成一面"主题皮肤展示墙"。八个手机屏（每个显示一款不同主题首页）均匀排成 **2×4 或 4×2** 的网格，外围统一加标题与边框。

- **主标题**：`多种主题，任你挑选`

- **副标题**：`深色 / 莫兰迪 / 活力 ，界面外观随你换，训练也要有格调`

- **可粘贴提示词（用下图模式时）**：
  `[保真约束见上]. I provide EIGHT app screenshots, each showing the same app home under a different colored theme skin. Composite them into ONE 9:19 app-store banner as a tidy skin-gallery grid: arrange the eight phone screens into a 2-column × 4-row or 4×2 grid, spread across the frame. Do NOT change what each screenshot shows — keep each phone screen pixel-identical, only crop/scale each to fit its grid cell. Top: a bold near-black headline "多种主题，任你挑选", smaller grey subtitle "深色 / 莫兰迪 / 活力，界面外观随你换，训练也要有格调". Give the grid an elegant warm off-white (#FAFAFA→#FFF4EE) background, a thin border frame with an orange (#FF6B35) accent bar, equal gutters, soft shadows under each phone, no text inside cells besides the untouched screens, everything only around/behind the phones.`

***

## 三、保真兜底（若 AI 仍改动了界面）

如果生成的图里**截图内容被重绘/变形/换字**：

1. 重新上传原图，提示词继续开头那段 `[保真约束]`，并额外加：
   `Do not invent, replace or redraw any text, buttons or icons inside my screenshot. If you are not sure, keep the phone screen as a literal untouched image.`
2. 若工具支持「局部重绘 / 蒙版」：把手机屏区域锁定为"保持"，只对四周生成。
3. 还不行的工具就换支持参考图的工具，别再硬试。

***

## 四、生成后自检清单

- [ ] 手机屏内与你的真实截图**完全一致**（无新增/删除/改字/变形）

- [ ] 外围装饰、标题、手机框、光影美观且统一品牌

- [ ] 主标题无错别字、副标题与文案口径一致

- [ ] 外围配色：主色活力橙 #FF6B35、背景暖白→浅杏；深色页可独立

- [ ] 无真实人脸/他人头像/测试编号外露（截图里的昵称可保留但属真实数据，上架前自行判断）

***

## 五、8 张与真实截图对应关系

| 截图 | 真实页面              | 美化主题         |
| -- | ----------------- | ------------ |
| 1  | 首页                | 票根/收据式（组数记录） |
| 2  | 休息倒计时（深色）         | 深色呼吸         |
| 3  | 首页（今日训练入口）        | 今日训练抽屉式      |
| 4  | 增肌计划库             | 货架/菜单式       |
| 5  | 教学中心              | 杂志课程表式       |
| 6  | 虚拟对手 PK           | 擂台式（已生成）     |
| 7  | 训练完成海报            | 杂志封面式        |
| 8  | 邀请有礼              | 领奖台式         |
| 9  | 8 套主题皮肤首页（9a\~9h） | 画廊/图鉴式（多图拼贴） |

> 提醒：截图 3 已改为「首页 · 今日训练入口」，与第 1 张「首页 · 组数记录」同为首页但角度不同；第 6 张为独立虚拟对手 PK（你已生成）；截图 9 为多图拼贴的皮肤画廊，需你提供 8 张不同主题首页图。为更完整，理想还可再补独立「统计 / PR」页。


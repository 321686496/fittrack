# 动作库全量动作指南与 AI 绘图提示词

> 本文档基于 Flutter 项目 `fittrack_flutter/lib/data/mock_data.dart` 中的系统内置动作库编写，共 **21 个动作**、**7 个分类**（胸部、背部、腿部、肩膀、手臂、核心、跑步）。
> 每个动作均包含：基本信息、动作描述、目标肌群、训练步骤（含关键要点），以及**封面图 + 每个步骤图**的 AI 生成提示词，每种图提供 **4 套风格**：写实风、插画风、卡通风、黑白线条风。
> 适用平台：Midjourney / DALL·E 3 / Stable Diffusion SDXL / 即梦 / 通义万相等 AI 图像生成工具。

---

## 一、动作库总览

| ID | 动作名称 | 英文名 | 分类 | 器械 | 目标肌群 |
|:---:|:---|:---|:---:|:---:|:---|
| e1 | 杠铃卧推 | Barbell Bench Press | 胸部 | 杠铃 | 胸大肌、三角肌前束、肱三头肌 |
| e2 | 哑铃飞鸟 | Dumbbell Fly | 胸部 | 哑铃 | 胸大肌、三角肌前束 |
| e3 | 上斜卧推 | Incline Bench Press | 胸部 | 杠铃 | 胸大肌上部、三角肌前束、肱三头肌 |
| e4 | 绳索夹胸 | Cable Crossover | 胸部 | 器械 | 胸大肌、三角肌前束 |
| e5 | 引体向上 | Pull-up | 背部 | 自重 | 背阔肌、肱二头肌、前臂 |
| e6 | 杠铃划船 | Barbell Row | 背部 | 杠铃 | 背阔肌、菱形肌、肱二头肌 |
| e7 | 高位下拉 | Lat Pulldown | 背部 | 器械 | 背阔肌、肱二头肌 |
| e8 | 坐姿划船 | Seated Cable Row | 背部 | 器械 | 背阔肌中部、菱形肌、斜方肌 |
| e9 | 杠铃深蹲 | Barbell Squat | 腿部 | 杠铃 | 股四头肌、臀大肌、核心肌群 |
| e10 | 腿举 | Leg Press | 腿部 | 器械 | 股四头肌、臀大肌 |
| e11 | 哑铃推举 | Dumbbell Shoulder Press | 肩膀 | 哑铃 | 三角肌中束、三角肌前束、肱三头肌 |
| e12 | 侧平举 | Lateral Raise | 肩膀 | 哑铃 | 三角肌中束、斜方肌上部 |
| e13 | 哑铃弯举 | Dumbbell Curl | 手臂 | 哑铃 | 肱二头肌、前臂 |
| e14 | 锤式弯举 | Hammer Curl | 手臂 | 哑铃 | 肱二头肌、肱桡肌、前臂 |
| e15 | 平板支撑 | Plank | 核心 | 自重 | 腹横肌、深层稳定肌群、竖脊肌 |
| e16 | 卷腹 | Crunch | 核心 | 自重 | 腹直肌、腹斜肌 |
| e17 | 慢跑 | Jogging | 跑步 | 自重 | 股四头肌、小腿肌群、心肺 |
| e18 | 间歇跑 | Interval Run | 跑步 | 自重 | 股四头肌、臀大肌、心肺 |
| e19 | 长距离跑 | Long Distance Run | 跑步 | 自重 | 股四头肌、小腿肌群、心肺 |
| e20 | 冲刺跑 | Sprint | 跑步 | 自重 | 股四头肌、臀大肌、心肺 |
| e21 | 坡度跑 | Incline Treadmill Run | 跑步 | 跑步机 | 臀大肌、股四头肌、小腿肌群 |

---

## 二、四套风格设定（公共风格前缀）

为保证同一套图风格统一，**每段提示词 = 下方对应风格前缀 + 各动作的核心描述**。下文每段提示词均为可直接复制的完整提示词（已包含风格前缀）。

### 风格 A：写实风（Photorealistic）

适合：封面主视觉、真实感强的教学配图。

```
photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, no text, no watermark, no logo
```

### 风格 B：插画风（Flat Illustration）

适合：App 内教学插图，扁平、清爽、莫兰迪配色（与项目整体色调一致）。

```
flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, no text, no watermark, no logo
```

### 风格 C：卡通风（Cute Cartoon）

适合：趣味展示、新手引导、低龄友好场景。

```
cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, no text, no watermark, no logo
```

### 风格 D：黑白线条风（Black & White Line Art）

适合：印刷物料、线稿涂色卡、极简说明书风格，去色后信息仍清晰。

```
black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, no shading, no gradient, no text, no watermark, no logo
```

> 提示：Midjourney 可追加 `--ar 1:1`（封面图）或 `--ar 4:3`（步骤图）与 `--v 6`；SDXL/即梦等工具封面图用 `square`（1024×1024），步骤图用 `landscape_4_3`（1024×768）。

---

## 三、动作详解与提示词

### 1. 杠铃卧推（Barbell Bench Press）｜e1

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e1 / 胸部 / 杠铃 |
| 目标肌群 | 胸大肌、三角肌前束、肱三头肌 |
| 封面图路径 | `assets/images/exercises/e1_barbell_bench_press.png` |

**动作描述**：平板杠铃卧推是胸部训练的王牌动作，主要刺激胸大肌中部，同时锻炼三角肌前束和肱三头肌。

**训练步骤**：
1. **准备姿势**：仰卧于平凳上，双脚踩实地面，肩胛骨后缩下沉，挺胸收腹。双手正握杠铃，握距略宽于肩，腕关节保持中立位，肘关节微屈。要点：肩胛骨始终保持后缩下沉不塌肩、双脚踩实臀部贴紧凳面、腕关节中立不后翻。
2. **离心下放**：控制杠铃沿垂直轨迹缓慢下放至胸大肌下缘（乳头连线），肘关节与躯干约呈 75 度角，下放过程吸气，全程保持张力。要点：杠铃轨迹垂直于肩关节正上方、肘关节约 75 度不外展过大、离心过程 2-3 秒控制。
3. **底端触胸**：杠铃轻触胸部后停顿 0.5-1 秒，不反弹借力，臀部不离凳，双脚不挪动，保持肩胛稳定。要点：轻触胸部不反弹借力、臀部贴紧凳面不离开。
4. **向心推起**：胸大肌主动发力，沿原轨迹垂直上推，肘部同步伸直，推起过程呼气，避免肩胛前引，保持挺胸。要点：胸肌主动发力推起、肩胛保持后缩不前引。
5. **顶端锁定**：推至手臂自然伸直（不锁死肘关节），杠铃位于肩关节正上方，肩胛保持后缩下沉，完成一次重复。要点：肘关节不锁死、杠铃锁定于肩关节正上方。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, male athlete lying on flat bench pressing barbell up from mid chest, wide grip, feet flat on floor, chest muscles contracted, arched chest, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, male athlete lying on flat bench pressing barbell upward from chest, wide grip, feet flat on floor, arched chest, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete lying on bench pushing barbell up from chest, happy expression, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, male athlete lying on flat bench pressing barbell upward from chest, wide grip, feet flat on floor, arched chest, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athletic man lying on flat bench, feet flat on floor, both hands gripping barbell slightly wider than shoulder width, shoulder blades retracted, wrist neutral, elbows slightly bent, chest up, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, male athlete lying on flat bench in starting position, wide grip on barbell, shoulder blades retracted, wrist neutral, feet on floor, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lying on flat bench gripping barbell wide, ready to press, happy face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, male athlete lying on flat bench in starting position, wide grip on barbell, shoulder blades retracted, wrist neutral, feet on floor, side view, no text, no watermark, no logo`

**步骤2 离心下放**
- 写实风：`photorealistic fitness photography, athlete lying on flat bench slowly lowering barbell to mid chest, elbows at 75 degrees, controlled movement, chest muscles stretching, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete lowering barbell to mid chest, elbows at 75 degrees, controlled motion arrow, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lowering big barbell slowly to chest, concentrating face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete lowering barbell to mid chest, elbows at 75 degrees, controlled motion arrow, side view, no text, no watermark, no logo`

**步骤3 底端触胸**
- 写实风：`photorealistic fitness photography, athlete lying on bench with barbell touching mid chest, brief pause, hips and feet stable, shoulder blades retracted, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, barbell resting gently on chest at bottom position, paused, stable hips, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding barbell touching chest at bottom, determined face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, barbell resting gently on chest at bottom position, paused, stable hips, side view, no text, no watermark, no logo`

**步骤4 向心推起**
- 写实风：`photorealistic fitness photography, athlete pressing barbell upward from chest with power, chest muscles contracted, elbows extending, breathing out, shoulder blades stable, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete pushing barbell up from chest, chest muscles highlighted in contraction, elbows extending, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pushing barbell up with effort, sweat drop, motivating pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete pushing barbell up from chest, chest muscles highlighted in contraction, elbows extending, side view, no text, no watermark, no logo`

**步骤5 顶端锁定**
- 写实风：`photorealistic fitness photography, athlete with arms fully extended holding barbell above shoulder joint, elbows not locked, shoulder blades retracted down, finishing position, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete holding barbell at top position above shoulders, arms extended not locked, finished repetition, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding barbell high above chest with both arms, smiling proud, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete holding barbell at top position above shoulders, arms extended not locked, finished repetition, side view, no text, no watermark, no logo`

---

### 2. 哑铃飞鸟（Dumbbell Fly）｜e2

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e2 / 胸部 / 哑铃 |
| 目标肌群 | 胸大肌、三角肌前束 |
| 封面图路径 | `assets/images/exercises/e2_dumbbell_fly.png` |

**动作描述**：哑铃飞鸟重点拉伸胸大肌，增加胸部肌肉的伸展范围，适合作为卧推的辅助动作。

**训练步骤**：
1. **准备姿势**：仰卧于平凳上，双脚踩实地面，肩胛骨后缩下沉贴凳。双手持哑铃于胸部正上方伸直，掌心相对，肘关节微屈约 20-30 度并固定角度。要点：肩胛贴凳不耸肩、肘关节微屈角度全程固定。
2. **离心展开**：保持肘关节固定角度，沿弧线缓慢向两侧打开哑铃，感受胸大肌拉伸，下放至与肩同高或略低，下放过程吸气。要点：肘关节角度全程固定、弧线轨迹下放。
3. **底端拉伸**：哑铃下放至与肩同高，胸大肌充分拉伸，停顿 1 秒感受拉伸感，不追求过大活动度以免肩关节受伤。要点：底端停顿感受拉伸、不超肩关节活动度。
4. **向心合拢**：胸大肌发力沿弧线将哑铃合拢至起始位置，呼气，顶峰收缩 1-2 秒，想象抱住一棵大树。要点：胸肌发力弧线合拢、顶峰收缩 1-2 秒。
5. **顶端收拢**：哑铃回到胸部正上方，掌心相对，肘关节保持微屈，肩胛稳定贴凳，完成一次重复，注意哑铃不互相碰撞。要点：顶端哑铃不触碰碰撞、肩胛贴凳稳定。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete lying on flat bench with arms opened wide in arc holding dumbbells above chest, elbows slightly bent, chest muscles stretched, palms facing inward, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete lying on bench holding dumbbells wide open above chest in a broad arc, elbows slightly bent, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete lying on bench spreading arms wide holding dumbbells, happy face, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete lying on bench holding dumbbells wide open above chest in a broad arc, elbows slightly bent, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete lying on flat bench holding dumbbells above chest with arms extended, palms facing each other, elbows slightly bent at fixed angle, feet on floor, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete holding dumbbells above chest, palms facing each other, elbows slightly bent, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbells above chest ready to fly, cheerful face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete holding dumbbells above chest, palms facing each other, elbows slightly bent, side view, no text, no watermark, no logo`

**步骤2 离心展开**
- 写实风：`photorealistic fitness photography, athlete opening arms wide to sides in a broad arc holding dumbbells, elbows locked at fixed slight angle, chest muscles stretching, dumbbells lowered to shoulder height, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, arms opening wide in arc, elbows slightly bent, chest stretch indicated, dumbbells at shoulder level, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete spreading arms wide like a bird holding dumbbells, fun expression, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, arms opening wide in arc, elbows slightly bent, chest stretch indicated, dumbbells at shoulder level, side view, no text, no watermark, no logo`

**步骤3 底端拉伸**
- 写实风：`photorealistic fitness photography, athlete at bottom of fly, dumbbells at shoulder height, chest fully stretched, brief pause, shoulder blades on bench, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells lowered to shoulder height, full chest stretch with highlight, pause, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbells down at sides feeling chest stretch, relaxed face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells lowered to shoulder height, full chest stretch with highlight, pause, side view, no text, no watermark, no logo`

**步骤4 向心合拢**
- 写实风：`photorealistic fitness photography, athlete closing arms together in arc like hugging a large barrel, elbows maintaining fixed bend, chest muscles squeezing, dumbbells moving above chest, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, arms closing in wide arc hugging a big barrel, chest contraction highlighted, dumbbells above chest, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete bringing dumbbells together hugging motion, smiling with effort, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, arms closing in wide arc hugging a big barrel, chest contraction highlighted, dumbbells above chest, side view, no text, no watermark, no logo`

**步骤5 顶端收拢**
- 写实风：`photorealistic fitness photography, athlete holding dumbbells above chest at top position, palms facing each other, elbows slightly bent, dumbbells not touching, shoulder blades stable on bench, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells held above chest not touching, stable shoulder blades, completed repetition, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbells up above chest, proud satisfied face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells held above chest not touching, stable shoulder blades, completed repetition, side view, no text, no watermark, no logo`

---

### 3. 上斜卧推（Incline Bench Press）｜e3

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e3 / 胸部 / 杠铃 |
| 目标肌群 | 胸大肌上部、三角肌前束、肱三头肌 |
| 封面图路径 | `assets/images/exercises/e3_incline_bench_press.png` |

**动作描述**：上斜卧推主要针对胸大肌上部，帮助塑造饱满的上胸线条。

**训练步骤**：
1. **准备姿势**：调节上斜凳至 30-45 度，仰卧于凳上，双脚踩实地面，肩胛后缩下沉，挺胸。双手正握杠铃，握距略宽于肩，腕关节中立。要点：凳面角度 30-45 度、肩胛后缩下沉贴凳。
2. **起始位置**：双手将杠铃从架上取出，控制杠铃位于锁骨正上方，手臂伸直不锁死，核心收紧稳定。要点：杠铃位于锁骨正上方、核心收紧稳定。
3. **离心下放**：控制杠铃沿斜上方轨迹下放至上胸部（锁骨下缘），肘关节约呈 60-75 度，吸气，保持张力不自由落体。要点：杠铃下放至上胸部、肘关节约 60-75 度。
4. **向心推起**：上胸大肌发力将杠铃沿原轨迹斜上推起，呼气，肘部同步伸直，肩胛保持稳定不前引，挺胸收腹。要点：上胸主动发力、肩胛稳定不前引。
5. **顶端锁定**：推至手臂自然伸直（不锁死），杠铃回到锁骨正上方，完成一次重复，注意角度过大会变平板卧推。要点：顶端不锁死、角度保持 30-45 度。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete lying on incline bench at 30-45 degrees pressing barbell from upper chest, feet on floor, upper chest muscles contracted, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete on incline bench pressing barbell upward from upper chest, 30-45 degree bench, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete on slanted bench pushing barbell up, determined smile, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete on incline bench pressing barbell upward from upper chest, 30-45 degree bench, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete lying on incline bench set at 30-45 degrees, wide grip on barbell, shoulder blades retracted, chest up, feet flat on floor, wrist neutral, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete on incline bench in starting position, wide grip on barbell at upper chest, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lying on slanted bench gripping barbell wide, ready pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete on incline bench in starting position, wide grip on barbell at upper chest, side view, no text, no watermark, no logo`

**步骤2 起始位置**
- 写实风：`photorealistic fitness photography, athlete unracking barbell and holding it above collarbone, arms extended not locked, core tight, incline bench, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, barbell held above collarbone, arms extended not locked, stable core, incline bench, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding barbell above chest on incline bench, concentrating, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, barbell held above collarbone, arms extended not locked, stable core, incline bench, side view, no text, no watermark, no logo`

**步骤3 离心下放**
- 写实风：`photorealistic fitness photography, athlete lowering barbell diagonally to upper chest below collarbone, elbows at 60-75 degrees, controlled movement, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, barbell lowering to upper chest, elbows 60-75 degrees, controlled motion, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete slowly lowering barbell to upper chest, focused face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, barbell lowering to upper chest, elbows 60-75 degrees, controlled motion, side view, no text, no watermark, no logo`

**步骤4 向心推起**
- 写实风：`photorealistic fitness photography, athlete pressing barbell diagonally upward, upper chest muscles contracting, elbows extending, chest up, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete pushing barbell up from upper chest, upper chest highlighted, elbows extending, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pushing barbell up with effort on incline bench, happy determination, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete pushing barbell up from upper chest, upper chest highlighted, elbows extending, side view, no text, no watermark, no logo`

**步骤5 顶端锁定**
- 写实风：`photorealistic fitness photography, athlete holding barbell above collarbone with arms extended not locked, completing repetition, incline bench angle visible, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, barbell locked above collarbone, arms extended not locked, finished repetition, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding barbell at top, proud smile, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, barbell locked above collarbone, arms extended not locked, finished repetition, side view, no text, no watermark, no logo`

---

### 4. 绳索夹胸（Cable Crossover）｜e4

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e4 / 胸部 / 器械（绳索） |
| 目标肌群 | 胸大肌、三角肌前束 |
| 封面图路径 | `assets/images/exercises/e4_cable_cross.png` |

**动作描述**：绳索夹胸提供持续张力，有效孤立胸大肌，适合作为收尾动作。

**训练步骤**：
1. **准备姿势**：站于绳索机双侧滑轮之间，双脚前后弓步站立稳定重心，双手握住 D 型把手，身体微前倾，挺胸收腹，核心收紧。要点：弓步站位稳定重心、挺胸收腹身体微前倾。
2. **起始位置**：双臂展开略低于肩，肘关节微屈固定角度，掌心朝前，肩胛后缩下沉，核心收紧准备发力夹胸。要点：肘关节微屈角度固定、肩胛后缩下沉。
3. **离心上送**：控制把手缓慢回放至双臂展开位，胸大肌充分拉伸，肘关节角度不变，吸气，保持张力不甩动。要点：控制回放保持张力、肘关节角度不变。
4. **向心夹胸**：胸大肌发力将把手向胸前下方弧线夹拢，肘部引导，呼气，在胸前交汇处顶峰收缩 2 秒，感受胸肌挤压。要点：弧线夹拢肘部引导、胸前交汇顶峰收缩 2 秒。
5. **顶端收拢**：双手在胸前交汇后保持收缩 1-2 秒，肩胛充分后缩，缓慢回放至起始位置，完成一次重复，全程控制。要点：交汇处保持收缩、肩胛充分后缩。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete standing between cable machine pulleys sweeping handles together in front of chest, arms slightly bent, chest muscles squeezed, slight forward lean, front view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete standing between cable pulleys bringing handles together in front of chest, front view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete pulling cables together in front of chest, determined smile, front view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete standing between cable pulleys bringing handles together in front of chest, front view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete standing in staggered stance between cable machine pulleys, holding both D-handles, slight forward lean, chest up, core engaged, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete in staggered stance holding cable handles, slight forward lean, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete standing between two cable towers holding handles, ready stance, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete in staggered stance holding cable handles, slight forward lean, front view, no text, no watermark, no logo`

**步骤2 起始位置**
- 写实风：`photorealistic fitness photography, athlete with arms open slightly below shoulder height, elbows slightly bent at fixed angle, palms forward, shoulder blades retracted, holding cable handles, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, arms open wide holding cable handles, elbows slightly bent, ready to squeeze, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding cables with arms open wide, excited face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, arms open wide holding cable handles, elbows slightly bent, ready to squeeze, front view, no text, no watermark, no logo`

**步骤3 离心上送**
- 写实风：`photorealistic fitness photography, athlete slowly returning handles to open position, arms wide, chest muscles stretched, elbows angle unchanged, tension in cables, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, cables returning handles to open arms, chest stretch, controlled movement, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete letting cables pull arms open wide, surprised fun face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, cables returning handles to open arms, chest stretch, controlled movement, front view, no text, no watermark, no logo`

**步骤4 向心夹胸**
- 写实风：`photorealistic fitness photography, athlete squeezing cable handles together in front of chest in an arc, elbows leading, chest muscles fully contracted, peak contraction, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, hands bringing handles together in front of chest, chest contraction highlighted, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pulling cables together in front of chest with effort, clenched teeth smile, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, hands bringing handles together in front of chest, chest contraction highlighted, front view, no text, no watermark, no logo`

**步骤5 顶端收拢**
- 写实风：`photorealistic fitness photography, athlete hands meeting in front of chest with cables, holding contraction, shoulder blades fully retracted, chest squeezed, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, hands crossed or meeting in front of chest, peak contraction hold, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete hands together in front of chest, happy accomplished face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, hands crossed or meeting in front of chest, peak contraction hold, front view, no text, no watermark, no logo`

---

### 5. 引体向上（Pull-up）｜e5

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e5 / 背部 / 自重 |
| 目标肌群 | 背阔肌、肱二头肌、前臂 |
| 封面图路径 | `assets/images/exercises/e5_pull_up.png` |

**动作描述**：引体向上是背部训练的黄金动作，主要锻炼背阔肌和肱二头肌。

**训练步骤**：
1. **准备姿势**：双手正握单杠，握距略宽于肩，身体自然悬垂，核心收紧，肩胛下沉激活背阔肌，避免死悬挂拉伤肩关节。要点：肩胛下沉先激活、核心收紧避免死悬挂。
2. **离心下放**：从顶端位置控制身体缓慢下放至完全伸展，背阔肌充分拉伸，下放过程 2-3 秒，保持张力不松手。要点：离心 2-3 秒控制、保持张力不松手。
3. **底端悬挂**：身体完全伸展悬垂，肩胛保持下沉不松弛，核心持续收紧，避免惯性摆动，准备背阔肌发力上拉。要点：底端肩胛不松弛、避免惯性摆动。
4. **向心上拉**：背阔肌发力，肘部向下向后引导，将身体向上拉起，呼气，肘部不外展，避免二头肌过度代偿。要点：背阔肌发力肘部引导、肘部不外展。
5. **顶端过杠**：拉至下巴超过杠面，背阔肌顶峰收缩 1 秒，不后仰过多，肩胛充分下回旋后缩，完成一次重复。要点：下巴过杠、肩胛充分下回旋。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete hanging from pull-up bar pulling chin above the bar, back muscles engaged, legs bent at knees crossed behind, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete pulling up on bar with chin above bar, back muscles highlighted, knees bent crossed behind, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete pulling up on bar, chin over the bar, happy proud face, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete pulling up on bar with chin above bar, back muscles highlighted, knees bent crossed behind, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete hanging from pull-up bar with wide overhand grip, arms fully extended, body straight, core tight, feet off ground, shoulder blades active, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete hanging from bar, arms extended, straight body, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete hanging from bar with straight arms, calm face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete hanging from bar, arms extended, straight body, side view, no text, no watermark, no logo`

**步骤2 离心下放**
- 写实风：`photorealistic fitness photography, athlete lowering body slowly from top position with full control, arms extending, back muscles stretching, body straight no swinging, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete lowering down from bar top, controlled descent arrow, back stretch, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete slowly lowering from bar, focused face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete lowering down from bar top, controlled descent arrow, back stretch, side view, no text, no watermark, no logo`

**步骤3 底端悬挂**
- 写实风：`photorealistic fitness photography, athlete fully extended hanging from bar, shoulder blades engaged not relaxed, core tight, no swinging, ready position, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, full hang at bottom position, shoulder blades engaged, ready to pull, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete hanging fully extended, thinking face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, full hang at bottom position, shoulder blades engaged, ready to pull, side view, no text, no watermark, no logo`

**步骤4 向心上拉**
- 写实风：`photorealistic fitness photography, athlete pulling body upward using back muscles, elbows driving down and back, chin rising toward bar, back muscles contracting, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete pulling up, elbows driving down and back, back contraction highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pulling up with effort, sweat drops, motivational face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete pulling up, elbows driving down and back, back contraction highlighted, side view, no text, no watermark, no logo`

**步骤5 顶端过杠**
- 写实风：`photorealistic fitness photography, athlete at top of pull-up with chin above the bar, back muscles peak contraction, shoulder blades retracted down, slight lean, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, chin above bar at top position, peak contraction hold, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete chin above the bar, big happy smile, celebration pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, chin above bar at top position, peak contraction hold, side view, no text, no watermark, no logo`

---

### 6. 杠铃划船（Barbell Row）｜e6

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e6 / 背部 / 杠铃 |
| 目标肌群 | 背阔肌、菱形肌、肱二头肌 |
| 封面图路径 | `assets/images/exercises/e6_barbell_row.png` |

**动作描述**：杠铃划船全面刺激背部肌群，特别是背阔肌中下部和菱形肌。

**训练步骤**：
1. **准备姿势**：双脚与肩同宽，微屈膝，髋部铰链俯身至上半身接近平行地面，背部保持中立，双手正握杠铃，握距略宽于肩。要点：背部中立不弓背、髋部铰链俯身。
2. **离心下放**：控制杠铃沿大腿前侧缓慢下放至手臂自然伸直，背阔肌充分拉伸，下放过程保持背部中立，吸气。要点：杠铃贴大腿前侧、背部中立保持。
3. **起始位置**：杠铃悬垂于膝盖下方，手臂自然伸直，肩胛放松下沉，背部平直，重心在足中，准备背部发力上拉。要点：杠铃位于膝盖下方、重心在足中。
4. **向心上拉**：背阔肌发力，肘部贴身向后上方拉起杠铃至下腹/肚脐位置，肩胛后缩，呼气，肘部不外展。要点：杠铃贴身拉至下腹、肘部贴身不外展。
5. **顶端收缩**：杠铃拉至下腹位置，肩胛充分后缩，背阔肌顶峰收缩 1 秒，控制下放，完成一次重复，保持背部平直。要点：肩胛充分后缩、顶峰收缩 1 秒。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete bent over at 45 degrees pulling barbell to lower abdomen, back muscles contracted, knees slightly bent, flat back, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete bent over at 45 degrees rowing barbell to lower abdomen, back muscles highlighted, knees slightly bent, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete bent over pulling barbell up to belly, effort face, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete bent over at 45 degrees rowing barbell to lower abdomen, back muscles highlighted, knees slightly bent, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete bent over at 45 degrees with hip hinge, knees slightly bent, back neutral, both hands gripping barbell wider than shoulders, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, bent over position at 45 degrees, neutral back, wide grip on barbell, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete bent over gripping barbell, ready stance, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, bent over position at 45 degrees, neutral back, wide grip on barbell, side view, no text, no watermark, no logo`

**步骤2 离心下放**
- 写实风：`photorealistic fitness photography, athlete slowly lowering barbell along front of thighs to straight arms, back muscles stretching, back stays neutral, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, barbell lowering along thighs, back stretch, controlled motion, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lowering barbell slowly, focused face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, barbell lowering along thighs, back stretch, controlled motion, side view, no text, no watermark, no logo`

**步骤3 起始位置**
- 写实风：`photorealistic fitness photography, barbell hanging below knees, arms fully extended, shoulder blades relaxed down, flat back, weight on mid-foot, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, barbell hanging below knees, arms extended, flat back, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding barbell below knees, calm ready face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, barbell hanging below knees, arms extended, flat back, side view, no text, no watermark, no logo`

**步骤4 向心上拉**
- 写实风：`photorealistic fitness photography, athlete pulling barbell to lower abdomen near belly button, elbows driving back close to body, shoulder blades squeezing, back muscles contracted, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, barbell pulled to lower abdomen, elbows close to body, back contraction highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pulling barbell up to belly with effort, sweat drop, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, barbell pulled to lower abdomen, elbows close to body, back contraction highlighted, side view, no text, no watermark, no logo`

**步骤5 顶端收缩**
- 写实风：`photorealistic fitness photography, barbell held at lower abdomen, shoulder blades fully retracted, back muscles peak contraction hold, flat back maintained, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, barbell at lower abdomen, peak contraction hold, shoulder blades together, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding barbell at belly, proud satisfied face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, barbell at lower abdomen, peak contraction hold, shoulder blades together, side view, no text, no watermark, no logo`

---

### 7. 高位下拉（Lat Pulldown）｜e7

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e7 / 背部 / 器械 |
| 目标肌群 | 背阔肌、肱二头肌 |
| 封面图路径 | `assets/images/exercises/e7_lat_pulldown.png` |

**动作描述**：高位下拉模拟引体向上动作，适合无法完成引体向上的训练者。

**训练步骤**：
1. **准备姿势**：坐于高位下拉机，双腿固定压板，双手宽握把手（宽于肩），挺胸收腹，躯干微后倾 15 度，核心收紧。要点：挺胸收腹微后倾、双腿固定压板。
2. **离心上送**：控制把手缓慢上送至双臂完全伸直，背阔肌充分拉伸，肩胛上回旋放松，上送过程吸气，保持张力。要点：控制上送保持张力、肩胛上回旋放松。
3. **起始位置**：双臂完全伸直，肩胛上回旋，躯干微后倾，挺胸，核心收紧，准备背阔肌发力下拉把手。要点：双臂完全伸直、挺胸核心收紧。
4. **向心下拉**：背阔肌发力，肘部引导向下后方压，将把手拉至锁骨/上胸位置，呼气，肩胛下回旋后缩。要点：肘部引导下压、肩胛下回旋后缩。
5. **底端收缩**：把手拉至锁骨位置，肩胛充分后缩，背阔肌顶峰收缩 1 秒，不后仰过多，控制还原，完成一次重复。要点：把手拉至锁骨、肩胛充分后缩。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete seated at lat pulldown machine pulling wide bar down to upper chest, back muscles engaged, thighs secured under pads, front view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete seated at pulldown machine pulling bar to upper chest, back muscles highlighted, front view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete sitting at pulldown machine pulling bar down, happy effort face, front view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete seated at pulldown machine pulling bar to upper chest, back muscles highlighted, front view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete seated at lat pulldown machine, thighs secured under pads, wide grip on bar overhead, slight backward lean, chest up, core tight, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, seated at machine with wide grip overhead, slight lean back, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete seated at pulldown machine gripping bar wide, ready pose, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, seated at machine with wide grip overhead, slight lean back, front view, no text, no watermark, no logo`

**步骤2 离心上送**
- 写实风：`photorealistic fitness photography, athlete slowly letting bar rise until arms fully extended, back muscles stretched, shoulder blades relaxed up, tension maintained, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, bar rising to full arm extension, controlled movement, back stretch, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete letting bar go up slowly, relaxed fun face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, bar rising to full arm extension, controlled movement, back stretch, front view, no text, no watermark, no logo`

**步骤3 起始位置**
- 写实风：`photorealistic fitness photography, athlete with arms fully extended holding bar overhead, shoulder blades elevated, slight backward lean, chest up, core engaged, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, full arm extension at top, ready to pull down, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete arms stretched up holding bar, concentrating face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, full arm extension at top, ready to pull down, front view, no text, no watermark, no logo`

**步骤4 向心下拉**
- 写实风：`photorealistic fitness photography, athlete pulling bar down to collarbone level, elbows driving down and back, lats contracting, chest up, controlled motion, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, bar pulled to upper chest, lats contraction highlighted, elbows driving down, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pulling bar down to chest with effort, determined smile, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, bar pulled to upper chest, lats contraction highlighted, elbows driving down, front view, no text, no watermark, no logo`

**步骤5 底端收缩**
- 写实风：`photorealistic fitness photography, bar held at collarbone, shoulder blades fully retracted, lats peak contraction hold, upright posture, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, bar at collarbone, peak contraction hold, shoulder blades together, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding bar at chest, proud happy face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, bar at collarbone, peak contraction hold, shoulder blades together, front view, no text, no watermark, no logo`

---

### 8. 坐姿划船（Seated Cable Row）｜e8

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e8 / 背部 / 器械 |
| 目标肌群 | 背阔肌中部、菱形肌、斜方肌 |
| 封面图路径 | `assets/images/exercises/e8_seated_row.png` |

**动作描述**：坐姿划船重点锻炼背部中部肌群，改善体态和背部厚度。

**训练步骤**：
1. **准备姿势**：坐于划船机上，双脚踩实踏板，膝盖微屈，双手握把手，挺胸收腹，脊柱保持中立位，核心收紧稳定。要点：脊柱中立位、双脚踩实踏板。
2. **离心前送**：控制把手缓慢前送至手臂自然伸直，背阔肌充分拉伸，肩胛前引放松，背部保持平直不弓背，吸气。要点：前送保持背部平直、肩胛前引放松。
3. **起始位置**：双臂自然伸直，肩胛前引，背部平直，躯干稳定不前后晃动，准备背阔肌发力后拉把手。要点：躯干稳定不晃动、双臂自然伸直。
4. **向心后拉**：背阔肌发力，肘部贴身向后拉把手至腹部，肩胛后缩，呼气，肘部不外展，躯干不后仰借力。要点：肘部贴身拉至腹部、躯干不后仰借力。
5. **顶端收缩**：把手拉至腹部，肩胛充分后缩，背阔肌顶峰收缩 1 秒，控制还原，完成一次重复，保持脊柱中立。要点：肩胛充分后缩、顶峰收缩 1 秒。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete seated at cable row machine pulling handle to abdomen, legs extended with feet on platform, torso upright, back muscles contracted, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete seated pulling handle to abdomen, back muscles highlighted, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete seated rowing handle to belly, effort smile, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete seated pulling handle to abdomen, back muscles highlighted, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete seated at cable row machine, feet on platform, knees slightly bent, holding handle, upright spine, chest out, core engaged, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, seated upright at row machine, feet on platform, neutral spine, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete seated holding row handle, ready pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, seated upright at row machine, feet on platform, neutral spine, side view, no text, no watermark, no logo`

**步骤2 离心前送**
- 写实风：`photorealistic fitness photography, athlete slowly letting handle go forward until arms straight, back muscles stretched, shoulder blades protracting, back flat, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, handle moving forward to straight arms, back stretch, controlled motion, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pushing handle forward, relaxed face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, handle moving forward to straight arms, back stretch, controlled motion, side view, no text, no watermark, no logo`

**步骤3 起始位置**
- 写实风：`photorealistic fitness photography, athlete arms fully extended holding handle, shoulder blades protracted, flat back, stable torso, ready position, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, arms extended forward, flat back, ready to pull, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete arms stretched forward holding handle, calm face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, arms extended forward, flat back, ready to pull, side view, no text, no watermark, no logo`

**步骤4 向心后拉**
- 写实风：`photorealistic fitness photography, athlete pulling handle to abdomen, elbows close to body driving back, shoulder blades squeezing, back muscles contracted, torso stable, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, handle pulled to abdomen, elbows close to body, back contraction highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pulling handle to belly with effort, sweat drop, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, handle pulled to abdomen, elbows close to body, back contraction highlighted, side view, no text, no watermark, no logo`

**步骤5 顶端收缩**
- 写实风：`photorealistic fitness photography, handle held at abdomen, shoulder blades fully retracted, back peak contraction hold, neutral spine, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, handle at abdomen, peak contraction hold, shoulder blades together, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding handle at belly, proud satisfied face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, handle at abdomen, peak contraction hold, shoulder blades together, side view, no text, no watermark, no logo`

---

### 9. 杠铃深蹲（Barbell Squat）｜e9

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e9 / 腿部 / 杠铃 |
| 目标肌群 | 股四头肌、臀大肌、核心肌群 |
| 封面图路径 | `assets/images/exercises/e9_barbell_squat.png` |

**动作描述**：深蹲是腿部训练之王，全面刺激股四头肌、臀大肌和核心肌群。

**训练步骤**：
1. **准备姿势**：杠铃置于斜方肌上沿（高杠位），双脚与肩同宽，脚尖略外展 15-30 度，挺胸收腹，核心收紧，肘部下压。要点：杠铃置于斜方肌上沿、脚尖外展 15-30 度。
2. **离心下蹲**：髋部后坐同时屈膝下蹲，膝盖沿脚尖方向，背部保持中立，下蹲过程吸气，重心保持在足中位置。要点：髋部后坐屈膝、重心在足中。
3. **底端平行**：下蹲至大腿与地面平行或略低于平行，髋部低于膝盖，保持核心紧绷，背部不圆，膝盖不内扣。要点：大腿至少与地面平行、背部中立不圆。
4. **向心起立**：足中发力，臀部和股四头肌同步发力站起，呼气，膝盖不内扣，保持外展与脚尖方向一致。要点：足中发力站起、膝盖不内扣。
5. **顶端锁定**：站起至髋膝完全伸展（不锁死膝关节），核心收紧，挺胸，完成一次重复，注意全程背部中立。要点：膝关节不锁死、核心收紧挺胸。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete with barbell across upper back squatting down with thighs parallel to ground, back straight, knees tracking over toes, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete squatting with barbell on upper back, thighs parallel to floor, back straight, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete squatting with barbell on shoulders, squatting pose, effort face, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete squatting with barbell on upper back, thighs parallel to floor, back straight, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete standing upright with barbell resting on upper traps, feet shoulder width apart, toes slightly pointed out, chest up, core tight, elbows down, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, standing with barbell on upper back, feet shoulder width, chest up, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete standing with barbell on shoulders, ready pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, standing with barbell on upper back, feet shoulder width, chest up, side view, no text, no watermark, no logo`

**步骤2 离心下蹲**
- 写实风：`photorealistic fitness photography, athlete squatting down with hips pushing back and knees bending following toes, back straight, weight on mid-foot, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, squatting down, hips back, knees over toes, neutral back, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete bending knees to squat down, concentrating, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, squatting down, hips back, knees over toes, neutral back, side view, no text, no watermark, no logo`

**步骤3 底端平行**
- 写实风：`photorealistic fitness photography, athlete at bottom of squat with thighs parallel to ground, hips below knees, core tight, back neutral, knees not caving inward, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, bottom squat position, thighs parallel to floor, neutral spine, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete at deepest squat, determined clenched face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, bottom squat position, thighs parallel to floor, neutral spine, side view, no text, no watermark, no logo`

**步骤4 向心起立**
- 写实风：`photorealistic fitness photography, athlete driving through mid-foot to stand up, glutes and quads contracting, hips and knees extending together, knees tracking over toes, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, standing up from squat, legs contraction highlighted, knees aligned with toes, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete standing up from squat with effort, sweat drops, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, standing up from squat, legs contraction highlighted, knees aligned with toes, side view, no text, no watermark, no logo`

**步骤5 顶端锁定**
- 写实风：`photorealistic fitness photography, athlete standing tall with hips and knees fully extended not locked, core tight, chest up, back neutral, finishing position, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, standing upright at top, hips extended not locked, chest up, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete standing tall with barbell, happy proud smile, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, standing upright at top, hips extended not locked, chest up, side view, no text, no watermark, no logo`

---

### 10. 腿举（Leg Press）｜e10

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e10 / 腿部 / 器械 |
| 目标肌群 | 股四头肌、臀大肌 |
| 封面图路径 | `assets/images/exercises/e10_leg_press.png` |

**动作描述**：腿举机可以安全地使用大重量训练腿部，主要锻炼股四头肌和臀大肌。

**训练步骤**：
1. **准备姿势**：坐于腿举机，背部紧贴靠垫，双脚与肩同宽放在踏板中上部，脚尖略外展，双手握两侧把手稳定身体。要点：双脚与肩宽踏板中上部、背部紧贴靠垫。
2. **离心下放**：控制踏板缓慢下放至大腿贴近胸部（膝关节约 90 度），下放过程吸气，核心收紧，膝盖不内扣。要点：下放至膝关节约 90 度、膝盖不内扣。
3. **底端停顿**：大腿贴近胸部时停顿 0.5-1 秒，不弹回，保持核心紧绷，臀部不离靠垫，膝关节不超脚尖。要点：底端停顿不弹回、臀部不离靠垫。
4. **向心蹬起**：足跟发力蹬起踏板，股四头肌和臀大肌同步发力，呼气，保持膝盖与脚尖方向一致不内扣。要点：足跟发力蹬起、膝盖沿脚尖方向。
5. **顶端锁定**：蹬至腿部接近伸直但不锁死膝关节，保持张力，完成一次重复，注意全程控制不甩动借力。要点：不锁死膝关节、保持张力不甩动。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete seated in leg press machine with feet on platform shoulder width apart, legs bent pressing platform, quadriceps and glutes engaged, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete seated in leg press machine pushing platform, legs bent, quads highlighted, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete sitting in leg press machine pushing plate with legs, effort smile, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete seated in leg press machine pushing platform, legs bent, quads highlighted, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete seated in leg press machine, back against padded support, feet on platform shoulder width apart, legs fully extended not locked, hands on side handles, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, seated in leg press machine, feet on platform, legs extended not locked, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete sitting in leg press machine with legs extended, ready pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, seated in leg press machine, feet on platform, legs extended not locked, side view, no text, no watermark, no logo`

**步骤2 离心下放**
- 写实风：`photorealistic fitness photography, athlete slowly lowering platform as knees bend toward chest at 90 degrees, core tight, knees tracking over toes, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, platform lowering, knees bending to 90 degrees, controlled motion, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete bending knees to bring platform down, focused face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, platform lowering, knees bending to 90 degrees, controlled motion, side view, no text, no watermark, no logo`

**步骤3 底端停顿**
- 写实风：`photorealistic fitness photography, athlete at bottom of leg press with thighs near chest, knees at 90 degrees, brief pause, hips stable on pad, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, bottom position knees at 90 degrees, paused, stable hips, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding bottom position, concentrated face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, bottom position knees at 90 degrees, paused, stable hips, side view, no text, no watermark, no logo`

**步骤4 向心蹬起**
- 写实风：`photorealistic fitness photography, athlete pressing platform away through heels, quadriceps and glutes contracting, knees extending aligned with toes, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, pushing platform away with legs, quads and glutes highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pushing platform with both legs, effort sweat drop, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, pushing platform away with legs, quads and glutes highlighted, side view, no text, no watermark, no logo`

**步骤5 顶端锁定**
- 写实风：`photorealistic fitness photography, athlete with legs nearly straight not locked on platform, tension maintained, controlled position, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, legs nearly extended not locked, tension held, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete legs almost straight on platform, proud satisfied face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, legs nearly extended not locked, tension held, side view, no text, no watermark, no logo`

---

### 11. 哑铃推举（Dumbbell Shoulder Press）｜e11

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e11 / 肩膀 / 哑铃 |
| 目标肌群 | 三角肌中束、三角肌前束、肱三头肌 |
| 封面图路径 | `assets/images/exercises/e11_dumbbell_shoulder_press.png` |

**动作描述**：哑铃推举主要锻炼三角肌中束和前束，是肩部训练的核心动作。

**训练步骤**：
1. **准备姿势**：坐于哑铃凳（有靠背），双脚踩实，背部贴靠垫，双手持哑铃于肩部两侧，掌心朝前，肘关节略前于躯干。要点：背部贴靠垫、肘关节略前于躯干。
2. **起始位置**：哑铃位于肩部两侧，掌心朝前，肘关节约呈 90 度，腕关节中立，核心收紧不塌腰，准备三角肌发力。要点：腕关节中立、核心收紧不塌腰。
3. **离心下放**：控制哑铃缓慢下放至肩部两侧，肘关节约 90 度，三角肌充分拉伸，下放过程吸气，保持核心稳定。要点：下放至肘关节 90 度、核心稳定不塌腰。
4. **向心推起**：三角肌发力将哑铃沿弧线推过头顶，呼气，肘部同步伸直，腕关节保持中立，不借力晃动。要点：三角肌发力推起、腕关节中立。
5. **顶端锁定**：推至手臂自然伸直（不锁死），哑铃在头顶上方靠近但不触碰，肩胛稳定，完成一次重复。要点：肘关节不锁死、哑铃顶端不碰撞。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete seated on bench pressing dumbbells overhead, arms extended upward, shoulders engaged, front view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete seated pressing dumbbells overhead, deltoid muscles highlighted, front view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete sitting on bench pushing dumbbells overhead, happy effort face, front view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete seated pressing dumbbells overhead, deltoid muscles highlighted, front view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete seated on bench with back support, feet flat, back against pad, holding dumbbells at shoulder level, palms forward, elbows slightly in front of torso, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, seated with dumbbells at shoulder height, elbows bent 90 degrees, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete seated holding dumbbells at shoulders, ready pose, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, seated with dumbbells at shoulder height, elbows bent 90 degrees, front view, no text, no watermark, no logo`

**步骤2 起始位置**
- 写实风：`photorealistic fitness photography, dumbbells held at shoulder level, palms forward, elbows at 90 degrees, wrist neutral, core tight, back on pad, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells at shoulders, elbows 90 degrees, wrist neutral, ready to press, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbells at shoulder level, concentrating, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells at shoulders, elbows 90 degrees, wrist neutral, ready to press, front view, no text, no watermark, no logo`

**步骤3 离心下放**
- 写实风：`photorealistic fitness photography, athlete lowering dumbbells slowly to shoulder level, elbows at 90 degrees, deltoid muscles stretching, core stable, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells lowering to shoulders, elbows 90 degrees, deltoid stretch, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lowering dumbbells slowly, focused face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells lowering to shoulders, elbows 90 degrees, deltoid stretch, front view, no text, no watermark, no logo`

**步骤4 向心推起**
- 写实风：`photorealistic fitness photography, athlete pressing dumbbells overhead in arc, elbows extending, deltoid muscles contracting, wrist neutral, no body swing, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, pushing dumbbells overhead, shoulders contraction highlighted, elbows extending, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete pushing dumbbells overhead with effort, sweat drops, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, pushing dumbbells overhead, shoulders contraction highlighted, elbows extending, front view, no text, no watermark, no logo`

**步骤5 顶端锁定**
- 写实风：`photorealistic fitness photography, athlete holding dumbbells overhead with arms extended not locked, dumbbells close but not touching, shoulder blades stable, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells overhead not touching, arms extended not locked, finished repetition, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbells overhead, proud happy face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells overhead not touching, arms extended not locked, finished repetition, front view, no text, no watermark, no logo`

---

### 12. 侧平举（Lateral Raise）｜e12

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e12 / 肩膀 / 哑铃 |
| 目标肌群 | 三角肌中束、斜方肌上部 |
| 封面图路径 | `assets/images/exercises/e12_lateral_raise.png` |

**动作描述**：侧平举孤立刺激三角肌中束，帮助打造宽阔的肩膀。

**训练步骤**：
1. **准备姿势**：站姿，双脚与肩同宽，双手各持哑铃于体侧，掌心朝向大腿，肘关节微屈约 10-20 度，挺胸收腹，核心收紧。要点：肘关节微屈 10-20 度、挺胸收腹核心收紧。
2. **离心下放**：控制哑铃从顶端位置缓慢下放至体侧，三角肌中束保持张力，下放过程吸气，不自由落体。要点：控制下放保持张力、不自由落体。
3. **向心侧举**：三角肌中束发力，肘部微屈引导，将哑铃沿弧线向两侧举起，呼气，不耸肩不借力晃动身体。要点：肘部引导侧举、不耸肩不借力。
4. **顶端停顿**：哑铃举至与肩同高（肘部与肩平齐），停顿 1 秒感受中束收缩，不高于肩避免斜方肌过度代偿。要点：顶端与肩平齐、停顿 1 秒感受收缩。
5. **离心还原**：控制哑铃缓慢下放至起始位置，下放过程 3 秒，保持张力，完成一次重复，全程不晃动借力。要点：下放 3 秒控制、全程不晃动借力。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete standing upright raising dumbbells laterally to shoulder height, slight bend in elbows, palms facing down, deltoid muscles highlighted, front view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete standing raising dumbbells to shoulder height at sides, elbows slightly bent, deltoids highlighted, front view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete raising dumbbells out to sides like airplane wings, happy face, front view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete standing raising dumbbells to shoulder height at sides, elbows slightly bent, deltoids highlighted, front view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete standing upright, feet shoulder width apart, dumbbells resting at sides in front of thighs, slight bend in elbows, palms facing each other, core tight, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, standing with dumbbells at sides, elbows slightly bent, ready to raise, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete standing with dumbbells at sides, calm ready face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, standing with dumbbells at sides, elbows slightly bent, ready to raise, front view, no text, no watermark, no logo`

**步骤2 离心下放**
- 写实风：`photorealistic fitness photography, athlete slowly lowering dumbbells from top position back to sides, lateral deltoid keeping tension, controlled descent, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells lowering slowly to sides, tension maintained, controlled motion, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete slowly lowering dumbbells, relaxed face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells lowering slowly to sides, tension maintained, controlled motion, front view, no text, no watermark, no logo`

**步骤3 向心侧举**
- 写实风：`photorealistic fitness photography, athlete raising dumbbells out to sides in arc, elbows leading slightly bent, lateral deltoid contracting, no shrugging, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells rising to sides in arc, deltoid contraction highlighted, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lifting dumbbells out to sides, effort smile, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells rising to sides in arc, deltoid contraction highlighted, front view, no text, no watermark, no logo`

**步骤4 顶端停顿**
- 写实风：`photorealistic fitness photography, dumbbells at shoulder height, elbows level with shoulders, brief pause feeling contraction, shoulders not raised, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells at shoulder height, pause at top, deltoid contraction hold, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbells at shoulder height, proud pose, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells at shoulder height, pause at top, deltoid contraction hold, front view, no text, no watermark, no logo`

**步骤5 离心还原**
- 写实风：`photorealistic fitness photography, athlete controlling dumbbells down slowly over 3 seconds, tension maintained, no body swing, returning to start, front view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells lowering slowly to sides, tension held, completed repetition, front view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lowering dumbbells slowly, relaxed satisfied face, front view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells lowering slowly to sides, tension held, completed repetition, front view, no text, no watermark, no logo`

---

### 13. 哑铃弯举（Dumbbell Curl）｜e13

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e13 / 手臂 / 哑铃 |
| 目标肌群 | 肱二头肌、前臂 |
| 封面图路径 | `assets/images/exercises/e13_dumbbell_curl.png` |

**动作描述**：哑铃弯举是肱二头肌的经典训练动作，简单有效。

**训练步骤**：
1. **准备姿势**：站姿，双脚与肩同宽，双手各持哑铃自然下垂于体侧，掌心朝前，肘关节微屈并贴紧躯干，挺胸收腹。要点：肘部贴紧躯干、挺胸收腹站姿稳定。
2. **起始位置**：哑铃自然下垂于体侧，掌心朝前，肘关节固定贴身，肩胛下沉，核心收紧，准备肱二头肌发力上弯。要点：肘关节固定贴身、肩胛下沉。
3. **向心上弯**：肱二头肌发力，将哑铃沿弧线弯举至肩部，呼气，肘关节保持固定不前后移动，腕关节中立。要点：肘关节固定不移动、腕关节中立。
4. **顶端收缩**：哑铃弯举至肩部，肱二头肌顶峰收缩 1 秒，肘部保持贴身，不耸肩，小指可微外旋强化收缩。要点：顶峰收缩 1 秒、肘部贴身不耸肩。
5. **离心下放**：控制哑铃缓慢下放至起始位置，下放过程 2-3 秒，肱二头肌保持张力，不甩动借力，完成一次重复。要点：下放 2-3 秒控制、不甩动借力。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete standing upright curling dumbbell toward shoulder, palm facing up, bicep muscle fully contracted, elbow pinned to side, other arm at side, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete curling dumbbell to shoulder, palm up, bicep highlighted, elbow close to body, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete curling dumbbell to shoulder showing off bicep, flexing pose, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete curling dumbbell to shoulder, palm up, bicep highlighted, elbow close to body, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete standing upright, feet shoulder width apart, arms at sides holding dumbbells, palms forward, elbows close to body, chest up, core tight, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, standing with dumbbells at sides, palms forward, elbows close to body, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete standing with dumbbells at sides, ready pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, standing with dumbbells at sides, palms forward, elbows close to body, side view, no text, no watermark, no logo`

**步骤2 起始位置**
- 写实风：`photorealistic fitness photography, dumbbells hanging naturally at sides, palms forward, elbows fixed close to body, shoulder blades down, core tight, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells at sides, elbows fixed close to torso, ready to curl, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbells at sides, calm focused face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells at sides, elbows fixed close to torso, ready to curl, side view, no text, no watermark, no logo`

**步骤3 向心上弯**
- 写实风：`photorealistic fitness photography, athlete curling dumbbell along arc toward shoulder, palm facing up, bicep contracting, elbow fixed without moving forward, wrist neutral, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbell curling to shoulder in arc, bicep contraction highlighted, elbow fixed, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete curling dumbbell up with effort, bicep bulging, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbell curling to shoulder in arc, bicep contraction highlighted, elbow fixed, side view, no text, no watermark, no logo`

**步骤4 顶端收缩**
- 写实风：`photorealistic fitness photography, dumbbell curled to shoulder, bicep peak contraction hold, elbow close to body, no shoulder raise, slight supination, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbell at shoulder, peak contraction hold, bicep highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbell at shoulder, flexing bicep proudly, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbell at shoulder, peak contraction hold, bicep highlighted, side view, no text, no watermark, no logo`

**步骤5 离心下放**
- 写实风：`photorealistic fitness photography, athlete slowly lowering dumbbell back to start over 2-3 seconds, bicep maintaining tension, arm extending fully, no swinging, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbell lowering slowly, tension maintained, controlled motion, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete slowly lowering dumbbell, relaxed face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbell lowering slowly, tension maintained, controlled motion, side view, no text, no watermark, no logo`

---

### 14. 锤式弯举（Hammer Curl）｜e14

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e14 / 手臂 / 哑铃 |
| 目标肌群 | 肱二头肌、肱桡肌、前臂 |
| 封面图路径 | `assets/images/exercises/e14_hammer_curl.png` |

**动作描述**：锤式弯举同时锻炼肱二头肌和肱桡肌，增加手臂整体围度。

**训练步骤**：
1. **准备姿势**：站姿，双脚与肩同宽，双手各持哑铃自然下垂于体侧，掌心相对（中立握），肘关节微屈贴身，挺胸收腹。要点：掌心相对中立握、肘部贴身微屈。
2. **起始位置**：哑铃自然下垂，掌心相对，肘关节固定贴身，肩胛下沉，核心收紧，准备肱二头肌和肱桡肌发力。要点：肘关节固定贴身、肩胛下沉。
3. **向心上弯**：肱二头肌和肱桡肌发力，保持掌心相对，将哑铃沿弧线弯举至肩部，呼气，肘部固定不晃动。要点：保持掌心相对、肘部固定不晃动。
4. **顶端收缩**：哑铃弯举至肩部，肱桡肌顶峰收缩 1 秒，掌心保持相对，肘部贴身不前移，不耸肩借力。要点：肱桡肌顶峰收缩 1 秒、肘部贴身不前移。
5. **离心下放**：控制哑铃缓慢下放至起始位置，下放过程 2-3 秒，保持张力，不借力甩动，完成一次重复。要点：下放 2-3 秒控制、不借力甩动。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete standing upright curling dumbbell to shoulder with neutral grip, palms facing each other, brachialis and bicep engaged, elbow pinned to side, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete curling dumbbell to shoulder with neutral grip, palms facing each other, arm muscles highlighted, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete hammer curling dumbbell to shoulder, thumbs up vibe, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete curling dumbbell to shoulder with neutral grip, palms facing each other, arm muscles highlighted, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete standing upright, feet shoulder width apart, arms at sides holding dumbbells with neutral grip, palms facing each other, elbows close to torso, chest up, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, standing with dumbbells neutral grip, palms facing each other, elbows close to body, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete standing holding dumbbells with neutral grip, ready pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, standing with dumbbells neutral grip, palms facing each other, elbows close to body, side view, no text, no watermark, no logo`

**步骤2 起始位置**
- 写实风：`photorealistic fitness photography, dumbbells hanging naturally with palms facing each other, elbows fixed close to body, shoulder blades down, core tight, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbells at sides neutral grip, elbows fixed close to torso, ready to curl, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbells neutral grip, calm focused face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbells at sides neutral grip, elbows fixed close to torso, ready to curl, side view, no text, no watermark, no logo`

**步骤3 向心上弯**
- 写实风：`photorealistic fitness photography, athlete curling dumbbell toward shoulder maintaining neutral grip, palms facing each other throughout, brachioradialis and bicep contracting, elbow stays pinned to side, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbell curling to shoulder, neutral grip maintained, arm muscles highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete hammer curling dumbbell up, effort face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbell curling to shoulder, neutral grip maintained, arm muscles highlighted, side view, no text, no watermark, no logo`

**步骤4 顶端收缩**
- 写实风：`photorealistic fitness photography, dumbbell curled to shoulder with neutral grip, brachioradialis peak contraction hold, elbow close to body, no shoulder raise, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbell at shoulder neutral grip, peak contraction hold, forearm muscles highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding dumbbell at shoulder, flexing proudly, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbell at shoulder neutral grip, peak contraction hold, forearm muscles highlighted, side view, no text, no watermark, no logo`

**步骤5 离心下放**
- 写实风：`photorealistic fitness photography, athlete slowly lowering dumbbell to start over 2-3 seconds, tension maintained, no swinging, arm extending fully, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dumbbell lowering slowly, tension held, completed repetition, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete slowly lowering dumbbell, relaxed satisfied face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dumbbell lowering slowly, tension held, completed repetition, side view, no text, no watermark, no logo`

---

### 15. 平板支撑（Plank）｜e15

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e15 / 核心 / 自重 |
| 目标肌群 | 腹横肌、深层稳定肌群、竖脊肌 |
| 封面图路径 | `assets/images/exercises/e15_plank.png` |

**动作描述**：平板支撑是核心训练的基础动作，锻炼腹横肌和深层稳定肌群。

**训练步骤**：
1. **准备姿势**：俯卧于垫上，双肘弯曲支撑于肩部正下方，前臂平行贴地，双脚并拢脚尖撑地，身体呈一条直线准备。要点：肘部位于肩部正下方、双脚并拢脚尖撑地。
2. **起始位置**：核心收紧抬起骨盆，身体从头部到脚跟呈一条直线，臀部不撅起不塌陷，颈部中立不抬头。要点：身体一条直线、臀部不撅不塌。
3. **保持稳定**：核心持续收紧，腹部激活，骨盆中立位，肩部远离耳朵，保持均匀呼吸不憋气，维持身体平直。要点：核心持续收紧、均匀呼吸不憋气。
4. **呼吸节奏**：保持自然腹式呼吸，吸气时腹部扩张，呼气时腹部收紧，避免憋气导致血压升高，维持稳定。要点：腹式呼吸节奏、不憋气。
5. **结束**：缓慢下放膝盖至地面，休息放松，避免突然塌腰，逐步增加保持时间，完成一组训练。要点：缓慢下放不塌腰、逐步增加时间。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete in forearm plank position, body forming a straight line from head to heels, elbows directly under shoulders, forearms and toes on floor, core engaged, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete holding forearm plank, straight body line, elbows under shoulders, core highlighted, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete doing plank on elbows, calm smiling face, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete holding forearm plank, straight body line, elbows under shoulders, core highlighted, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete lying face down on mat, elbows bent directly under shoulders, forearms on floor, toes tucked, body ready to lift, core engaged, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, lying on mat on forearms, elbows under shoulders, ready to lift, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lying on mat on elbows, relaxed ready face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, lying on mat on forearms, elbows under shoulders, ready to lift, side view, no text, no watermark, no logo`

**步骤2 起始位置**
- 写实风：`photorealistic fitness photography, athlete lifting body into plank position, straight line from head to heels, core engaged, neutral spine, no sagging or arching, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, body raised in plank, straight line, neutral spine, core highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete raising into plank position, focused face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, body raised in plank, straight line, neutral spine, core highlighted, side view, no text, no watermark, no logo`

**步骤3 保持稳定**
- 写实风：`photorealistic fitness photography, athlete holding stable plank, core fully engaged, pelvis neutral, shoulders away from ears, breathing steadily, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, stable plank hold, core activation highlighted, steady posture, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding plank steady, calm focused smile, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, stable plank hold, core activation highlighted, steady posture, side view, no text, no watermark, no logo`

**步骤4 呼吸节奏**
- 写实风：`photorealistic fitness photography, athlete breathing naturally in plank position, belly expanding on inhale, core tight on exhale, relaxed expression, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, plank with breath rhythm indicated, calm stable posture, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete breathing calmly in plank, peaceful face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, plank with breath rhythm indicated, calm stable posture, side view, no text, no watermark, no logo`

**步骤5 结束**
- 写实风：`photorealistic fitness photography, athlete gently lowering knees to the floor, releasing from plank, relaxing on mat, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, lowering knees to floor, finished set, relaxed posture, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete kneeling down resting, relieved happy face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, lowering knees to floor, finished set, relaxed posture, side view, no text, no watermark, no logo`

---

### 16. 卷腹（Crunch）｜e16

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e16 / 核心 / 自重 |
| 目标肌群 | 腹直肌、腹斜肌 |
| 封面图路径 | `assets/images/exercises/e16_crunch.png` |

**动作描述**：卷腹重点刺激腹直肌上部，是腹部训练的最基本动作。

**训练步骤**：
1. **准备姿势**：仰卧于垫上，双腿屈膝约 90 度，双脚掌着地（或抬腿），双手轻放耳侧，下背部贴紧地面。要点：下背部贴紧地面、双手轻放耳侧不拽头。
2. **起始位置**：骨盆中立，下背贴地，肩胛微离地准备，核心激活，颈部放松不紧张，目视上方方向。要点：下背贴地骨盆中立、颈部放松目视上方。
3. **向心卷起**：腹直肌发力将肩胛骨抬离地面，呼气，脊柱逐节卷起，下背保持贴地，不拽头颈借力。要点：腹直肌发力卷起、下背贴地不拽头颈。
4. **顶端收缩**：肩胛完全离地，腹直肌上部顶峰收缩 1-2 秒，下背不离开地面，目视膝盖方向，保持呼吸。要点：顶峰收缩 1-2 秒、下背不离地。
5. **离心还原**：控制肩胛缓慢下放至离地约 1 厘米（不贴地完全放松），吸气，保持张力，完成一次重复。要点：控制下放保持张力、下放不完全放松。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting with gentle shadows, shallow depth of field, sharp focus on the athlete, clean modern gym background, DSLR photo quality, high detail, athlete lying on mat with knees bent, upper back curled up off the floor, hands placed lightly behind head, abdominal muscles contracted, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete curled up in crunch, knees bent, abs contracted, hands behind head, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete curling up for crunch, effort smile, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete curled up in crunch, knees bent, abs contracted, hands behind head, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 准备姿势**
- 写实风：`photorealistic fitness photography, athlete lying on back on mat, knees bent at 90 degrees, feet flat on floor, hands lightly near ears, lower back pressed into mat, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, lying on back with knees bent, hands near ears, lower back on mat, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete lying on mat with knees bent, hands near head, ready pose, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, lying on back with knees bent, hands near ears, lower back on mat, side view, no text, no watermark, no logo`

**步骤2 起始位置**
- 写实风：`photorealistic fitness photography, pelvis neutral, lower back on floor, shoulder blades slightly lifted, core activated, neck relaxed, gaze upward, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, neutral pelvis, core activated, ready to curl, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete core ready to curl, concentrating, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, neutral pelvis, core activated, ready to curl, side view, no text, no watermark, no logo`

**步骤3 向心卷起**
- 写实风：`photorealistic fitness photography, athlete curling shoulders and upper back off the floor, abdominal muscles contracting, lower back stays on mat, hands not pulling neck, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, curling up, abs contraction highlighted, lower back on floor, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete curling up with effort, sweat drop, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, curling up, abs contraction highlighted, lower back on floor, side view, no text, no watermark, no logo`

**步骤4 顶端收缩**
- 写实风：`photorealistic fitness photography, shoulder blades fully off the floor, upper abs peak contraction hold, lower back stays on mat, gaze toward knees, breathing, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, peak contraction hold, abs highlighted, lower back on mat, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete holding crunch at top, proud focused face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, peak contraction hold, abs highlighted, lower back on mat, side view, no text, no watermark, no logo`

**步骤5 离心还原**
- 写实风：`photorealistic fitness photography, athlete slowly lowering shoulder blades to hover one centimeter off floor, tension maintained, controlled descent, side view, clean modern gym background, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, controlled lowering, tension held, not fully relaxing, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete slowly lowering back down, relaxed face, side view, simple cheerful gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, controlled lowering, tension held, not fully relaxing, side view, no text, no watermark, no logo`

---

### 17. 慢跑（Jogging）｜e17

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e17 / 跑步 / 自重 |
| 目标肌群 | 股四头肌、小腿肌群、心肺 |
| 封面图路径 | `assets/images/exercises/e17_jogging.png` |

**动作描述**：慢跑是低强度有氧运动，适合热身、恢复和燃脂，能有效提升心肺功能。

**训练步骤**：
1. **热身准备**：先进行 5 分钟快走或动态拉伸热身，活动脚踝、膝关节和髋关节，逐步提升心率至目标区间。要点：动态热身 5 分钟、活动踝膝髋关节。
2. **起始配速**：从快走过渡到慢跑，速度以能正常对话为宜（约 60-70% 最大心率），身体微前倾，目视前方。要点：配速能正常对话、身体微前倾目视前方。
3. **保持节奏**：保持均匀呼吸（三步一吸两步一呼）和稳定步伐，前脚掌或全脚掌着地，摆臂自然放松，核心收紧。要点：呼吸节奏均匀、核心收紧摆臂放松。
4. **中段补水**：每 15-20 分钟适量补水（每次 100-150ml），保持电解质平衡，注意心率不超过 70% 最大值。要点：定时少量补水、心率不超 70%。
5. **放松收尾**：结束前逐步减速至快走 3-5 分钟，最后进行下肢静态拉伸（股四头、腘绳、小腿），帮助恢复。要点：逐步减速冷身、下肢静态拉伸。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, golden hour outdoor light, shallow depth of field, sharp focus on the runner, DSLR photo quality, high detail, athlete jogging at steady pace on a park running trail, relaxed running form, slight forward lean, natural arm swing, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete jogging at easy pace on a trail, steady relaxed form, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful outdoor park background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete jogging happily on a park path, cheerful face, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete jogging at easy pace on a trail, steady relaxed form, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 热身准备**
- 写实风：`photorealistic fitness photography, athlete doing dynamic warm-up stretching by a park trail, reaching toward toes, moving hips and knees, athletic wear, outdoor setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dynamic warm-up stretch pose, outdoor park background, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete stretching happily before run, outdoor park, cheerful face, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dynamic warm-up stretch pose, outdoor park background, side view, no text, no watermark, no logo`

**步骤2 起始配速**
- 写实风：`photorealistic fitness photography, athlete transitioning from walking to jogging, comfortable pace, slight forward lean, gaze forward, relaxed expression, park trail, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, jogging start pace, slight forward lean, relaxed form, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete starting to jog, happy relaxed face, side view, simple outdoor background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, jogging start pace, slight forward lean, relaxed form, side view, no text, no watermark, no logo`

**步骤3 保持节奏**
- 写实风：`photorealistic fitness photography, athlete jogging with steady rhythm, natural arm swing, core engaged, mid-foot striking the ground, relaxed breathing, park trail, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, steady jogging rhythm, balanced arm swing, consistent stride, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete jogging steadily, rhythm marks around, focused smile, side view, simple outdoor background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, steady jogging rhythm, balanced arm swing, consistent stride, side view, no text, no watermark, no logo`

**步骤4 中段补水**
- 写实风：`photorealistic fitness photography, athlete pausing briefly at a park water fountain taking a small sip of water, jogging gear, outdoor setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete drinking water bottle during break, park setting, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete drinking water with a water bottle, refreshed happy face, outdoor background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete drinking water bottle during break, park setting, no text, no watermark, no logo`

**步骤5 放松收尾**
- 写实风：`photorealistic fitness photography, athlete cooling down walking slowly, then stretching quadriceps and calves at the trail side, relaxed, outdoor setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, cool-down walking then static leg stretch, park setting, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete cooling down and stretching legs, relieved happy face, outdoor background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, cool-down walking then static leg stretch, park setting, side view, no text, no watermark, no logo`

---

### 18. 间歇跑（Interval Run）｜e18

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e18 / 跑步 / 自重 |
| 目标肌群 | 股四头肌、臀大肌、心肺 |
| 封面图路径 | `assets/images/exercises/e18_interval_run.png` |

**动作描述**：间歇跑通过高低强度交替，提升心肺耐力和燃脂效率，适合进阶训练者。

**训练步骤**：
1. **热身准备**：先慢跑 5-10 分钟热身，动态拉伸下肢，激活臀部和核心，预防拉伤，逐步提升心率准备冲刺。要点：慢跑热身 5-10 分钟、动态拉伸激活核心。
2. **高强度冲刺**：以接近全力（85-95% 最大心率）冲刺跑 30-60 秒，摆臂有力，前脚掌着地，保持正确跑姿。要点：85-95% 最大心率、摆臂有力前脚掌着地。
3. **低强度恢复**：冲刺后转入慢跑或快走 1-2 分钟恢复，心率降至 60-70%，保持轻微活动不静止站立。要点：恢复 1-2 分钟、心率降至 60-70%。
4. **循环重复**：重复冲刺-恢复循环 6-8 组，全程保持核心稳定，注意跑姿不变形，组间适量补水。要点：6-8 组循环、跑姿不变形。
5. **放松收尾**：完成全部组数后慢走 3-5 分钟冷身，进行下肢静态拉伸，补充水分和蛋白质，帮助恢复。要点：慢走冷身 3-5 分钟、下肢静态拉伸。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, bright daylight on running track, shallow depth of field, sharp focus on the runner, DSLR photo quality, high detail, athlete sprinting fast on a running track during high-intensity interval, powerful arm swing, forefoot striking, dynamic motion, three-quarter view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete sprinting on track for interval training, dynamic posture, speed lines, three-quarter view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful track background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete sprinting fast on a track with speed lines, determined fun face, three-quarter view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete sprinting on track for interval training, dynamic posture, speed lines, three-quarter view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 热身准备**
- 写实风：`photorealistic fitness photography, athlete jogging slowly to warm up on track, then dynamic leg stretches, activating hips and core, track setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, warm-up jogging and dynamic stretch on track, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete warming up with stretches on track, relaxed smile, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, warm-up jogging and dynamic stretch on track, no text, no watermark, no logo`

**步骤2 高强度冲刺**
- 写实风：`photorealistic fitness photography, athlete sprinting at near-full effort for 30-60 seconds, powerful arm drive, forefoot striking, correct form, intense expression, running track, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, sprinting at high intensity, powerful posture, speed lines, forefoot strike, track, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete sprinting with all effort, sweat flying, determined face, speed lines, track, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, sprinting at high intensity, powerful posture, speed lines, forefoot strike, track, no text, no watermark, no logo`

**步骤3 低强度恢复**
- 写实风：`photorealistic fitness photography, athlete jogging slowly to recover after sprint, hands relaxed, steady breathing, heart rate dropping, track setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, slow recovery jog, relaxed posture, track, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete slow jogging to catch breath, relieved face, track, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, slow recovery jog, relaxed posture, track, no text, no watermark, no logo`

**步骤4 循环重复**
- 写实风：`photorealistic fitness photography, athlete starting another sprint interval, core stable, running form maintained, repeating sprint-recovery cycle on track, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, cycle loop icons around athlete sprinting again, consistent form, track, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete sprinting again in cycle, repeating loop arrows, determined smile, track, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, cycle loop icons around athlete sprinting again, consistent form, track, no text, no watermark, no logo`

**步骤5 放松收尾**
- 写实风：`photorealistic fitness photography, athlete walking slowly for cool-down then stretching lower legs on track side, hydrated, relaxing, track setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, cool-down walk and leg stretch, track setting, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete cooling down stretching legs, relieved happy face, track, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, cool-down walk and leg stretch, track setting, no text, no watermark, no logo`

---

### 19. 长距离跑（Long Distance Run）｜e19

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e19 / 跑步 / 自重 |
| 目标肌群 | 股四头肌、小腿肌群、心肺 |
| 封面图路径 | `assets/images/exercises/e19_long_run.png` |

**动作描述**：长距离跑培养持久耐力，锻炼心肺功能和下肢肌肉耐力，适合马拉松备战。

**训练步骤**：
1. **充分热身**：进行 10 分钟动态热身，重点活动髋关节、膝关节和踝关节，慢跑过渡激活心肺，避免冷启动受伤。要点：动态热身 10 分钟、慢跑过渡激活心肺。
2. **起始配速**：以低于目标配速 1 分钟的速度起步 2-3 公里，逐步进入匀速区间，避免起跑过快导致后程掉速。要点：低于目标配速起步、逐步进入匀速。
3. **匀速跑**：保持稳定的中等配速，呼吸节奏三步一吸两步一呼，核心稳定，步频 170-180 步/分钟。要点：呼吸节奏稳定、步频 170-180。
4. **补充水分能量**：每 15-20 分钟补水 100-150ml，每 45 分钟补充能量胶或电解质，防止脱水和糖原耗尽。要点：定时补水补能量、防止糖原耗尽。
5. **放松收尾**：结束前 1 公里逐步减速，慢走 3-5 分钟冷身，充分拉伸下肢和髋部，补充碳水蛋白质恢复。要点：逐步减速冷身、充分拉伸恢复。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, scenic long-distance running route along a lakeside road, soft morning light, shallow depth of field, sharp focus on the runner, DSLR photo quality, high detail, athlete running steady endurance pace on a long road, consistent stride, relaxed upper body, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete running steady long-distance pace along scenic road, consistent stride, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful outdoor background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete running along a long scenic road, determined cheerful face, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete running steady long-distance pace along scenic road, consistent stride, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 充分热身**
- 写实风：`photorealistic fitness photography, athlete doing 10 minutes of dynamic warm-up, hip and ankle mobility drills, then light jog, scenic road setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, dynamic warm-up drills and light jog, outdoor road, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete doing warm-up stretches by the road, cheerful face, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, dynamic warm-up drills and light jog, outdoor road, no text, no watermark, no logo`

**步骤2 起始配速**
- 写实风：`photorealistic fitness photography, athlete starting at slower pace than target, gradual build, relaxed breathing, long road ahead, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, starting slow pace, long road perspective, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete starting jogging slowly, calm smile, road with distance markers, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, starting slow pace, long road perspective, no text, no watermark, no logo`

**步骤3 匀速跑**
- 写实风：`photorealistic fitness photography, athlete holding steady medium pace, stable breathing rhythm, core stable, cadence 170-180 steps per minute, consistent form, road setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, steady pace running, rhythm marks, consistent stride, road, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete running at steady pace, focused relaxed face, road, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, steady pace running, rhythm marks, consistent stride, road, no text, no watermark, no logo`

**步骤4 补充水分能量**
- 写实风：`photorealistic fitness photography, athlete taking water bottle and energy gel mid-run, hydrating at roadside, long run gear, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, athlete drinking water and taking energy gel, road setting, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete drinking water and eating energy gel, refreshed happy face, road, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete drinking water and taking energy gel, road setting, no text, no watermark, no logo`

**步骤5 放松收尾**
- 写实风：`photorealistic fitness photography, athlete slowing down in final kilometer, walking for cool-down, stretching hips and legs by the road, relaxed, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, cool-down walk and hip/leg stretch, road setting, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete cooling down and stretching, relieved satisfied face, road, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, cool-down walk and hip/leg stretch, road setting, no text, no watermark, no logo`

---

### 20. 冲刺跑（Sprint）｜e20

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e20 / 跑步 / 自重 |
| 目标肌群 | 股四头肌、臀大肌、心肺 |
| 封面图路径 | `assets/images/exercises/e20_sprint.png` |

**动作描述**：冲刺跑发展爆发力和速度，全面刺激快肌纤维，提升无氧能力。

**训练步骤**：
1. **充分热身**：进行充分热身，包括慢跑和动态拉伸，激活臀部和腘绳肌，预防肌肉拉伤，提升神经兴奋性。要点：慢跑动态拉伸热身、激活臀部腘绳肌。
2. **起跑加速**：起跑后前 10-20 米逐步加速，身体前倾，前脚掌着地，摆臂有力，重心前移保持推进。要点：逐步加速身体前倾、前脚掌着地摆臂有力。
3. **全力冲刺**：加速至最大速度，保持正确跑姿，摆臂幅度大，步频快，前脚掌着地，目视前方不低头。要点：最大速度保持跑姿、步频快摆臂幅度大。
4. **完全恢复**：每组冲刺间充分休息 2-3 分钟，心率降至 60% 以下，进行 4-6 组，确保每组保持最大速度。要点：休息 2-3 分钟、4-6 组保持最大速度。
5. **放松收尾**：完成全部组数后慢跑或慢走 5 分钟冷身，进行下肢和髋部静态拉伸，防止肌肉僵硬。要点：慢走冷身 5 分钟、下肢静态拉伸。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, bright daylight on a sprint track, shallow depth of field, sharp focus on the runner, DSLR photo quality, high detail, athlete sprinting at maximum speed, explosive powerful posture, big arm swing, forefoot striking, intense determination, motion blur background, three-quarter view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete in explosive sprint pose at max speed, dynamic lines, three-quarter view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful track background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete sprinting super fast with big speed lines, determined excited face, three-quarter view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete in explosive sprint pose at max speed, dynamic lines, three-quarter view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 充分热身**
- 写实风：`photorealistic fitness photography, athlete warming up with light jogging and dynamic stretches, activating glutes and hamstrings, sprint track setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, warm-up jog and dynamic stretch, track, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete warming up stretching by the track, relaxed smile, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, warm-up jog and dynamic stretch, track, no text, no watermark, no logo`

**步骤2 起跑加速**
- 写实风：`photorealistic fitness photography, athlete accelerating from start, body leaning forward, forefoot striking, powerful arm swing, weight driving forward, first 10-20 meters, track, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, explosive start acceleration, forward lean, dynamic posture, track, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete launching into sprint, forward lean, excited face, speed lines, track, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, explosive start acceleration, forward lean, dynamic posture, track, no text, no watermark, no logo`

**步骤3 全力冲刺**
- 写实风：`photorealistic fitness photography, athlete at maximum speed, correct form, big arm swing, fast cadence, forefoot striking, gaze forward, intense focus, track, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, max speed sprint posture, big arm swing, fast stride, dynamic lines, track, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete sprinting at full speed, sweat flying, fierce determined face, big speed lines, track, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, max speed sprint posture, big arm swing, fast stride, dynamic lines, track, no text, no watermark, no logo`

**步骤4 完全恢复**
- 写实风：`photorealistic fitness photography, athlete resting between sprint sets, walking slowly with hands on hips, breathing deeply, heart rate recovering, track setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, rest between sets, walking and deep breathing, track, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete resting hands on hips catching breath, relaxed face, track, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, rest between sets, walking and deep breathing, track, no text, no watermark, no logo`

**步骤5 放松收尾**
- 写实风：`photorealistic fitness photography, athlete cooling down with slow jog or walk for 5 minutes, then static stretching legs and hips, preventing stiffness, track setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, cool-down jog and static stretches, track, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete cooling down stretching, relieved happy face, track, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, cool-down jog and static stretches, track, no text, no watermark, no logo`

---

### 21. 坡度跑（Incline Treadmill Run）｜e21

| 属性 | 内容 |
|:---|:---|
| ID / 分类 / 器械 | e21 / 跑步 / 跑步机 |
| 目标肌群 | 臀大肌、股四头肌、小腿肌群 |
| 封面图路径 | `assets/images/exercises/e21_incline_run.png` |

**动作描述**：坡度跑模拟上坡跑步，强化臀部和股四头肌，同时提升心肺负荷。

**训练步骤**：
1. **调整坡度**：将跑步机坡度调整至 5-8%，先慢走 2 分钟适应坡度，身体微前倾，激活臀部准备坡度跑。要点：坡度 5-8%、慢走 2 分钟适应。
2. **起始配速**：从慢走过渡到慢跑，坡度保持 5-8%，步伐缩小，前脚掌着地，臀部发力蹬地推进。要点：步伐缩小前脚掌着地、臀部发力蹬地。
3. **坡度跑**：身体微前倾，保持稳定节奏，核心收紧，摆臂幅度略大，呼吸节奏均匀，臀部持续发力。要点：身体微前倾、核心收紧臀部发力。
4. **平坡恢复**：坡度跑 1-2 分钟后，降低坡度慢跑恢复 30-60 秒，心率下降后再次提升坡度，交替 5-6 组。要点：交替 5-6 组、恢复 30-60 秒。
5. **放松收尾**：完成全部组数后，坡度归零慢走 3-5 分钟冷身，拉伸小腿、股四头和臀部，恢复肌肉弹性。要点：坡度归零慢走冷身、拉伸小腿臀部。

**封面图提示词**
- 写实风：`photorealistic fitness photography, realistic human anatomy with natural muscle definition, athletic man in sportswear, soft studio lighting in a modern gym, shallow depth of field, sharp focus on the athlete, DSLR photo quality, high detail, athlete running on a treadmill set at an incline, slight forward lean, driving through glutes and quads, sweat, side view, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, modern instructional exercise guide style, Morandi soft color palette with muted pastel tones, simple geometric shapes, clean composition, soft gradient background, clear silhouette, accurate exercise form demonstration, 2D illustration style, athlete running on inclined treadmill, slight forward lean, glutes highlighted, side view, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi-style athlete with big head and rounded soft body, vibrant friendly colors, simple cheerful gym background, playful instructional style, clear and simple pose, thick clean outlines, cute athlete running on inclined treadmill, determined effort face, side view, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, athlete running on inclined treadmill, slight forward lean, glutes highlighted, side view, no text, no watermark, no logo`

**步骤图提示词**

**步骤1 调整坡度**
- 写实风：`photorealistic fitness photography, athlete setting treadmill incline to 5-8 percent, walking slowly to adapt, slight forward lean, modern gym setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, treadmill with incline setting visible, slow walking adapt phase, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete adjusting treadmill incline, curious face, gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, treadmill with incline setting visible, slow walking adapt phase, side view, no text, no watermark, no logo`

**步骤2 起始配速**
- 写实风：`photorealistic fitness photography, athlete transitioning to slow jog on incline, smaller stride, forefoot striking, glutes pushing off, slight forward lean, treadmill, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, jogging on incline, smaller steps, forefoot strike, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete jogging on inclined treadmill, focused smile, gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, jogging on incline, smaller steps, forefoot strike, side view, no text, no watermark, no logo`

**步骤3 坡度跑**
- 写实风：`photorealistic fitness photography, athlete running steadily on incline, slight forward lean, core tight, bigger arm swing, steady breathing, glutes driving, treadmill, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, steady incline run, forward lean, core and glutes highlighted, side view, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete running on incline steadily, sweat drops, effort smile, gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, steady incline run, forward lean, core and glutes highlighted, side view, no text, no watermark, no logo`

**步骤4 平坡恢复**
- 写实风：`photorealistic fitness photography, athlete lowering incline and jogging easy to recover, heart rate coming down, then raising incline again, treadmill, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, flat easy jog recovery phase, incline cycle arrows, treadmill, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete jogging easy on flat treadmill, relieved face, cycle arrows, gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, flat easy jog recovery phase, incline cycle arrows, treadmill, no text, no watermark, no logo`

**步骤5 放松收尾**
- 写实风：`photorealistic fitness photography, athlete setting incline to zero, slow walking cool-down, then stretching calves, quads and glutes by the treadmill, gym setting, DSLR photo quality, no text, no watermark, no logo`
- 插画风：`flat vector fitness illustration, Morandi soft color palette, incline zero cool-down walk and leg stretches, gym setting, soft gradient background, no text, no watermark, no logo`
- 卡通风：`cute cartoon fitness illustration, chibi athlete cooling down and stretching legs, relieved happy face, gym background, thick clean outlines, no text, no watermark, no logo`
- 黑白线条风：`black and white line art illustration, minimalist line drawing style, clean single-weight outlines, monochrome stroke only, no color fill, simple instructional exercise guide style, pure white background, clear silhouette, accurate exercise form demonstration, incline zero cool-down walk and leg stretches, gym setting, no text, no watermark, no logo`

---

## 四、汇总清单

| ID | 动作名称 | 分类 | 步骤数 | 封面图提示词 | 步骤图提示词 |
|:---:|:---|:---:|:---:|:---:|:---:|
| e1 | 杠铃卧推 | 胸部 | 5 | 4 套（写实/插画/卡通/黑白线条） | 5×4 套 |
| e2 | 哑铃飞鸟 | 胸部 | 5 | 4 套 | 5×4 套 |
| e3 | 上斜卧推 | 胸部 | 5 | 4 套 | 5×4 套 |
| e4 | 绳索夹胸 | 胸部 | 5 | 4 套 | 5×4 套 |
| e5 | 引体向上 | 背部 | 5 | 4 套 | 5×4 套 |
| e6 | 杠铃划船 | 背部 | 5 | 4 套 | 5×4 套 |
| e7 | 高位下拉 | 背部 | 5 | 4 套 | 5×4 套 |
| e8 | 坐姿划船 | 背部 | 5 | 4 套 | 5×4 套 |
| e9 | 杠铃深蹲 | 腿部 | 5 | 4 套 | 5×4 套 |
| e10 | 腿举 | 腿部 | 5 | 4 套 | 5×4 套 |
| e11 | 哑铃推举 | 肩膀 | 5 | 4 套 | 5×4 套 |
| e12 | 侧平举 | 肩膀 | 5 | 4 套 | 5×4 套 |
| e13 | 哑铃弯举 | 手臂 | 5 | 4 套 | 5×4 套 |
| e14 | 锤式弯举 | 手臂 | 5 | 4 套 | 5×4 套 |
| e15 | 平板支撑 | 核心 | 5 | 4 套 | 5×4 套 |
| e16 | 卷腹 | 核心 | 5 | 4 套 | 5×4 套 |
| e17 | 慢跑 | 跑步 | 5 | 4 套 | 5×4 套 |
| e18 | 间歇跑 | 跑步 | 5 | 4 套 | 5×4 套 |
| e19 | 长距离跑 | 跑步 | 5 | 4 套 | 5×4 套 |
| e20 | 冲刺跑 | 跑步 | 5 | 4 套 | 5×4 套 |
| e21 | 坡度跑 | 跑步 | 5 | 4 套 | 5×4 套 |
| **合计** | **21 个动作** | **7 类** | **105 步** | **84 张封面图** | **420 张步骤图** |

> **总计：504 张图片提示词**（21 张/动作 × 24 套/张，即每张图 4 种风格）。若选定单一风格生成，则为 **126 张**（21 封面 + 105 步骤）。

---

## 五、图片命名规范

建议按以下规则命名，与代码中的资源路径直接对应：

**封面图**：`{action_id}_{英文动作名}_preview.png`
- 示例：`e1_barbell_bench_press_preview.png`、`e17_jogging_preview.png`

**步骤图**：`{action_id}_{英文动作名}_step{N}.png`（N 为 1-5）
- 示例：`e1_barbell_bench_press_step1.png`、`e17_jogging_step5.png`

**多风格区分**（可选）：在风格间加后缀 `_realistic` / `_flat` / `_cartoon` / `_lineart`
- 示例：`e1_barbell_bench_press_preview_cartoon.png`、`e1_barbell_bench_press_preview_lineart.png`

### 在项目中的存放位置

```
fittrack_flutter/assets/images/exercises/
├── e1_barbell_bench_press.png          # 现有封面图（旧命名）
├── e1_barbell_bench_press_preview.png  # 新封面图（推荐命名）
├── e1_barbell_bench_press_step1.png
├── e1_barbell_bench_press_step2.png
├── ...（e2-e16 同理）
├── e17_jogging_preview.png             # 跑步类动作当前无图，需新生成
├── e17_jogging_step1.png ~ step5.png
├── e18_interval_run_*.png
├── e19_long_run_*.png
├── e20_sprint_*.png
└── e21_incline_run_*.png
```

> 注：目前 `assets/images/exercises/` 下仅有 e1-e16 的封面图（旧命名 `e1_barbell_bench_press.png` 等），e17-e21 跑步类动作没有图片资源，可优先使用本文档提示词生成。

---

## 六、生成参数建议

| 参数 | 封面图 | 步骤图 |
|:---|:---:|:---:|
| 画幅比例 | 1:1（square） | 4:3（landscape） |
| 分辨率 | 1024×1024 | 1024×768 |
| 人物视角 | 侧视图为主、夹胸/下拉类正视图 | 与封面保持一致 |
| 背景 | 写实风：健身房实景；插画风：浅色渐变；卡通风：简洁场景；黑白线条风：纯白背景 | 同左 |
| 负向提示词 | 建议统一追加：`text, watermark, logo, extra fingers, deformed hands, low quality, blurry` | 同左 |

### 各平台使用提示

- **Midjourney**：在提示词末尾追加 `--ar 1:1 --v 6`（封面）或 `--ar 4:3 --v 6`（步骤图）。
- **SDXL / 即梦 / 通义万相**：风格选"摄影写实 / 扁平插画 / 卡通"或直接粘贴提示词；封面图 `image_size` 用 `square`，步骤图用 `landscape_4_3`。
- **统一性建议**：同一动作先固定一种风格生成整套（封面+步骤），保证视觉一致；如需换风格，使用同一条风格前缀即可整体切换。

---

## 七、数据来源说明

本文档所有动作数据（名称、分类、器械、目标肌群、描述、训练步骤与关键要点）均来源于：

- [mock_data.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/mock_data.dart) 中的 `exercises`（L199-L221）、`exerciseDescriptions`（L226-L248）、`exerciseMuscles`（L253-L275）、`exerciseSteps`（L280-L428）
- 动作详情页展示：[exercise_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/exercise_page.dart)

图片生成后，将封面图路径更新到 `mock_data.dart` 的 `exercises` 列表中 `image` 字段，步骤图路径更新到 `exerciseSteps` 中各步骤的 `image` 字段即可完成对接。


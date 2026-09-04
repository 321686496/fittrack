#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""LiftTrack 皮肤墙 —— 扇形 v6（无手，手机更大更清晰，底部收拢扇柄）"""
import math, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1242, 2688
FONT_B = r"C:\Windows\Fonts\msyhbd.ttc"
FONT_R = r"C:\Windows\Fonts\msyh.ttc"
def font(size, bold=True):
    return ImageFont.truetype(FONT_B if bold else FONT_R, size)

SKINS = [
    ("6aac62ea-561f-49df-9b5c-5638c832174c.png", "活力运动", "#FF6B35"),
    ("65e85acd-2184-402a-b0b4-27585b9848e3.png", "硬核铁馆", "#EF4444"),
    ("ea748719-226e-4bd8-8e55-82b5084d88d9.png", "柔美花语", "#EC4899"),
    ("a7737bf5-874e-4891-a2cd-847ce5e20762.png", "长者关怀", "#059669"),
    ("463c0402-6f16-4a89-aa3a-60d8703f5dde.png", "清新极简", "#0EA5E9"),
    ("28287ac7-b2e3-47b7-84f9-cee669efc21e.png", "赛博霓虹", "#D946EF"),
    ("2a6d8d1e-be3d-412f-a971-1ac6c6b0c99b.png", "黑金尊享", "#F59E0B"),
]
BASE = r"d:\app\projects\health_training\assets\ohos\skins"
def hex2rgb(h):
    h=h.lstrip('#')
    return tuple(int(h[i:i+2],16) for i in (0,2,4))

BG=(24,18,20)
img=Image.new("RGB",(W,H),BG)

# ---- 标题（紧凑）----
d=ImageDraw.Draw(img)
d.text(((W-d.textlength("THEMES · 风格主题",font=font(28)))/2,72),
       "THEMES · 风格主题",font=font(28),fill="#FFB98A")
d.text(((W-d.textlength("多种主题",font=font(78)))/2,140),
       "多种主题",font=font(78),fill="#FFFFFF")
d.text(((W-d.textlength("任你挑选",font=font(78)))/2,250),
       "任你挑选",font=font(78),fill="#FFFFFF")
d.text(((W-d.textlength("7 套主题，选择你的训练气场",font=font(26)))/2,376),
       "7 套主题，选择你的训练气场",font=font(26),fill="#B9AAA0")

# ================= 扇形 =================
n=len(SKINS)
full_angle=88
max_deg=full_angle/2
# 扇心（汇聚点）在画面下方中部
HX,HY=W//2, H-560
# 让中心手机最大最清晰，两侧渐小（近大远小）增强扑克扇形景深
card_w_center=210
card_h_center=int(card_w_center*1292/588)   # ~461
Rc=720                        # 中心手机中心到扇心距离
deg_list=[i*(full_angle/(n-1))-max_deg for i in range(n)]

def place(idx,deg):
    fn,name,color=SKINS[idx]
    # 近大远小：中心(deg≈0)最大，两侧缩小
    k=abs(deg)/max_deg   # 0中心,1端
    scl=1-0.35*k
    cw=int(card_w_center*scl)
    ch=int(card_h_center*scl)
    im=Image.open(os.path.join(BASE,fn)).convert("RGB")
    im=im.resize((cw,ch),Image.LANCZOS)
    rad=math.radians(deg)
    cxp=HX+Rc*math.sin(rad)
    # 两侧轻微上收（负余弦减小半径），形成弧形
    cyp=HY-Rc*math.cos(rad)+k*40
    rot=im.rotate(-deg,resample=Image.BICUBIC,expand=True)
    x=int(cxp-rot.width/2)
    y=int(cyp-rot.height/2)
    if x<50: x=50
    if x+rot.width>W-50: x=W-50-rot.width
    if y<470: y=470
    # 阴影
    sh=Image.new("L",(rot.width+36,rot.height+36),0)
    ImageDraw.Draw(sh).rounded_rectangle([18,18,18+rot.width,18+rot.height],20,fill=140)
    sh=sh.filter(ImageFilter.GaussianBlur(15))
    shr=Image.new("RGBA",(rot.width+36,rot.height+36),(0,0,0,0))
    shr.putalpha(sh.point(lambda v:min(v,90)))
    img.paste(shr,(x-18,y-18),shr)
    # 亮度处理：远侧稍暗增强景深
    if k>0.45:
        dim=Image.new("RGB",im.size,(0,0,0))
        im=Image.blend(im,dim,int((k-0.45)*0.35))
    mask=Image.new("L",rot.size,0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,rot.width-1,rot.height-1],16,fill=255)
    img.paste(rot,(x,y),mask)
    ImageDraw.Draw(img).rounded_rectangle([x,y,x+rot.width,y+rot.height],16,
                                          outline=hex2rgb(color),width=4)

# 中心先画(底层)，两端后画？错：中心为主视觉，应最清晰；但要层叠，让中心在最前
order=sorted(range(n),key=lambda i:abs(deg_list[i]))
for idx in order:
    place(idx,deg_list[idx])

# ================= 扇柄收拢（底部金色彩带环）=================
# 放在中心手机正下方，紧贴中心手机底部
band_y=int(HY-Rc+card_h_center/2+16)
d.ellipse([HX-70,band_y-16,HX+70,band_y+16],outline="#E8A93B",width=6)
d.ellipse([HX-56,band_y-6,HX+56,band_y+6],fill="#FFD479")

# ================= 底部色卡 =================
d=ImageDraw.Draw(img)
swatch_y=H-165
cell_w=(W-60)//n
x=(W-cell_w*n)//2
for fn,name,color in SKINS:
    cx2=x+cell_w//2
    d.ellipse([cx2-13,swatch_y,cx2+13,swatch_y+26],fill=hex2rgb(color)+(255,))
    nw=d.textlength(name,font=font(24))
    d.text((x+(cell_w-nw)/2,swatch_y+34),name,font=font(24),fill="#E8DED6")
    x+=cell_w

# ================= CTA =================
btn_w,btn_h=560,84
bx=(W-btn_w)//2
by=H-96
btn=Image.new("RGBA",(W,H),(0,0,0,0))
bd=ImageDraw.Draw(btn)
for yy in range(btn_h):
    t=yy/(btn_h-1)
    c=(int(255-20*t),int(107+55*t),int(53+52*t))
    bd.line([(bx,by+yy),(bx+btn_w,by+yy)],fill=c+(255,))
mask=Image.new("L",(W,H),0)
ImageDraw.Draw(mask).rounded_rectangle([bx,by,bx+btn_w,by+btn_h],radius=btn_h//2,fill=255)
img=img.convert("RGBA")
img.paste(btn,(0,0),mask)
img=img.convert("RGB")
d=ImageDraw.Draw(img)
cta="探索全部主题"
d.text(((W-d.textlength(cta,font=font(32)))/2,by+(btn_h-32)/2),cta,font=font(32),fill="#FFFFFF")

out=r"d:\app\projects\health_training\docs\skin_wall_H_hand_fan.png"
img.save(out)
print("saved",out,img.size)
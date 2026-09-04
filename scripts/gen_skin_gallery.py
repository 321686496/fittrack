#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""LiftTrack 主题皮肤上架截图 - 多规格扇形（相对布局）
支持 App Store 1242x2688 与 鸿蒙/华为 1080x1920
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SIZES = {
    "appstore":  (1242, 2688),
    "harmony":   (1080, 1920),
}

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
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0,2,4))

def render(size_key, out_path):
    W, H = SIZES[size_key]
    BG = (24, 18, 20)
    s = H / 2688.0          # 缩放系数（以 2688 为基准；宽也随比例，但主要按高度）
    # 画布
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)

    # ---- 顶部标题（按 s 缩放）----
    kick = int(30*s)
    d.text(((W-d.textlength("THEMES · 风格主题", font=font(kick)))/2, int(90*s)),
           "THEMES · 风格主题", font=font(kick), fill="#FFB98A")
    t1z = int(88*s)
    d.text(((W-d.textlength("多种主题", font=font(t1z)))/2, int(175*s)),
           "多种主题", font=font(t1z), fill="#FFFFFF")
    d.text(((W-d.textlength("任你挑选", font=font(t1z)))/2, int(175*s)+int(122*s)),
           "任你挑选", font=font(t1z), fill="#FFFFFF")

    # ---- 扇形 ----
    n = len(SKINS)
    full_angle = 80
    start_deg = -full_angle/2
    step = full_angle/(n-1)
    FAN_CY = H - int(420*s)
    scale = W / 1242.0     # 横向缩放
    RAD = int(400 * scale)
    SIDE_MARGIN = int(90*scale)
    card_w = int(180*scale)
    card_h = int(card_w*1292/588)

    deg_list = [start_deg + i*step for i in range(n)]
    order = sorted(range(n), key=lambda i: abs(deg_list[i]), reverse=True)

    def place_fan(idx, deg):
        fn, name, color = SKINS[idx]
        im = Image.open(os.path.join(BASE, fn)).convert("RGB")
        im = im.resize((card_w, card_h), Image.LANCZOS)
        rot = im.rotate(deg, resample=Image.BICUBIC, expand=True, center=(card_w/2, card_h/2))
        rad = math.radians(deg)
        cx = W//2 + RAD * math.sin(rad)
        cy = FAN_CY - RAD * math.cos(rad)
        x = int(cx - rot.width/2)
        y = int(cy - rot.height/2)
        if x < SIDE_MARGIN:
            x = SIDE_MARGIN
        if x + rot.width > W - SIDE_MARGIN:
            x = W - SIDE_MARGIN - rot.width
        # 阴影
        sh = Image.new("L", (rot.width+40, rot.height+40), 0)
        ImageDraw.Draw(sh).rounded_rectangle([20,20,20+rot.width,20+rot.height], int(20*s), fill=150)
        sh = sh.filter(ImageFilter.GaussianBlur(int(15*s)))
        sh_rgba = Image.new("RGBA", (rot.width+40, rot.height+40), (0,0,0,0))
        sh_rgba.putalpha(sh.point(lambda v: min(v, 90)))
        img.paste(sh_rgba, (x-20, y-20), sh_rgba)
        mask = Image.new("L", rot.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([0,0,rot.width-1,rot.height-1], int(16*s), fill=255)
        img.paste(rot, (x, y), mask)
        ImageDraw.Draw(img).rounded_rectangle([x,y,x+rot.width,y+rot.height], int(16*s),
                                              outline=hex2rgb(color), width=max(1,int(3*s)))

    for idx in order:
        place_fan(idx, deg_list[idx])

    # ---- 底部色卡 ----
    lz = int(30*s)
    swatch_y = H - int(340*s)
    cell_w = (W - int(40*s)) // n
    x = (W - cell_w*n)//2
    for fn, name, color in SKINS:
        cx2 = x + cell_w//2
        r = int(17*s)
        d.ellipse([cx2-r, swatch_y, cx2+r, swatch_y+2*r], fill=hex2rgb(color))
        nw = d.textlength(name, font=font(lz))
        d.text((x+(cell_w-nw)/2, swatch_y+2*r+int(14*s)), name, font=font(lz), fill="#EDE4DE")
        x += cell_w

    # ---- CTA ----
    btn_h = int(92*s)
    btn_w = int(560*scale)
    bx = (W-btn_w)//2
    by = H - int(160*s)
    btn = Image.new("RGBA",(W,H),(0,0,0,0))
    bd = ImageDraw.Draw(btn)
    for yy in range(btn_h):
        t = yy/(btn_h-1)
        c = (int(255-20*t), int(107+55*t), int(53+52*t))
        bd.line([(bx,by+yy),(bx+btn_w,by+yy)], fill=c+(255,))
    mask2 = Image.new("L",(W,H),0)
    ImageDraw.Draw(mask2).rounded_rectangle([bx,by,bx+btn_w,by+btn_h], radius=btn_h//2, fill=255)
    img = img.convert("RGBA")
    img.paste(btn,(0,0),mask2)
    img = img.convert("RGB")
    d = ImageDraw.Draw(img)
    cz = int(34*s)
    cta = "探索全部主题"
    d.text(((W-d.textlength(cta,font=font(cz)))/2, by+(btn_h-cz)/2), cta, font=font(cz), fill="#FFFFFF")

    img.save(out_path)
    return img.size

if __name__ == "__main__":
    for k, path in [("appstore", r"d:\app\projects\health_training\docs\skin_gallery_1242x2688.png"),
                    ("harmony",  r"d:\app\projects\health_training\docs\skin_gallery_1080x1920.png")]:
        sz = render(k, path)
        print(k, "saved", path, sz)
#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""LiftTrack 皮肤墙上架图 —— 4 版扇形对比（手机内容均正立可读）"""
import math, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1242, 2688
BG = (24, 18, 20)
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

def base_canvas():
    img = Image.new("RGB", (W, H), BG)
    return img

def header(d, tag="THEMES · 风格主题", t1="多种主题", t2="任你挑选"):
    d.text(((W-d.textlength(tag, font=font(30)))/2, 90), tag, font=font(30), fill="#FFB98A")
    d.text(((W-d.textlength(t1, font=font(88)))/2, 170), t1, font=font(88), fill="#FFFFFF")
    d.text(((W-d.textlength(t2, font=font(88)))/2, 292), t2, font=font(88), fill="#FFFFFF")

def colorbar_footer(d):
    n = len(SKINS)
    lz = 30
    swatch_y = H - 340
    cell_w = (W - 60)//n
    x = (W - cell_w*n)//2
    for fn, name, color in SKINS:
        cx2 = x + cell_w//2
        d.ellipse([cx2-17, swatch_y, cx2+17, swatch_y+34], fill=hex2rgb(color))
        nw = d.textlength(name, font=font(lz))
        d.text((x+(cell_w-nw)/2, swatch_y+44), name, font=font(lz), fill="#EDE4DE")
        x += cell_w

def cta(img):
    btn_w, btn_h = 560, 92
    bx = (W-btn_w)//2
    by = H - 160
    btn = Image.new("RGBA",(W,H),(0,0,0,0))
    bd = ImageDraw.Draw(btn)
    for yy in range(btn_h):
        t = yy/(btn_h-1)
        c = (int(255-20*t), int(107+55*t), int(53+52*t))
        bd.line([(bx,by+yy),(bx+btn_w,by+yy)], fill=c+(255,))
    mask = Image.new("L",(W,H),0)
    ImageDraw.Draw(mask).rounded_rectangle([bx,by,bx+btn_w,by+btn_h], radius=btn_h//2, fill=255)
    img = img.convert("RGBA")
    img.paste(btn,(0,0),mask)
    img = img.convert("RGB")
    d = ImageDraw.Draw(img)
    cta_txt = "探索全部主题"
    d.text(((W-d.textlength(cta_txt,font=font(34)))/2, by+(btn_h-34)/2), cta_txt, font=font(34), fill="#FFFFFF")
    return img

def load_phone(idx, cw, ch=None):
    fn, name, color = SKINS[idx]
    im = Image.open(os.path.join(BASE, fn)).convert("RGB")
    if ch is None:
        ch = int(cw*1292/588)
    im = im.resize((cw, ch), Image.LANCZOS)
    return im, cw, ch, color

def paste_phone(img, im, x, y, color, ch, glow_color=None, shadow=True):
    if shadow:
        sh = Image.new("L", (im.width+40, im.height+40), 0)
        ImageDraw.Draw(sh).rounded_rectangle([20,20,20+im.width,20+im.height], 22, fill=150)
        sh = sh.filter(ImageFilter.GaussianBlur(16))
        sh_rgba = Image.new("RGBA", (im.width+40, im.height+40), (0,0,0,0))
        sh_rgba.putalpha(sh.point(lambda v: min(v, 90)))
        img.paste(sh_rgba, (x-20, y-20), sh_rgba)
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,im.width-1,im.height-1], 16, fill=255)
    img.paste(im, (x, y), mask)
    ImageDraw.Draw(img).rounded_rectangle([x,y,x+im.width,y+im.height], 16,
                                          outline=hex2rgb(color), width=3)

# ============================================================
# 版本 A：正立"孔雀骨扇"——手机正立，底部沿圆弧聚拢、顶部张开成扇面
# ============================================================
def variant_A():
    img = base_canvas(); d = ImageDraw.Draw(img)
    header(d)
    n = len(SKINS)
    # 扇中心点在下方
    CX, CY = W//2, H+80
    max_a = math.radians(42)   # 最大开角
    cw = 176
    ch = int(cw*1292/588)
    # 每台手机底部中心落在以CX,CY为心的圆弧半径R上，顶部沿R'更外层
    R = 460
    R2 = R + ch
    # 计算每台位置：底部中心=(CX+R*sin a, CY - R*cos a)
    order = list(range(n))
    # 先画两端的，中心最后画（盖最上层）
    order.sort(key=lambda i: abs((i-(n-1)/2)))
    for i in order:
        a = -max_a + (2*max_a)*(i/(n-1))
        bx = CX + R*math.sin(a)
        by = CY - R*math.cos(a)
        x = int(bx - cw/2)
        y = int(by - ch)
        im,_,_,color = load_phone(i, cw, ch)
        paste_phone(img, im, x, y, color, ch)
    # 扇轴装饰（底部小圆）
    d.ellipse([CX-14, CY-14, CX+14, CY+14], fill="#FFB98A")
    colorbar_footer(d)
    return cta(img), "A"

# ============================================================
# 版本 B：正立"阶梯扇"——手机正立，左右对称向后错级，像台阶扇形
# ============================================================
def variant_B():
    img = base_canvas(); d = ImageDraw.Draw(img)
    header(d)
    n = len(SKINS)
    cw = 176
    ch = int(cw*1292/588)
    top_y = 470
    step_h = int(ch*0.30)   # 每级高差
    gap_x = 96
    total_w = (n-1)*gap_x + cw
    start_x = (W-total_w)//2
    order = list(range(n))
    order.sort(key=lambda i: abs(i-(n-1)/2), reverse=True)  # 两端先画，中心最后(最上层)
    for i in order:
        x = start_x + i*gap_x
        y = top_y + int(step_h*(n-1-i)) if i <= (n-1)/2 else top_y + int(step_h*i)
        # y 居中对称：两翼高，中心最低最前
        y = top_y + int(step_h*abs(i-(n-1)/2))
        im,_,_,color = load_phone(i, cw, ch)
        paste_phone(img, im, x, y, color, ch)
    colorbar_footer(d)
    return cta(img), "B"

# ============================================================
# 版本 C：正立"扇骨放射"——手机正立从底部扇柄放射（底部收、顶部张）
# ============================================================
def variant_C():
    img = base_canvas(); d = ImageDraw.Draw(img)
    header(d)
    n = len(SKINS)
    CX, CY = W//2, H+60
    max_a = math.radians(52)
    cw = 168
    ch = int(cw*1292/588)
    R = 510
    order = list(range(n))
    order.sort(key=lambda i: abs(i-(n-1)/2))
    for i in order:
        a = -max_a + (2*max_a)*(i/(n-1))
        # 手机底部中心沿扇骨方向，正立
        bx = CX + R*math.sin(a)*0.9
        by = CY - R*math.cos(a)
        x = int(bx - cw/2)
        y = int(by - ch)
        im,_,_,color = load_phone(i, cw, ch)
        paste_phone(img, im, x, y, color, ch)
    colorbar_footer(d)
    return cta(img), "C"

# ============================================================
# 版本 D：正立"双层弧扇"——两行手机排成交错弧面，后排高、前排低
# ============================================================
def variant_D():
    img = base_canvas(); d = ImageDraw.Draw(img)
    header(d)
    n = len(SKINS)
    cw = 150
    ch = int(cw*1292/588)
    # 前排4个（accented），后排3个
    front = [0,2,3,4]   # 活力运动,柔美花语,长者关怀,清新极简
    back  = [1,5,6]     # 硬核铁馆,赛博霓虹,黑金尊享
    # 前排宽摆开
    fgap = 78
    fw = (len(front)-1)*fgap + cw
    fx0 = (W-fw)//2
    fy = 560
    for idx, i in enumerate(front):
        x = fx0 + idx*fgap
        im,_,_,color = load_phone(i, cw, ch)
        paste_phone(img, im, x, fy, color, ch)
    # 后排高一点，错开对齐到前排缝隙
    bgap = 78
    bw = (len(back)-1)*bgap + cw
    bx0 = int(fx0 + (fw-bw)/2)
    by = fy - int(ch*0.38)
    for idx, i in enumerate(back):
        x = bx0 + idx*bgap + (fgap//2 if len(front)>len(back) else 0)
        im,_,_,color = load_phone(i, cw, ch)
        paste_phone(img, im, x, by, color, ch)
    colorbar_footer(d)
    return cta(img), "D"

# ============================================================
# 版本 E：全正立·扇面轮廓（手机垂直，底部沿圆弧聚拢、顶部张开）
# ============================================================
def variant_E():
    img = base_canvas(); d = ImageDraw.Draw(img)
    header(d)
    n = len(SKINS)
    CX, CY = W//2, H + 520    # 虚拟扇心在更下方，使底部切近圆弧
    max_a = math.radians(40)
    cw = 176
    ch = int(cw*1292/588)
    R = 640                   # 底部半径
    order = list(range(n))
    order.sort(key=lambda i: abs(i-(n-1)/2))
    for i in order:
        a = -max_a + (2*max_a)*(i/(n-1))
        bx = CX + R*math.sin(a)
        by = CY - R*math.cos(a)
        x = int(bx - cw/2)
        y = int(by - ch)
        im,_,_,color = load_phone(i, cw, ch)
        paste_phone(img, im, x, y, color, ch)
    colorbar_footer(d)
    return cta(img), "E"

# ============================================================
# 版本 F：全正立·近大远小（中心大、两侧渐小，不倾斜）
# ============================================================
def variant_F():
    img = base_canvas(); d = ImageDraw.Draw(img)
    header(d)
    n = len(SKINS)
    cy_top = 540
    base_w = 230
    base_ch = int(base_w*1292/588)
    order = list(range(n))
    order.sort(key=lambda i: abs(i-(n-1)/2), reverse=True)  # 两端先画
    positions = []
    for i in range(n):
        k = i/(n-1)                  # 0..1
        t = abs(2*k-1)               # 0=中,1=端
        scale = 1 - 0.45*t           # 中心1.0 两侧0.55
        w = base_w*scale
        chh = base_ch*scale
        # x 按中心距排，中心密集、两侧略收
        span = 0.42 + 0.26*t
        off = (k-0.5)*2*span*W
        cx = W//2 + off
        y = cy_top + (base_ch - chh)*0.7   # 两侧略低
        positions.append((i, cx, y, w, chh))
    # 排【底部基线】对齐：让所有手机底部在一条水平线
    max_bottom = 0
    for i,cx,y,w,chh in positions:
        if (y+chh) > max_bottom: max_bottom = y+chh
    order_p = list(range(n))
    order_p.sort(key=lambda i: abs(i-(n-1)/2))
    for i in order_p:
        _, cx, y, w, chh = positions[i]
        y = max_bottom - chh
        x = int(cx - w/2)
        im,_,_,color = load_phone(i, int(w), int(chh))
        paste_phone(img, im, x, int(y), color, int(chh))
    colorbar_footer(d)
    return cta(img), "F"

# ============================================================
# 版本 G：全正立·纯扇骨错位（等大，水平错开成扇叶）
# ============================================================
def variant_G():
    img = base_canvas(); d = ImageDraw.Draw(img)
    header(d)
    n = len(SKINS)
    cw = 170
    ch = int(cw*1292/588)
    # 底部对齐圆弧：中心手机最低，两侧逐渐抬高（错位）
    CX, CY = W//2, H + 300
    max_a = math.radians(46)
    R = 560
    order = list(range(n))
    order.sort(key=lambda i: abs(i-(n-1)/2))
    for i in order:
        a = -max_a + (2*max_a)*(i/(n-1))
        bx = CX + R*math.sin(a)
        by = CY - R*math.cos(a)
        x = int(bx - cw/2)
        y = int(by - ch)
        im,_,_,color = load_phone(i, cw, ch)
        paste_phone(img, im, x, y, color, ch)
    colorbar_footer(d)
    return cta(img), "G"

OUTS = {
    "A": r"d:\app\projects\health_training\docs\skin_wall_A.png",
    "B": r"d:\app\projects\health_training\docs\skin_wall_B.png",
    "E": r"d:\app\projects\health_training\docs\skin_wall_E.png",
    "F": r"d:\app\projects\health_training\docs\skin_wall_F.png",
    "G": r"d:\app\projects\health_training\docs\skin_wall_G.png",
}

if __name__ == "__main__":
    for fn in (variant_A, variant_B, variant_E, variant_F, variant_G):
        img, tag = fn()
        p = OUTS[tag]
        img.save(p)
        print(tag, "saved", p, img.size)
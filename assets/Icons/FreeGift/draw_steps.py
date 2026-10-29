import math
import os

from PIL import Image, ImageDraw, ImageFont

SCALE = 2
W, H = 480, 270
OUT = os.path.dirname(os.path.abspath(__file__))
FONTS = "C:/Windows/Fonts/"

BG = (25, 27, 31)
PANEL = (42, 45, 51)
BLUE = (51, 95, 255)
TEXT = (230, 232, 235)
SUB = (160, 165, 172)
RED = (215, 25, 25)
RED_DARK = (120, 0, 0)


def font(size, bold=False):
    return ImageFont.truetype(FONTS + ("arialbd.ttf" if bold else "arial.ttf"), size * SCALE)


def s(*values):
    return [v * SCALE for v in values]


def base():
    image = Image.new("RGBA", (W * SCALE, H * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(s(0, 0, W - 1, H - 1), radius=18 * SCALE, fill=BG, outline=(80, 84, 92), width=3 * SCALE)
    return image, draw


def play_bar(draw):
    draw.rounded_rectangle(s(150, 18, 462, 96), radius=10 * SCALE, fill=BLUE)
    cx, cy = 306, 57
    draw.polygon(s(cx - 16, cy - 22, cx - 16, cy + 22, cx + 22, cy), fill=(255, 255, 255))


def star(draw, cx, cy, r, fill):
    points = []
    for i in range(10):
        radius = r if i % 2 == 0 else r * 0.45
        angle = -math.pi / 2 + i * math.pi / 5
        points += [cx + radius * math.cos(angle), cy + radius * math.sin(angle)]
    draw.polygon(s(*points), fill=fill)


def bell(draw, cx, cy, fill):
    draw.pieslice(s(cx - 16, cy - 20, cx + 16, cy + 14), 180, 360, fill=fill)
    draw.rectangle(s(cx - 16, cy - 3, cx + 16, cy + 10), fill=fill)
    draw.rectangle(s(cx - 21, cy + 10, cx + 21, cy + 15), fill=fill)
    draw.ellipse(s(cx - 5, cy + 16, cx + 5, cy + 24), fill=fill)


def thumb(draw, cx, cy, fill, flip=False):
    sign = -1 if flip else 1

    def p(x, y):
        return (cx + x, cy + sign * y)

    draw.rectangle(s(*p(-26, -6), *p(-14, 22)) if not flip else s(*p(-26, 22), *p(-14, -6)), fill=fill)
    palm = [p(-10, -6), p(-2, -12), p(4, -30), p(12, -30), p(14, -14), p(28, -14), p(30, -4), p(26, 22), p(-10, 22)]
    draw.polygon(s(*[c for xy in palm for c in xy]), fill=fill)


def arrow(draw, start, control, end):
    points = []
    for i in range(41):
        t = i / 40
        x = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * control[0] + t * t * end[0]
        y = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * control[1] + t * t * end[1]
        points.append((x, y))
    flat = [c for xy in points for c in xy]
    draw.line(s(*flat), fill=RED_DARK, width=24 * SCALE, joint="curve")
    draw.line(s(*flat), fill=RED, width=16 * SCALE, joint="curve")
    (x0, y0), (x1, y1) = points[-4], points[-1]
    angle = math.atan2(y1 - y0, x1 - x0)
    tip = (x1 + 22 * math.cos(angle), y1 + 22 * math.sin(angle))
    left = (x1 + 26 * math.cos(angle + 2.2), y1 + 26 * math.sin(angle + 2.2))
    right = (x1 + 26 * math.cos(angle - 2.2), y1 + 26 * math.sin(angle - 2.2))
    draw.polygon(s(*tip, *left, *right), fill=RED, outline=RED_DARK, width=3 * SCALE)


def label(draw, x, y, text, size=24, fill=TEXT, bold=False, anchor="mm"):
    draw.text(s(x, y), text, font=font(size, bold), fill=fill, anchor=anchor)


def like():
    image, draw = base()
    play_bar(draw)
    bell(draw, 70, 150, SUB)
    label(draw, 70, 200, "Notify", 22, SUB)
    thumb(draw, 250, 158, (255, 255, 255))
    draw.rectangle(s(205, 205, 290, 211), fill=(255, 255, 255))
    draw.rectangle(s(296, 205, 330, 211), fill=SUB)
    draw.rectangle(s(336, 205, 370, 211), fill=SUB)
    label(draw, 222, 236, "Like", 24, TEXT, True)
    thumb(draw, 410, 150, SUB, flip=True)
    arrow(draw, (110, 260), (130, 150), (205, 150))
    return image


def favorite():
    image, draw = base()
    play_bar(draw)
    star(draw, 120, 150, 26, (255, 255, 255))
    label(draw, 120, 205, "Favorite", 24, TEXT, True)
    bell(draw, 300, 150, SUB)
    label(draw, 300, 205, "Notify", 22, SUB)
    arrow(draw, (450, 250), (300, 270), (170, 175))
    return image


def join():
    image, draw = base()
    draw.rounded_rectangle(s(24, 24, 124, 124), radius=12 * SCALE, fill=(255, 170, 0), outline=(255, 255, 255), width=3 * SCALE)
    label(draw, 74, 74, "S", 64, (255, 255, 255), True)
    label(draw, 142, 56, "Sciyth Studio", 30, TEXT, True, "lm")
    label(draw, 142, 96, "Community", 22, SUB, False, "lm")
    draw.rounded_rectangle(s(40, 160, 400, 222), radius=12 * SCALE, fill=BLUE)
    label(draw, 220, 191, "Join Community", 28, (255, 255, 255), True)
    arrow(draw, (470, 120), (460, 190), (410, 195))
    return image


for name, make in (("StepLike", like), ("StepFavorite", favorite), ("StepJoin", join)):
    make().resize((W, H), Image.LANCZOS).save(os.path.join(OUT, f"{name}.png"))
    print(name)

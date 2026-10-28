"""Regenerates every launcher icon from branding/app_icon_source.png.

Usage: python3 branding/make_icon.py branding/app_icon_source.png \
           android/app/src/main/res branding

Adaptive icon (Android 8+): the artwork's logo region is fitted inside the
circular mask (radius 35 of the 108-unit canvas) so no launcher shape clips
it, over a navy gradient matching the artwork. Android 7 and the Play Store
icon use the full artwork. Also writes assets/branding/logo.png for in-app use.
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFilter

SRC, RES, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
# Logo region of the artwork (measured): centre and half-size of the square
# crop, and the half-diagonal of the visible content to keep inside the mask.
CX, CY, HALF, CONTENT_HALF_DIAG = 627, 611, 525, 578
BG_FROM, BG_TO = (1, 0, 6), (2, 30, 102)  # bottom-left -> top-right navy

im = Image.open(SRC).convert('RGBA')


def gradient(n):
    g = Image.new('RGB', (n, n))
    px = g.load()
    for y in range(n):
        for x in range(n):
            t = ((x / n) + (1 - y / n)) / 2
            px[x, y] = tuple(int(a + (b - a) * t) for a, b in zip(BG_FROM, BG_TO))
    return g


crop = im.crop((CX - HALF, CY - HALF, CX + HALF, CY + HALF))
mask = Image.new('L', crop.size, 0)
# Soft rounded-square edge well outside the logo, so no letter is faded.
ImageDraw.Draw(mask).rounded_rectangle([40, 40, crop.size[0] - 40, crop.size[1] - 40], radius=160, fill=255)
crop.putalpha(mask.filter(ImageFilter.GaussianBlur(28)))
canvas_px = int(108 * CONTENT_HALF_DIAG / 35)
fg = Image.new('RGBA', (canvas_px, canvas_px), (0, 0, 0, 0))
fg.alpha_composite(crop, ((canvas_px - crop.size[0]) // 2, (canvas_px - crop.size[1]) // 2))
bg = gradient(512)

# Full artwork without the white outer corners (for legacy/store icons).
art = im.crop((40, 40, im.size[0] - 40, im.size[1] - 40))

for name, k in {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}.items():
    n = int(108 * k)
    fg.resize((n, n), Image.LANCZOS).save(f'{RES}/mipmap-{name}/ic_launcher_foreground.png')
    bg.resize((n, n), Image.LANCZOS).save(f'{RES}/mipmap-{name}/ic_launcher_background.png')
    m = int(48 * k)
    art.resize((m, m), Image.LANCZOS).convert('RGB').save(f'{RES}/mipmap-{name}/ic_launcher.png')
art.resize((512, 512), Image.LANCZOS).convert('RGB').save(f'{OUT}/play_store_icon_512.png')

# In-app logo (About, Home header): the composed adaptive icon, rounded.
comp = bg.resize((432, 432)).convert('RGBA')
comp.alpha_composite(fg.resize((432, 432), Image.LANCZOS))
comp = comp.crop((72, 72, 360, 360))
round_mask = Image.new('L', comp.size, 0)
ImageDraw.Draw(round_mask).rounded_rectangle([0, 0, comp.size[0] - 1, comp.size[1] - 1], radius=64, fill=255)
logo = Image.new('RGBA', comp.size, (0, 0, 0, 0))
logo.paste(comp, (0, 0), round_mask)
os.makedirs('assets/branding', exist_ok=True)
logo.save('assets/branding/logo.png')

# Previews of launcher masks.
for shape in ('circle', 'squircle'):
    n = 432
    c = bg.resize((n, n)).convert('RGBA')
    c.alpha_composite(fg.resize((n, n), Image.LANCZOS))
    vis = c.crop((n * 18 // 108, n * 18 // 108, n * 90 // 108, n * 90 // 108))
    m = Image.new('L', vis.size, 0)
    d = ImageDraw.Draw(m)
    if shape == 'circle':
        d.ellipse([0, 0, vis.size[0] - 1, vis.size[1] - 1], fill=255)
    else:
        d.rounded_rectangle([0, 0, vis.size[0] - 1, vis.size[1] - 1], radius=vis.size[0] // 4, fill=255)
    pv = Image.new('RGBA', vis.size, (240, 240, 240, 255))
    pv.paste(vis, (0, 0), m)
    pv.resize((192, 192), Image.LANCZOS).save(f'{OUT}/preview_{shape}.png')
print('ok')

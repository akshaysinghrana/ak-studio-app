import sys, math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
src, res, out_dir = sys.argv[1], sys.argv[2], sys.argv[3]
im = Image.open(src).convert('RGBA')
# Logo + text region of the source (measured), centred square crop.
cx, cy, half = 627, 660, 450
crop = im.crop((cx - half, cy - half, cx + half, cy + half))
# Feather the crop edges so the square boundary never shows.
mask = Image.new('L', crop.size, 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, crop.size[0], crop.size[1]], radius=200, fill=255)
mask = mask.filter(ImageFilter.GaussianBlur(40))
crop.putalpha(mask)
# Content half-diagonal ~567 px must fit radius 35 of the 108-unit canvas.
canvas_px = int(108 * 567 / 35)
fg_master = Image.new('RGBA', (canvas_px, canvas_px), (0, 0, 0, 0))
fg_master.alpha_composite(crop, ((canvas_px - crop.size[0]) // 2, (canvas_px - crop.size[1]) // 2))
# Background: the original's glow, blurred and darkened (no crisp logo).
bg_master = im.resize((1024, 1024), Image.LANCZOS).filter(ImageFilter.GaussianBlur(60))
bg_master = ImageEnhance.Brightness(bg_master).enhance(0.55)
dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
for name, k in dens.items():
    n = int(108 * k)
    fg_master.resize((n, n), Image.LANCZOS).save(f'{res}/mipmap-{name}/ic_launcher_foreground.png')
    bg_master.resize((n, n), Image.LANCZOS).convert('RGB').save(f'{res}/mipmap-{name}/ic_launcher_background.png')
    # Legacy (API 24-25) icon: the full original artwork.
    m = int(48 * k)
    im.resize((m, m), Image.LANCZOS).convert('RGB').save(f'{res}/mipmap-{name}/ic_launcher.png')
im.resize((512, 512), Image.LANCZOS).convert('RGB').save(f'{out_dir}/play_store_icon_512.png')
# Previews: circle and squircle masks at 192 px.
for shape in ('circle', 'squircle'):
    n = 432
    comp = bg_master.resize((n, n)).convert('RGBA')
    comp.alpha_composite(fg_master.resize((n, n), Image.LANCZOS))
    vis = comp.crop((n * 18 // 108, n * 18 // 108, n * 90 // 108, n * 90 // 108))
    m = Image.new('L', vis.size, 0)
    d = ImageDraw.Draw(m)
    if shape == 'circle':
        d.ellipse([0, 0, vis.size[0] - 1, vis.size[1] - 1], fill=255)
    else:
        d.rounded_rectangle([0, 0, vis.size[0] - 1, vis.size[1] - 1], radius=vis.size[0] // 4, fill=255)
    pv = Image.new('RGBA', vis.size, (240, 240, 240, 255))
    pv.paste(vis, (0, 0), m)
    pv.resize((192, 192), Image.LANCZOS).save(f'{out_dir}/preview_{shape}.png')
print('ok')

#!/usr/bin/env python3
"""Compose emoji PNGs into macOS app icon"""

import math
import os
import shutil
import subprocess
from PIL import Image, ImageDraw

SIZE = 1024
CENTER = SIZE // 2
BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def superellipse_mask(size, n=5):
    img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    r = size / 2 - 2
    points = []
    for deg in range(360):
        t = math.radians(deg)
        cos_t, sin_t = math.cos(t), math.sin(t)
        x = r * abs(cos_t) ** (2 / n) * (1 if cos_t >= 0 else -1)
        y = r * abs(sin_t) ** (2 / n) * (1 if sin_t >= 0 else -1)
        points.append((cx + x, cy + y))
    draw.polygon(points, fill=255)
    return img


def draw_gradient_bg(img, mask):
    pixels = img.load()
    mask_pixels = mask.load()
    top = (88, 86, 214)
    bot = (52, 199, 189)
    for y in range(SIZE):
        t = y / SIZE
        r = int(top[0] + (bot[0] - top[0]) * t)
        g = int(top[1] + (bot[1] - top[1]) * t)
        b = int(top[2] + (bot[2] - top[2]) * t)
        for x in range(SIZE):
            if mask_pixels[x, y] > 0:
                pixels[x, y] = (r, g, b, mask_pixels[x, y])


def load_and_resize(filename, target_size):
    path = os.path.join(BASE_DIR, filename)
    img = Image.open(path).convert("RGBA")
    # Trim transparent edges
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    # Scale to target
    w, h = img.size
    scale = target_size / max(w, h)
    img = img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
    return img


def main():
    # Background
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    mask = superellipse_mask(SIZE)
    draw_gradient_bg(canvas, mask)

    # Load emoji images
    mouse = load_and_resize("emoji_mouse_noto.png", 520)
    updown = load_and_resize("emoji_updown_noto.png", 300)

    # Place mouse in center-top
    mw, mh = mouse.size
    mx = CENTER - mw // 2
    my = CENTER - mh // 2 - 70
    canvas.paste(mouse, (mx, my), mouse)

    # Place up-down arrow bottom-right as badge
    uw, uh = updown.size
    ux = CENTER + 80
    uy = CENTER + 120
    canvas.paste(updown, (ux, uy), updown)

    # Clip to squircle
    result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    result.paste(canvas, (0, 0), mask)

    # Save preview
    preview = os.path.join(BASE_DIR, "icon_preview.png")
    result.save(preview)
    print(f"Preview: {preview}")

    # Create .icns
    iconset = os.path.join(BASE_DIR, "AppIcon.iconset")
    os.makedirs(iconset, exist_ok=True)
    for name, sz in [
        ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
    ]:
        result.resize((sz, sz), Image.LANCZOS).save(os.path.join(iconset, name))

    icns = os.path.join(BASE_DIR, "AppIcon.icns")
    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", icns], check=True)
    shutil.rmtree(iconset)
    print(f"Icon: {icns}")


if __name__ == "__main__":
    main()

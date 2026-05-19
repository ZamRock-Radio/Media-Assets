#!/usr/bin/env python3
"""Add ZamRock Radio watermark to an image.

Usage:
  python3 watermark.py input.jpg [output.jpg]
  python3 watermark.py input.jpg --press

Always saves a copy (never modifies original).
Default output: input_wm_v0.0.1.jpg
--press saves to Media-Assets/Press/releases/ with a timestamp.
"""

import argparse
import os
import subprocess
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

FONT_TAG_CA = "/usr/share/fonts/noto/NotoSansCanadianAboriginal-ExtraBold.ttf"
FONT_TAG_LATIN = "/usr/share/fonts/noto/NotoSans-Black.ttf"
FONT_URL = "/usr/share/fonts/truetype/Bangers.ttf"
WATERMARK_COLOR = "#c8d4e8"
WATERMARK_ALPHA = 200
BG_DARK = "#282828"
PRESS_DIR = os.path.expanduser("~/hub/Media-Assets/Press/releases")


def watermark(img_path: str, out_path: str | None = None, press: bool = False):
    img = Image.open(img_path).convert("RGBA")
    W, H = img.size

    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    font_size_tag = max(int(W * 0.035), 24)

    font_ca = ImageFont.truetype(FONT_TAG_CA, font_size_tag)
    font_lat = ImageFont.truetype(FONT_TAG_LATIN, font_size_tag)
    font_url = ImageFont.truetype(FONT_URL, font_size_tag)

    tagline = "ᘔᗩᗰᘔᗩᗰ ᖴOᖇ ᒪIᖴE"
    url = "ZamRock.net"

    def is_ca(c: str) -> bool:
        return 0x1400 <= ord(c) <= 0x167F

    segments = []
    current = ""
    current_ca = is_ca(tagline[0])
    for c in tagline:
        if is_ca(c) == current_ca:
            current += c
        else:
            segments.append((current, current_ca))
            current = c
            current_ca = is_ca(c)
    segments.append((current, current_ca))

    tag_w = 0
    tag_h = 0
    for text, is_ca_seg in segments:
        f = font_ca if is_ca_seg else font_lat
        b = draw.textbbox((0, 0), text, font=f)
        tag_w += b[2] - b[0]
        tag_h = max(tag_h, b[3] - b[1])

    font_url_size = max(int(W * 0.030), 18)
    font_url = ImageFont.truetype(FONT_URL, font_url_size)
    ub = draw.textbbox((0, 0), url, font=font_url)
    url_w = ub[2] - ub[0]
    url_h = ub[3] - ub[1]

    if url_w > 0 and tag_w > 0 and url_w < tag_w * 0.7:
        target_ratio = tag_w / url_w
        font_url_size = max(int(font_url_size * target_ratio), 1)
        font_url = ImageFont.truetype(FONT_URL, font_url_size)
        ub = draw.textbbox((0, 0), url, font=font_url)
        url_w = ub[2] - ub[0]
        url_h = ub[3] - ub[1]

    pad = int(W * 0.012)
    margin = int(W * 0.015)

    bar_w = max(tag_w, url_w) + pad * 3
    bar_h = url_h + tag_h + pad * 2 + int(pad * 0.5)
    bar_x = W - bar_w - margin
    bar_y = H - bar_h - margin

    draw.rounded_rectangle(
        [bar_x, bar_y, bar_x + bar_w, bar_y + bar_h],
        radius=int(pad * 0.8),
        fill=(*hex_to_rgb(BG_DARK), 180),
    )

    ux = bar_x + pad * 1.5
    uy = bar_y + pad
    draw.text((ux, uy), url, font=font_url,
              fill=(*hex_to_rgb(WATERMARK_COLOR), WATERMARK_ALPHA))

    tx = bar_x + pad * 1.5
    ty = uy + url_h + int(pad * 0.5)
    for text, is_ca_seg in segments:
        f = font_ca if is_ca_seg else font_lat
        draw.text((tx, ty), text, font=f,
                  fill=(*hex_to_rgb(WATERMARK_COLOR), WATERMARK_ALPHA))
        b = draw.textbbox((0, 0), text, font=f)
        tx += b[2] - b[0]

    result = Image.alpha_composite(img, overlay).convert("RGB")

    if out_path is None:
        root, ext = os.path.splitext(img_path)
        out_path = f"{root}_wm_v0.0.1{ext}"
    if press:
        os.makedirs(PRESS_DIR, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        out_path = os.path.join(PRESS_DIR, f"zamrock_press_{ts}.jpg")

    result.save(out_path, quality=95)
    return out_path


def hex_to_rgb(h: str) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Add ZamRock watermark to image")
    parser.add_argument("input", help="Input image path")
    parser.add_argument("output", nargs="?", default=None, help="Output path (optional)")
    parser.add_argument("--press", action="store_true", help="Save to Media-Assets/Press/releases/")
    args = parser.parse_args()
    out = watermark(args.input, args.output, press=args.press)
    print(f"Watermarked: {out}")

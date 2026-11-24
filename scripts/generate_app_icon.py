#!/usr/bin/env python3
"""Build AppIcon.iconset + masked 512px preview from icon-source."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE_CANDIDATES = [
    ROOT / "uploads" / "icon-source.jpg",
    ROOT / "Resources" / "icon-source.jpg",
]
ICONSET = ROOT / "Resources" / "AppIcon.iconset"
PREVIEW_512 = ROOT / "Resources" / "appicon-512.png"
BUNDLE_PREVIEW = ROOT / "Sources" / "PortWatch" / "Resources" / "appicon-512.png"

CANVAS = 1024
BODY = 824
CORNER_RADIUS = 186


def locate_source() -> Path:
    for candidate in SOURCE_CANDIDATES:
        if candidate.is_file():
            return candidate
    raise SystemExit("icon-source.jpg not found; place it in uploads/ or Resources/")


def squircle_mask(size: int, body: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    inset = (size - body) // 2
    draw.rounded_rectangle(
        (inset, inset, size - inset - 1, size - inset - 1),
        radius=radius,
        fill=255,
    )
    return mask.filter(ImageFilter.GaussianBlur(radius=0.6))


def remove_white_fringe(image: Image.Image, mask: Image.Image) -> Image.Image:
    px = image.load()
    mpx = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = px[x, y]
            if mpx[x, y] < 16:
                px[x, y] = (r, g, b, 0)
                continue
            if r > 248 and g > 248 and b > 248:
                # Fade white halo that sits outside the artwork body.
                edge = mpx[x, y] / 255.0
                new_a = int(a * min(1.0, edge * 1.25))
                px[x, y] = (r, g, b, new_a)
    return image


def build_master(src: Path) -> Image.Image:
    raw = Image.open(src).convert("RGBA")
    if raw.size != (CANVAS, CANVAS):
        raw = raw.resize((CANVAS, CANVAS), Image.Resampling.LANCZOS)

    mask = squircle_mask(CANVAS, BODY, CORNER_RADIUS)
    composed = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    composed.paste(raw, (0, 0), mask)
    composed = remove_white_fringe(composed, mask)

    # Subtle macOS-style depth shadow inside the canvas (optional lift).
    shadow = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    inset = (CANVAS - BODY) // 2
    sdraw.rounded_rectangle(
        (inset + 6, inset + 12, CANVAS - inset + 6, CANVAS - inset + 12),
        radius=CORNER_RADIUS,
        fill=(0, 0, 0, 48),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=12))
    out = Image.alpha_composite(shadow, composed)
    return out


def write_iconset(master: Image.Image) -> None:
    ICONSET.mkdir(parents=True, exist_ok=True)
    pairs = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for name, edge in pairs:
        resized = master.resize((edge, edge), Image.Resampling.LANCZOS)
        resized.save(ICONSET / name, format="PNG", optimize=True)

    preview = master.resize((512, 512), Image.Resampling.LANCZOS)
    PREVIEW_512.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW_512, format="PNG", optimize=True)
    BUNDLE_PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(BUNDLE_PREVIEW, format="PNG", optimize=True)


def main() -> None:
    src = locate_source()
    master = build_master(src)
    write_iconset(master)
    print(f"Wrote {ICONSET} and {PREVIEW_512}")


if __name__ == "__main__":
    main()
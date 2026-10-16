#!/usr/bin/env python3
"""Chroma-key + trim + pivot-align helper for Metro Dash sprites.

The AI image generator always renders characters on a flat chroma-green
background (see docs/ASSET_PIPELINE.md). This script turns such a raw render
into a game-ready sprite:

  1. removes the green background (dominance test + despill),
  2. trims to the opaque bounding box,
  3. scales the result to a fixed height,
  4. pastes it into a canvas so the feet sit flush on the bottom edge and the
     body is centered horizontally -- i.e. the bottom-center pivot the renderer
     assumes (docs/TECH_ARCHITECTURE.md, Projection invariants).

Usage:
    python3 tool/slice_sprites.py RAW.png OUT.png [--height 512] [--pad 2]

Whole batch:
    python3 tool/slice_sprites.py --batch docs/art/raw_*.png --out-dir assets/sprites

Notes:
  * pure stdlib + Pillow; no other dependency
  * never touches the raw input files (they stay as provenance in docs/art/)
"""
from __future__ import annotations

import argparse
import glob
import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover - tooling hint
    sys.exit("Pillow is required:  python3 -m pip install pillow")


def chroma_key(img: Image.Image, tolerance: float = 1.35) -> Image.Image:
    """Remove a flat green screen and desaturate the green fringe it leaves."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            # background: green dominates both other channels by a wide margin
            if g > 70 and g > r * tolerance and g > b * tolerance:
                px[x, y] = (r, g, b, 0)
            else:
                # despill: the brighter the green-dominance, the more we pull
                # green back down towards its neighbours -- kills the halo
                dom = g - max(r, b)
                if dom > 8:
                    g = int(g - dom * 0.75)
                    px[x, y] = (r, max(g, 0), b, a)
    return img


def trim(img: Image.Image, alpha_threshold: int = 12) -> Image.Image:
    box = img.getchannel("A").point(lambda v: 255 if v > alpha_threshold else 0).getbbox()
    if box is None:
        raise SystemExit("sprite is fully transparent after chroma key -- check the raw image")
    return img.crop(box)


def align(img: Image.Image, height: int, pad_bottom: int = 0, pad_side: int = 2) -> Image.Image:
    """Scale to `height` and place feet flush at the bottom edge, centered."""
    scale = height / img.height
    new_w = max(1, round(img.width * scale))
    resized = img.resize((new_w, height), Image.LANCZOS)
    canvas = Image.new("RGBA", (new_w + pad_side * 2, height + pad_bottom), (0, 0, 0, 0))
    canvas.paste(resized, (pad_side, pad_bottom), resized)
    return canvas


def process(raw: str, out: str, height: int, pad_bottom: int) -> None:
    img = align(trim(chroma_key(Image.open(raw))), height, pad_bottom)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    img.save(out, optimize=True)
    print(f"{raw}  ->  {out}   {img.width}x{img.height}, {os.path.getsize(out)//1024} KB")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("raw", nargs="?", help="input PNG (chroma-green background)")
    ap.add_argument("out", nargs="?", help="output PNG path")
    ap.add_argument("--height", type=int, default=512, help="target sprite height in px (default 512)")
    ap.add_argument("--pad-bottom", type=int, default=0, help="transparent px under the feet")
    ap.add_argument("--batch", nargs="+", help="glob(s) of raw PNGs")
    ap.add_argument("--out-dir", default="assets/sprites", help="output dir for --batch")
    a = ap.parse_args()

    if a.batch:
        files: list[str] = []
        for pattern in a.batch:
            files.extend(sorted(glob.glob(pattern)))
        if not files:
            return print("no files matched") or 1
        for f in files:
            name = Path(f).stem.replace("-raw", "").replace("_raw", "")
            process(f, str(Path(a.out_dir) / f"{name}.png"), a.height, a.pad_bottom)
        return 0

    if not a.raw or not a.out:
        return print("usage: slice_sprites.py RAW OUT [--height N]   (or --batch)") or 2
    process(a.raw, a.out, a.height, a.pad_bottom)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

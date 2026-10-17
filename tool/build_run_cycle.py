#!/usr/bin/env python3
"""Assemble a consistent 4-frame run cycle from the generated back-view poses.

The image generator will not reliably swap which leg is lifted when asked, so a
cycle built from four independent renders limps: every frame lifts the same
foot. Two things fix that deterministically:

  * a horizontal mirror supplies the opposite stride (the character is seen
    from directly behind, so the flip is invisible in play), and
  * every frame is scaled from ONE reference height -- the tallest pose, which
    is the one with both feet on the ground -- instead of being stretched to a
    fixed height individually, so the body never changes size between frames.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from slice_sprites import chroma_key  # noqa: E402

HEIGHT = 420


def load(path: str, flip: bool) -> Image.Image:
    keyed = chroma_key(Image.open(path))
    img = keyed.crop(keyed.getbbox())
    if flip:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img


def head_metrics(img: Image.Image) -> tuple[float, float]:
    """Width and centre of the hair blob -- the one rigid landmark in a run."""
    a = np.array(img)
    alpha = a[..., 3]
    top = int(np.where(alpha > 128)[0].min())
    height = img.height
    band = a[top : top + max(4, int(height * 0.12))]
    dark = (
        (band[..., 3] > 128)
        & (band[..., 0] < 70)
        & (band[..., 1] < 70)
        & (band[..., 2] < 80)
    )
    _, xs = np.where(dark)
    return float(xs.max() - xs.min() + 1), float((xs.min() + xs.max()) / 2)


def main() -> int:
    art = Path("docs/art")
    poses = {
        "contact_left": load(str(art / "runner-sprite-raw.png"), flip=True),
        "pass": load(str(art / "runner-run3b-raw.png"), flip=False),
        "contact_right": load(str(art / "runner-sprite-raw.png"), flip=False),
        "pass_mirror": load(str(art / "runner-run3b-raw.png"), flip=True),
    }
    # Normalise on the head, not the silhouette: a lifted foot shortens the
    # bounding box, so fitting every frame to the same box made the character
    # grow and shrink through the cycle. The hair blob never changes size.
    metrics = {name: head_metrics(img) for name, img in poses.items()}
    target_head = 59.0  # px, i.e. a ~420 px character at this art style
    out = Path("assets/sprites")
    width = 220
    for i, (name, img) in enumerate(poses.items()):
        head_w, head_cx = metrics[name]
        scale = target_head / head_w
        w = max(1, round(img.width * scale))
        h = max(1, round(img.height * scale))
        resized = img.resize((w, h), Image.LANCZOS)
        canvas = Image.new("RGBA", (width, HEIGHT), (0, 0, 0, 0))
        # keep the head centred, and the lowest foot on the bottom edge
        x = round(width / 2 - head_cx * scale)
        canvas.paste(resized, (x, HEIGHT - h), resized)
        path = out / f"runner_run_{i}.png"
        canvas.save(path, optimize=True)
        print(
            f"{name:14} head={head_w:4.0f}px scale={scale:.3f} -> {path} "
            f"{canvas.width}x{HEIGHT} ({path.stat().st_size // 1024} KB)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

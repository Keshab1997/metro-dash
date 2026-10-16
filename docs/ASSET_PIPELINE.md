# 🎨 ASSET PIPELINE — Metro Dash

> সব asset **repo-তে bundle** হবে (কোনো CDN নয়)। এই ফাইলটাই worker-দের asset "recipe book" — prompt, spec, export নিয়ম সব এখানে।

---

## 0. নীতিমালা

1. **AI-generated, brand-free, original।** কোনো আসল কোম্পানি/মাসকট/লোগো නැо — "Subway Surfers"-এর নাম/চরিত্র কোথাও ব্যবহার হবে না, শুধু ঘরানার feel।
2. **প্রতিটা asset-এর একটাই লিখিত prompt** এই ফাইলে থাকবে (reproducible) — কেউ edit করলে version বাড়বে (`v2`)।
3. **Palette লক:** `lib/core/palette.dart`-এর hex-এর বাইরে নতুন রঙ asset-এ থাকবে না।
4. **Bottom-center pivot, transparent background** (sprites), power-of-two না হলেও চলবে — কিন্তু atlas `≤ 2048²`।
5. কোনো asset `1 MB`-র বেশি নয় (single file); total bundle `≤ 8 MB`।

---

## 1. ✅ যা হয়ে গেছে (locked)

| Asset | Path | Spec | Task |
|---|---|---|---|
| Key art / title backdrop | `docs/art/key-art.png` | 768×1152, golden hour, 3 converging rails, tram + Ambassador taxi + Howrah-ধাঁচের bridge + festival lights + coins | title screen-এর 2-layer parallax (foreground/background আলাদা করে কাটা হবে) |
| Character reference (turnaround) | `docs/art/character-ref.png` | 1408×784, gray bg, standard pose, full body | **সব runner sprite-এর parent reference** — image-to-image edit-এ এটাই দেওয়া হবে |

হিরো চরিত্র (locked): teen, dark curly hair, **teal hoodie** (rolled sleeves), **orange backpack**, dark blue joggers, **black knee pad** (left), **orange/white sneakers**।

---

## 2. Runner sprite set (Worker B-এর দায়িত্ব)

**মূল কৌশল:** `character-ref.png`-কে reference হিসেবে দিয়ে **same-style edit generation** — প্রতিটা ফ্রেম নতুন করে লিখবে না।

### 2.1 Animation list

| Animation | Frames | Loop | Frame spec | Notes |
|---|---|---|---|---|
| `run` | 8 | ✅ | 256×256 | stride cycle; পা+হাত পাল্টা, backpack slight bounce |
| `jump_rise` | 3 | ❌ | 256×256 | crouch-release → stretched → tucked |
| `jump_fall` | 3 | ❌ | 256×256 | spread → brace → ready-land |
| `roll` | 6 | ❌ | 256×192 | tuck, spin 360° (স্লাইড নয়) |
| `hit` | 5 | ❌ | 256×256 | impact → tumble → settle (শেষ ফ্রেমে hold) |
| `idle` | 4 | ✅ | 224×256 | title screen: শ্বাস + হালকা sway |

**Generator prompt (base — প্রতিটা ফ্রেমে frame-নির্দেশ যোগ হবে):**

```
Same original character as the reference image, same outfit, same proportions.
[POSE: running stride, left foot forward, arms opposite]
Side-three-quarter view from behind-left, matching the reference style.
Full body, feet on the ground line, centered, isolated on a plain flat chroma-green (#00FF00) background, no shadow, uniform studio lighting from upper-left.
No text, no letters, no logos, no watermark.
```

> কেন chroma-green bg: post-processing-এ background removal সবচেয়ে নির্ভরযোগ্য (edge artifacts কম)।

### 2.2 Post-process (Python + Pillow)

```bash
python3 -m pip install --quiet pillow numpy
# tool/slice_sprites.py — Batch 1-এ বানানো হবে (Captain A-কে দেবে)
#   1. chroma-key (#00FF00) → alpha
#   2. despill (green rim সরানো)
#   3. bbox trim + bottom-center pivot align (feet line = y=bottom)
#   4. horizontal strip-এ জোড়া (frame order file নামে: run_00.png …)
#   5. 2048² atlas-এ pack + JSON frame table
```

Output: `assets/sprites/runner_atlas.png` + `runner_atlas.json`

---

## 3. World set (Worker A-এর দায়িত্ব)

| Asset | কী | Frames | Spec | Prompt keywords (base-এর সাথে) |
|---|---|---|---|---|
| `rail_tile` | rail pair + sleepers + ballast, sector-এ repeat | 1 (tileable) | 512×512 | `seamless tileable metro rail track segment, wooden sleepers, gray ballast stones, straight top-down three-quarter, no shadows at edges` |
| `rail_switch` | lane merge/edge | 2 | 512×512 | `track junction, switch rails, same style` |
| `props_day` | street props sheet: tea stall, jhalmuri cart, water tank, hanging wires pole, signboard (Bengali script geometry, unreadable-safe) | 6 | 256×256 ea | `kolkata street prop, [PROP], stylized 3D render, golden hour, isolated, transparent-ready plain background` |
| `city_skyline` | দূরের শহর + Howrah truss bridge silhouette | 2 layers | 2048×512 | `distant city skyline with steel truss cantilever bridge silhouette, warm haze, flat layered parallax art` |
| `sky` | sky gradient + sun disc + bird specks | 1 | 1024×512 | `golden hour sky gradient, sun near horizon, faint birds` — তারপর code-এ gradient override ممکن |
| `grass_bank` | দুই পাশের বাঁধ/ঘাস band | 1 tileable | 512×128 | `seamless grass and concrete embankment band, side view, golden hour` |

World-এর প্রতিটা tile **`farZ`-এ fade** হবে — তাই edge-এ hard seam থাকলে camera-তে ধরা পড়বে না, tabu tileable রাখা হবে।

---

## 4. Obstacles & collectibles (Worker C-এর দায়িত্ব)

| ID | Asset | Frames | Spec | Prompt keywords |
|---|---|---|---|---|
| `barrier_low` | রেলিং gate, lাল-sাদা striped | 1 | 256×192 | `low railway crossing barrier gate with red-white stripes, stylized, isolated` |
| `barrier_high` | ঝুলন্ত banner (festival) | 2 (sway) | 320×192 | `hanging festival banner strung across, red and yellow cloth, light sway, isolated` |
| `train` | suburban coach/ট্রাম, side+top | 1 (+1 lit) | 384×256 | `old Kolkata tram / suburban metro coach, teal and cream livery, stylized 3D, side three-quarter` |
| `cones` | cone cluster (3) | 1 | 192×128 | `cluster of three orange traffic cones, worn, isolated` |
| `coin` | spinning coin | 8 | 96×96 | `gold coin with embossed generic tram icon, spin cycle, shiny` |
| `magnet`, `x2`, `sneakers` | powerup pickups | 6 each | 128×128 | `floating powerup icon, [MAGNET / 2X / RUNNING SNEAKER], glowing soft rim` |
| `dust_*` | dust puff | 6 | 128×128 | `stylized dust puff, warm tan` |
| `crash_burst` | hit impact | 6 | 256×256 | `comic impact burst, dust and debris chunks, warm palette` |

---

## 5. UI (Captain)

| Asset | Notes |
|---|---|
| Logo (`metro_dash_logo.png`) | text-as-art; BN + EN দুটো version (font-based fallback OK) |
| Button (9-slice) | `ui_btn_pill.png` — orange fill, cream stroke, 9-slice meta |
| Icons: pause, play, sound-on/off, music, haptics, gear, trophy, coin, retry, home | 24×24 → 96×96 render-এ; এক color: `paper` |
| Panel | `ui_panel.png` 9-slice, cream `#FFF6E6`, soft shadow |

> **UI-তে system font নয়** — বান্ডল করব ২টা font (SIL OFL, brand-free, Bangla+Latin coverage): Google Fonts থেকে `Baloo Da 2` (Bangla display) + `Rubik` (Latin/UI)। License text `assets/fonts/LICENSE-*.txt` সহ commit হবে।

---

## 6. Audio (Captain — Batch 2)

| File | কী | Spec |
|---|---|---|
| `music_day.ogg` | golden-hour loop (dholak-light + synth flute + bass) | 60–90 s seamless loop, 44.1 kHz mono, `-14 LUFS` |
| `music_day_intense.ogg` | একই melody + percussion layer (speed 18+ হলে crossfade) | same tempo/bar |
| `sfx_jump/land/roll/coin_1..5/whoosh/crash/powerup/best/ui/countdown_tick.ogg` | প্রতিটা 0.1–1.2 s | 44.1 kHz mono, peak `-6 dBFS` |

**সোর্স:** (a) Python synthesis (numpy → wav → ogg, tuneable, 100% original), (b) CC0 pack (Kenney/Juhani Junkala-ধাঁচ) — দুটোর মিশ্রণ। যা-ই হোক, প্রতিটার entry এই টেবিলে source+license সহ লেখা হবে।

---

## 7. Export checklist (প্রতিটা asset-এর জন্য worker নিজে চালাবে)

```
[ ] transparent background (alpha) — ไม่มี white/green edge
[ ] bottom-center pivot এ aligned (sprites)
[ ] palette check: নতুন রঙ হলে ডকুমেন্টে justify করা
[ ] file নাম convention: <entity>_<anim>_<frame>.png (lower_snake, zero-padded)
[ ] size budget: single ≤ 1 MB, মোট ≤ 8 MB
[ ] source prompt এই ফাইলে register করা (§1-§6 টেবিলে যোগ) — বাদ দিলে report bounce
[ ] LICENSE: AI-generated হলে "AI-generated (repo internal)" + CC0 হলে pack নাম + license file
```

## 8. Registration table (update-as-you-go)

| Asset group | Owner | Status | Date |
|---|---|---|---|
| key-art, character-ref | Captain | ✅ done | 2026-10-17 |
| runner set | B | ⬜ Batch 1 | — |
| world set | A | ⬜ Batch 1 | — |
| obstacles/coins | C | ⬜ Batch 1 | — |
| UI + fonts | Captain | ⬜ Batch 1 | — |
| audio | Captain | ⬜ Batch 2 | — |

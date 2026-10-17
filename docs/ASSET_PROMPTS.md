# 🎯 ASSET PROMPT SHEET — Metro Dash

> প্রতিটা prompt **self-contained** — একা copy করে paste করলেই কাজ করবে।
> ইংরেজিতেই রাখা হয়েছে (image model ইংরেজি prompt-এ সবচেয়ে ভালো বোঝে)।
> generate-এর পরে কী করতে হবে সেটাও প্রতিটার নিচে দেওয়া আছে।

---

## 0. তিনটা নিয়ম (এই তিনটাই বেশিরভাগ ভুল আটকায়)

1. **এক call = এক asset।** "৪টা prop একসাথে" চাইলে aspect ratio নষ্ট হয়।
2. **Chroma suffix বাদ দিলে sprite কাজ করবে না** — প্রতিটা prop/character prompt-এর শেষে বসাও:

```
Isolated on a completely flat, uniform chroma-key bright green (#00FF00) background
with no gradient, no texture, no shadow on the background and no other objects.
No text, no letters, no numbers, no logos, no watermark.
```

3. **Texture-এ chroma নয়** — texture seamless; ওখানে শুধু:

```
Seamless tileable texture, edges blend perfectly when tiled, no vignette, no border.
No text, no watermark.
```

**Universal style prefix** (character/prop prompt-এর শুরুতে):

```
Stylized-3D mobile game rendering, warm golden-hour light from the upper left,
crisp clean edges, rich material detail.
```

**Generate-এর পর:**

```bash
python3 tool/slice_sprites.py docs/art/<name>-raw.png assets/sprites/<name>.png --height <H>
```

---

## 1. RAIL LINE

### R4 · `texture_sleeper` — কাঠের sleeper (seamless, chroma নয়)

```
A seamless tileable texture, top-down view of one weathered wooden railway
sleeper: dense dark timber grain running lengthwise, deep cracks, one rusty iron
bolt plate and a couple of old spike holes, edges worn and rounded, subtle dust
in the grain. Warm late-afternoon light, even soft lighting with no harsh
directional shadow, uniform detail across the whole frame. Photorealistic but
slightly stylized for a mobile game. Seamless tileable texture, edges blend
perfectly when tiled, no vignette, no border. No text, no watermark, no objects.
```

→ `512×512` → `assets/sprites/texture_sleeper.jpg` · `--height` লাগে না

### R5 · `rail_head_strip` — ইস্পাতের rail head (seamless, chroma নয়)

```
A seamless tileable texture of polished steel railway rail head seen from above:
a bright brushed steel surface with fine lengthwise grinding marks, thin dark
scratches, a few specks of orange rust near the edges, faint oily sheen in the
centre. Even soft lighting from above, no strong directional shadow.
Photorealistic metal, slightly stylized for a mobile game. Seamless tileable
texture, edges blend perfectly when tiled, no vignette, no border. No text, no
watermark, no objects.
```

→ `512×128` → `texture_rail_head.jpg`

### R6 · `prop_signal` — রেল সিগন্যাল

```
[STYLE PREFIX] A single old railway signal post: a grey steel pole on a concrete
base with a rectangular black signal head at the top holding two round lenses,
one glowing red and one dark green, a small metal ladder stub and a faded number
plate without any readable markings. Seen from the front, three-quarter angle,
whole object visible from base to top with generous empty margins.
[CHROMA SUFFIX]
```

→ `--height 460` → `prop_signal.png`

### R7 · `prop_catenary` — overhead electrification mast

```
[STYLE PREFIX] A single overhead electrification mast for a metro rail line:
a tall grey steel lattice pole with a horizontal cantilever arm at the top, a
short dropper wire and a ceramic insulator hanging from the arm, a small concrete
footing at the base. Seen from the front three-quarter, whole structure visible
from footing to the tip of the arm, much taller than it is wide, generous empty
margins on both sides.
[CHROMA SUFFIX]
```

→ `--height 620` → `prop_catenary.png`

### R8 · `prop_marker` — kilometre post

```
[STYLE PREFIX] A small railway distance marker post: a short white concrete
stone with a black painted top band and a slightly chipped edge, standing
upright, about one third as wide as it is tall, generous margins.
[CHROMA SUFFIX]
```

→ `--height 220` → `prop_marker.png`

---

## 2. RUNNER (reference-image দিয়ে chain করো — §6 দেখো)

> **সব ফ্রেমে এই বাক্যাংশ অপরিবর্তিত:**
> `Same original teenage character as the reference image: teal hoodie with rolled sleeves, orange backpack with two straps, dark blue joggers, orange and white sneakers, dark curly hair.`

### P3 · `runner_run_2` — run cycle, ৩য় ফ্রেম

```
Same original teenage character as the reference image: teal hoodie with rolled
sleeves, orange backpack with two straps, dark blue joggers, orange and white
sneakers, dark curly hair. Seen from directly behind, running away from the
camera, mid-stride in the passing phase: the right leg is lifting high behind
him with the knee bent, the left leg is straight and planted, the right arm is
forward. Full body from head to shoes, feet near the bottom edge, centered
horizontally, moderate size with generous empty margins. Uniform studio lighting
from the upper left, no cast shadow.
[CHROMA SUFFIX]
```

→ `--height 420` → `runner_run_2.png`

### P3 · `runner_run_3` — ৪র্থ ফ্রেম

```
Same original teenage character as the reference image: teal hoodie with rolled
sleeves, orange backpack with two straps, dark blue joggers, orange and white
sneakers, dark curly hair. Seen from directly behind, running away from the
camera, mid-stride in the contact phase: both feet close to the ground, the left
foot just landing in front, the right foot pushing off behind, body at its
lowest point, arms relaxed at the sides. Full body from head to shoes, feet near
the bottom edge, centered horizontally, moderate size. Uniform studio lighting
from the upper left, no cast shadow.
[CHROMA SUFFIX]
```

→ `--height 420` → `runner_run_3.png`

### P4 · `runner_roll` — ৪ ফ্রেম

**1** `Same character, starting to duck into a roll: knees bent deeply, torso leaning forward, arms tucking in, backpack rising. Seen from behind, full body visible, centered, generous margins. [CHROMA SUFFIX]`

**2** `Same character, fully tucked into a ball in mid-roll, seen from behind and slightly above: head down, knees to the chest, backpack on top, half a turn completed. Centered. [CHROMA SUFFIX]`

**3** `Same character, three quarters through the roll: body uncurling, one foot reaching for the ground, one hand pushing off, seen from behind. Centered. [CHROMA SUFFIX]`

**4** `Same character, coming out of the roll into a crouched run: one knee low, torso still leaning forward, arms swinging up for balance, seen from directly behind. [CHROMA SUFFIX]`

> ↑ প্রতিটার আগে বসাও: `Same original teenage character as the reference image: teal hoodie, orange backpack, dark blue joggers, orange and white sneakers, dark curly hair. Uniform studio lighting from the upper left, no cast shadow.`

→ প্রতিটা `--height 380` → `runner_roll_0..3.png`

### P5 · `runner_hit` — ৪ ফ্রেম

**1** `chest hitting the obstacle, body jolting backwards, arms flying forward, feet still off the ground, viewed from behind.`
**2** `thrown into the air, body tilted, backpack slipping to one side, legs flailing, viewed from behind.`
**3** `landing on his back on the ground, knees up, one arm out, viewed from behind and slightly above, lying flat.`
**4** `lying still on his back after the crash, arms loose at the sides, backpack under him, viewed from behind and slightly above.`

> ↑ প্রতিটার আগে: `Same original teenage character as the reference image (teal hoodie, orange backpack, dark blue joggers, orange sneakers, dark curly hair), now ` … শেষে `[CHROMA SUFFIX]`

→ `--height 380` → `runner_hit_0..3.png`

### P6 · `runner_idle` — title screen (৪ ফ্রেম)

```
Same original teenage character as the reference image, standing still on the
spot, seen from directly behind, feet together, arms relaxed, chest rising very
slightly, backpack settled on his back. Full body visible, centered, generous
margins. Uniform studio lighting from the upper left, no cast shadow.
[CHROMA SUFFIX]
```

→ `--height 440` → `runner_idle_0..3.png` (চার call, শুধু শ্বাস/ভর বদলাবে)

---

## 3. OBSTACLE

### O6 · `barrier_low_2`

```
[STYLE PREFIX] A worn railway level-crossing barrier in its raised position: one
wooden post with peeling yellow paint and a counterweight arm, a single
red-and-white striped boom tilted diagonally upward, rust on the hinge, a small
red lamp on the post. Slightly wider than it is tall, whole barrier visible from
ground to boom tip, centered with generous empty margins.
[CHROMA SUFFIX]
```

→ `--height 300` → `barrier_low_2.png`

### O7 · `train_side`

```
[STYLE PREFIX] The long side of a suburban metro coach seen at a slight
three-quarter angle from the track: teal and cream livery, a row of large dark
windows, sliding doors, a thin yellow safety stripe along the skirt, roof vents,
slight rust at the panel seams. The coach is much wider than it is tall and
fills the frame edge to edge with a little empty margin at top and bottom.
[CHROMA SUFFIX] No destination sign, no numbers.
```

→ `--height 420` → `train_side.png`

### O8 · `coin_spin` — ৬ ফ্রেম

**0** `A single shiny gold game coin seen face-on, filling most of the frame, thick bevelled rim and an embossed generic old tram silhouette in the centre (no letters, no numbers, no currency symbols). Stylized-3D mobile game rendering, bright warm highlights, soft dark gold shading. [CHROMA SUFFIX]`

**1–5** `The same gold game coin, now turned [22 / 45 / 68 / 90 / 112] degrees around its vertical axis, so it appears progressively narrower and elliptical, the embossed tram tilting with it, the rim catching a bright highlight. Centered, same size and lighting as the reference. [CHROMA SUFFIX]`

→ প্রতিটা `--height 160` → `coin_spin_0..5.png`

### O9 · powerups

```
[STYLE PREFIX] A floating power-up pickup: a chunky horseshoe magnet painted red
with silver tips, glowing with a soft warm rim light, seen face-on, centered,
generous margins. [CHROMA SUFFIX]
```
```
[STYLE PREFIX] A floating power-up pickup: a chunky glossy multiplier badge made
of two stacked gold chevrons forming a double arrow shape, no letters, soft warm
rim glow, face-on, centered, generous margins. [CHROMA SUFFIX]
```
```
[STYLE PREFIX] A floating power-up pickup: a single sneaker with glowing orange
soles and small speed wisps trailing from the heel, seen from the side, centered,
generous margins. [CHROMA SUFFIX]
```

→ `--height 200` → `powerup_magnet.png`, `powerup_x2.png`, `powerup_sneaker.png`

---

## 4. EFFECT (কালো background — chroma নয়)

> suffix: `Isolated on a plain pure black background, no other objects. No text, no watermark.`

### E1 · `dust_puff` — ৫ ফ্রেম

**1** `A small compact puff of warm tan dust just kicked up from gravel, tight ball, few grains at the edges.`
**2** `The same dust puff expanding wider and lower, particles spreading out, still dense in the middle.`
**3** `The dust puff flattened and thinning, individual grains visible at the edges, centre getting lighter.`
**4** `The dust puff almost dissolved, only faint wisps and a few grains remain.`
**5** `Almost nothing left: a very faint haze of dust, ready to disappear.`

→ আগে `Stylized-3D game particle, warm golden-hour colours, crisp detail.` → `--height 200` → `dust_0..4.png`

### E2 · `crash_burst` — ৬ ফ্রেম

**1** `A sharp bright impact flash at the moment of collision, radiating spikes, small debris chunks at the centre.`
**2** `The flash spreading into an irregular burst ring with debris flying outward, warm orange and paper-white.`
**3** `The ring expanding and thinning, larger chunks tumbling outward, centre darkening.`
**4** `Debris slowing, dust mixing in, ring almost gone.`
**5** `Only the dust and a few tumbling chunks remain.`
**6** `Faint dust settling, ready to disappear.`

→ `--height 300` → `crash_0..5.png`

### E3 · `speed_streak`

```
Stylized-3D game effect: a single long thin horizontal speed streak, a tapered
white-warm line fading at both ends, slightly curved, glowing softly. Isolated
on a plain pure black background, no other objects. No text, no watermark.
```

→ `--height 90` → `speed_streak.png`

---

## 5. CITY ও STREET

### C3 · নতুন বাড়ি

```
[STYLE PREFIX] A single four-storey old Kolkata house, pale pink walls with
weathered green shutters, small balconies with iron railings, a clothesline with
sarongs on the top floor, water stains running down the wall, seen from a
three-quarter angle, whole building visible from pavement to rooftop.
[CHROMA SUFFIX]
```
```
[STYLE PREFIX] A single narrow three-storey house with deep blue walls and white
window frames, a rooftop parapet with a small shrine niche, an electrical cable
crossing the facade, seen from a three-quarter angle, whole building visible.
[CHROMA SUFFIX]
```
```
[STYLE PREFIX] A single low single-storey corner tea shop with a tin roof, a
green wooden shutter folded back, a bench outside, steel tumblers on a tray and
a kettle, seen from a three-quarter angle, whole shop visible.
[CHROMA SUFFIX] No signs, no writing, no boards with text.
```

→ প্রতিটা `--height 520` → `house_4.png`, `house_5.png`, `house_6.png`

### C4 · `prop_cart`

```
[STYLE PREFIX] A street tea vendor's wooden hand cart: glass jar of biscuits,
a steel kettle on a small stove, a stack of cups, a folded canopy pole, one
bicycle wheel at the side, blue-painted frame worn at the edges. Seen from a
three-quarter angle, whole cart visible. No lettering.
[CHROMA SUFFIX]
```

→ `--height 300` → `prop_cart.png`

### C5 · `prop_stall`

```
[STYLE PREFIX] A tiny roadside stall under a striped canvas awning on four thin
poles: a wooden counter with stacked fruit crates and hanging garlands of
biscuit packets, a folding chair, an old weighing scale. Seen from a
three-quarter angle, whole stall visible from ground to awning.
[CHROMA SUFFIX] No signs, no writing.
```

→ `--height 380` → `prop_stall.png`

### C6 · night city (Batch 2, seamless)

```
A seamless tileable night skyline of an old Indian city: silhouetted rooftops,
water tanks, antennas, warm lit windows scattered across the buildings, deep
blue-violet sky with a faint orange haze near the horizon, no moon, no stars,
even lighting, uniform detail. Seamless tileable, edges blend perfectly when
tiled, no vignette, no border. No text, no watermark.
```

→ `2048×512` → `city_night.jpg`

---

## 6. ANIMATION chain (সবচেয়ে গুরুত্বপূর্ণ)

Text-only prompt-এ ৮ ফ্রেম বানালে চরিত্র বদলে যাবে। **chain করো:**

```
Frame 0 বানাও → পছন্দ হলে accept
        ↓
Frame 1: reference = Frame 0, prompt = "same character as the reference image, now [NEW POSE]"
        ↓
প্রতিটা পরের ফ্রেমে আগের approved ফ্রেমটাই reference
```

- সব ফ্রেমে **একই `--height`** (run = 420, roll/hit = 380) → scale এক থাকবে
- pixel-art নয়, stylized-3D — তাই ফ্রেম-দরে ছোট তফাত চোখে পড়বে না
- pivot: `slice_sprites.py` নিজেই পা-এর নিচে বসায় (bottom-center)

---

## 7. Generate-এর পর QA

```
[ ] background পুরো flat — কোনো gradient/ছায়া নেই
[ ] sprite সম্পূর্ণ দেখা যাচ্ছে — কোনো দিক কাটা নেই
[ ] দুই দিকে ফাঁকা margin আছে
[ ] কোনো লেখা/সংখ্যা/লোগো নেই      ← সবচেয়ে বেশি বাদ পড়ে
[ ] আলো উপরে-বাঁয়ে (বাকিদের সাথে মিলছে)
[ ] palette-এর বাইরে জ্বলজ্বলে রঙ নেই (docs/ART_DIRECTION.md §3)
```

pass হলে: slice → `docs/ASSET_REQUESTS.md`-এ ⬜ → ✅ → report-এ path।

---

## 8. এক নজরে (target height)

| Asset | Height | ফাইল |
|---|---|---|
| `texture_sleeper`, `texture_rail_head` | 512² / 512×128 | `.jpg` |
| `prop_signal` / `prop_catenary` / `prop_marker` | 460 / 620 / 220 | `.png` |
| `runner_run_2/3` | 420 | `.png` |
| `runner_roll_0..3`, `runner_hit_0..3` | 380 | `.png` |
| `runner_idle_0..3` | 440 | `.png` |
| `barrier_low_2` / `train_side` | 300 / 420 | `.png` |
| `coin_spin_0..5` | 160 | `.png` |
| `powerup_*` | 200 | `.png` |
| `dust_0..4` / `crash_0..5` / `speed_streak` | 200 / 300 / 90 | `.png` |
| `house_4/5/6` | 520 | `.png` |
| `prop_cart` / `prop_stall` | 300 / 380 | `.png` |
| `city_night` | 2048×512 | `.jpg` |

# 🎮 GAME DESIGN — Metro Dash (ডাকনাম: "Kolkata Runner")

> **Repo:** `Keshab1997/dog-road-runner` (নাম পুরনো, গেম নতুন)
> **স্ট্যাটাস:** ডিজাইন লক (2026-10-17) · **কোড:** এখনো শুরু হয়নি (Batch 0-তে পুরনো গেম ডিলিট হবে)
> **ধরন:** 3-lane endless runner · Subway Surfers ঘরানার · Kolkata-themed stylized 3D look

---

## 1. এক লাইনে

তিনটা metros rail লাইনের ওপর দিয়ে দৌড়, gate/ব্যারিয়ার/ট্রেন লাফিয়ে-হেলে পার হও, কয়েন কুড়াও, গোল্ডেন আওয়ারে কলকাতার ছাদ-বাজার-ট্রাম-ব্রিজের ভেতর দিয়ে যত দূর পারো দৌড়াও।

**Pillars (যে ৩টা জিনিস গেমকে "আসল গেম" বানাবে):**

| Pillar | মানে কী |
|---|---|
| **Feel** | প্রতি input-এর সাথে সাথে, ভারী কিন্তু স্ন্যাপি: dust puff, squash-stretch, screen shake, whoosh |
| **Fair** | মৃত্যু কখনো "হয়নি রে" মনে হবে না — spawn director guarantee করে সবসময় একটা escape lane থাকবে |
| **World** | ফ্ল্যাট ২ডি নয় — pseudo-3D perspective, layered parallax, golden-hour আলো; কলকাতার চেনা রঙ |

---

## 2. Core loop

```
Title ──TAP──► 3·2·1·GO ──► RUN (auto-forward, swipe) ──hit──► GAME OVER ──► Retry
                                │                                                  │
                                └────── coins + score ──────────────────────────────┘
                                          save (best, coins)
```

- **Forward:** অটো, player কিছুই করে না — speed ধীরে ধীরে বাড়ে (distance-based)।
- **Player-এর পুরো agency:** lane বদলানো, jump, roll।
- **Run length:** গড় ৬০–৯০ সেকেন্ড; good player ৩০০০m+।
- **Session:** ৩০ সেকেন্ডে এক run possible; "আরেকবার" চাপ সবচেয়ে বড় retention lever।

---

## 3. Camera & space

| জিনিস | লক করা মান |
|---|---|
| Camera type | chase cam, runner-এর পিছনে-উপরে, world-এ fixed (runner camera-র দিকে ধাবমান) |
| Camera height | `2.6 u` · **distance** `6.5 u` পিছনে · look-at runner + `1.2 u` উপরে |
| FOV | ~55° (perspective projection, `f = h/2 / tan(fov/2)`) |
| Lane change-এ | camera `±0.25 u` lateral ease + `±2°` roll (juice) |
| Ground | `y = 0` = rail-top plan · `x ∈ {−1, 0, +1}` = তিন lane (`1 u` = `1 m`) |
| Render | sprite-scaling, back-to-front painter's sort by `z` (Flame `Renderable` sort) |
| Unit scale | runner `1.75 u` লম্বা · lane width `1.0 u` · rail gauge `0.75 u` |

**Projection (একটাই ফাংশন, সব entity এর জন্য):**

```dart
// world (x,y,z) → screen (sx, sy, scale)
final dz = z - cam.z;                 // camera z = runner.z - 6.5
final s  = f / dz;                    // sprite scale ∝ 1/z
final sx = size.x / 2 + (x - cam.x) * s;
final sy = horizon + (cam.y - y) * s;
```

এই একটা ফাংশনই 2D sprite-কে 3D দুনিয়ায় বসায় — এটাই পুরো visual system-এর ভিত্তি।

---

## 4. Controls (input × feel)

| Input | Action | Duration | Notes |
|---|---|---|---|
| Swipe ←/→ (বা `A/D`) | lane change | `0.14 s` tween, cancelable | দ্রুত টানা swipe-এ double-lane নয়, একটা করে |
| Swipe ↑ (বা `W`/`Space`) | jump | airtime `~0.62 s`, apex `1.1 u` | **jump buffer** `0.15 s`, **coyote** নয় (ground-ই নেই) |
| Swipe ↓ (বা `S`) | roll/slide | `0.55 s`, hitbox height `0.9 u` | roll-এর মধ্যে আবার down = তাড়াতাড়ি শেষ |
| `Esc` / ⏸ button | pause | — | focus হারালে অটো-pause |
| `M` / 🔇 | mute toggle | — | settings-এ save |

**Feel rules (non-negotiable):**
1. Input → visible response **≤ 50 ms**। lane tween animation চলাকালীনই পরের swipe accept হবে (queued)।
2. Jump/roll-এর প্রথম ও শেষ ফ্রেমে **squash & stretch** (scaleY 0.88 → 1.08)।
3. Hard landing-এ camera `0.08 u` dip + dust burst।
4. Near-miss (obstacle থেকে `≤0.25 u` দূর দিয়ে পার) → whoosh SFX + score-এ `+5 style` + ছোট white flash।

---

## 5. World content

### 5.1 Obstacles

| ID | দেখতে | কী লাগে | Hitbox | Spawn desde |
|---|---|---|---|---|
| `barrier_low` | রেল-গেট, lাল-সাদা | **jump** | `h 0.9 u` | ০ m |
| `barrier_high` | ঝুলন্ত ব্যানার/সাইনবোর্ড | **roll** | gap নিচে `0.9 u` | ১৫০ m |
| `tram` / `train` | ট্রাম/coach, লম্বা `8–14 u` | **lane change** (উপরে ওঠা যাবে — `train_top` free path) | `h 2.2 u` | ৩০০ m |
| `cones` | রাস্তার cone cluster | jump (কম) / lane change | `h 0.5 u` | ০ m |
| `puddle`/`manhole` | ভেজা patch | lane change (হেলতে হয় না, পিছলে যায় না — শুধু ভিজ্যুয়াল v1) | — | ৫০০ m |
| `moving_train` | পাশের lane-এ ধেয়ে আসা ট্রেন | lane change + audio cue | `h 2.2 u` | v2 |

### 5.2 Collectibles & powerups

| আইটেম | নিয়ম |
|---|---|
| 🪙 Coin | `+5` score; pattern: line (৫), arch (jump rail), zigzag, cluster |
| 🧲 Magnet | `8 s`, `4 u` radius-এর কয়েন টেনে নেয় |
| ✖️2 Multiplier | `10 s`, score `×2` |
| 👟 Super Sneakers | `7 s`, jump apex `1.7 u` (উঁচু ব্যানার也很难) |
| ⭐ Style streak | near-miss chain: ৩ → `+15`, SFX চড়ে |

### 5.3 Fairness rule (spawn director-এর আইন)

> **যেকোনো `25 u` জায়গায় অন্তত একটা lane সম্পূর্ণ free থাকবে।**
> Spawn করে সিদ্ধান্তের আগে minimum reaction window: `max(0.65 s, 17 u / speed)`।
> একই সময়ে দুটো lane বন্ধ শুধু তখনই, যখন কমপক্ষে `180 m` আগে থেকে player যে lane-এ আছে সেটা খোলা ছিল।

Difficulty curve:

| Distance | Speed | Lane events / 100 m | Special |
|---|---|---|---|
| 0–250 m | `11 → 14 u/s` | 3 | শুধু `barrier_low` + cone |
| 250–800 m | `14 → 18` | 4–5 | `barrier_high`, প্রথম `train` |
| 800–1600 m | `18 → 22` | 6 | powerup introduction, moving train (v2) |
| 1600 m+ | `22 → 26` (cap) | 7 | সব মিশ্রিত, কুয়াশা/রাত skyline |

---

## 6. Scoring

```
score  =  floor(distance_m)             // 1 point / m
        + coins * 5                     // coin value
        + style_bonus                   // near-miss chain
score *= multiplier                     // ×2 powerup চলাকালীন

best_score  → local save (v1), persistent coins → local save
```

- HUD: score বাঁয়ে (rolling animation, `+12` pop), coins ডানে, powerup timer bar উপরে-মাঝে।
- New best: `z` 800 ms-এ "NEW BEST!" burst + BGM-এ এক bar উঁচু।

---

## 7. Fail & recovery

| Event | Reaction |
|---|---|
| Obstacle hit | `0.35 s` hit-stop → camera `z`-তে দূরে ঠেলে, কুকুর... মানে রানার পড়ে যায় → ragdoll-ish tumble (sprite), shake `0.4 u`, dust |
| Game over screen | score count-up, best comparison, `+coins` tally, **RETRY** (বড় button) · MENU |
| Revive (v2) | প্রতি run-এ একবার free revive (লোভী না) — চাইলে 광고-free, coins `50` spend |

**Death camera:** মৃত্যুর মুহূর্তে camera ধীরে হতে হবে (`timeScale 0.25` → `0.05` within `0.4 s`) — classic "oh no" beat, তারপর overlay।

---

## 8. UI / UX

| Screen | কী থাকবে |
|---|---|
| **Title** | key-art backdrop (parallax 2 layer), গেম logo, `BEST  12 340` / `🪙 480`, big **PLAY**, ⚙️ settings, 🏪 store (v2, "SOON" badge) |
| **Countdown** | `3 · 2 · 1 · GO` — scale-pop, প্রতিটিতে tick SFX; input আগেই buffer হবে |
| **HUD** | score (left), coins (right), powerup bars (top-center), pause (top-right) |
| **Pause** | blur overlay, RESUME / RESTART / SOUND / QUIT |
| **Game over** | panel slide-up `0.3 s`, score, best, coins earned, RETRY / MENU |
| **Settings** | sound on-off, music on-off, haptics on-off, reduced-motion, language (EN/BN) |
| **Tutorial** | প্রথম run-এ ৩টা swipe hint (left/right/up) `0.35 s` অন্তর, একবারই দেখাবে |

**Language:** UI strings EN + BN দুটোতেই (`lib/core/strings.dart`-এ দুটো map)। Default: device locale।

---

## 9. Audio direction

| Category | List |
|---|---|
| Music | `2` loop: **day** (golden hour, fusion-ish: dholak-light percussion + synth flute) · **night** (v2)। Intensity layer: speed বাড়লে percussion layer যোগ হয় |
| SFX | `jump`, `land`, `roll`, `coin` (pitch ladder — টানা কয়েনে চড়ে), `whoosh` (near-miss), `crash`, `powerup`, `best`, `ui_click`, `countdown_tick` |
| Mix | SFX `-6 dBFS` peak, music `-14 LUFS`; crash-এ music `0.3 s` duck |
| Haptics | coin = light, land = light, crash = heavy, best = double-medium |

Asset specs ও AI-generation prompt: **`docs/ASSET_PIPELINE.md`**।

---

## 10. Art direction (সারসংক্ষেপ)

- **Camera/light:** golden hour, sun horizon-এ বাঁয়ে-কাছে, উষ্ণ rim light রানারের ডান দিকে, নিচু-লম্বা shadow।
- **রঙ:** নিচের palette লক (hex); প্রতিটা asset এই palette-র ভেতরেই থাকবে।
- **আবহ:** কলকাতা — হাওড়া-ধাঁচের steel truss bridge দূরে, ট্রাম, হলুদ অ্যাম্বাসেডর taxi, উৎসবের string lights, graffiti দেওয়াল, বাজারের ছাউনি, বাড়ির ছাদে জলের ট্যাংকি।
- **Character:** original (AI-generated, brand-free): teal hoodie, orange backpack, dark curly hair, knee pad, orange sneaker — **`docs/art/character-ref.png`** চূড়ান্ত reference।
- **Key art (লক):** `docs/art/key-art.png`
- বিস্তারিত style bible: **`docs/ART_DIRECTION.md`**

```dart
// lib/core/palette.dart — লক করা token
skyTop     = 0xFF7EC8E3;   horizonWarm = 0xFFFFD9A0;   sunGlow  = 0xFFFF9E7A;
railSteel  = 0xFF9AA3A8;   ballast     = 0xFF8E7F6E;   concrete = 0xFFC9C4BC;
hoodie     = 0xFF1F9E8F;   hoodieLit   = 0xFF2BB3A3;   accent   = 0xFFFF8A3D;
coin       = 0xFFFFC63D;   coinDeep    = 0xFFE08A18;   danger   = 0xFFE5484D;
ink        = 0xFF2A2320;   paper       = 0xFFFFF6E6;
```

---

## 11. Performance budget (mid-range Android, 60 fps)

| Metric | Target | Hard cap |
|---|---|---|
| Frame time | ≤ 12 ms | 16.6 ms (60 fps NA) |
| Draw calls / frame | ≤ 90 | 120 |
| Texture memory | ≤ 48 MB | 64 MB |
| Total asset download (web) | ≤ 6 MB | 8 MB |
| Cold start (web 4G) | ≤ 4 s | 6 s |
| Update-loop allocation | 0 (object pool সব entity-র জন্য) | — |

---

## 12. Accessibility & platform

- **Input:** touch swipe (প্রধান), keyboard (arrows/WASD/Space), mouse drag; gamepad → v3।
- **Reduced motion:** screen-shake, flash, camera roll বন্ধ করার option।
- **Colorblind:** obstacle的形状 আলাদা (gate / banner / train silhouette), শুধু রঙে নির্ভরতা নয়।
- **Pause on blur**, orientation lock portrait, safe-area respect (notch)।
- **Platforms:** Web (preview + itch-style play) → Android APK/AAB → iOS (পরে)।
- **Monetization:** **কিছুই না** (v1)। কোনো ad SDK, কোনো backend, কোনো account। ಪೂರ್ಣ offline।

---

## 13. অ-লক্ষ্য (v1-এ কিছুই করব না)

Multiplayer · leaderboard/backend · IAP/store · cloud save · level/মিশন সিস্টেম · iOS signing · controller support · 3D modelling pipeline (সব sprite-based pseudo-3D থাকবে)।

## 14. সিদ্ধান্ত-বাকি (Keshab থেকে দরকার)

| # | প্রশ্ন | ডিফল্ট (না বললে এটাই) |
|---|---|---|
| D1 | গেমের নাম + repo rename? | working title **Metro Dash**; repo rename করব না |
| D2 | Hero-র নাম দরকার? (UI-তে কোথাও আসবে না) | `Raju` (শুধু internal) |
| D3 | কলকাতা theme পুরোটা? নাকি generic শহর? | কলকাতা flavor, brand-মুক্ত |
| D4 | ডগ (পুরনো repo নামের কুকুর) ট্রেইল pet হিসাবে থাকবে? | v3-তে unlockable pet হিসাবে ফিরবে |

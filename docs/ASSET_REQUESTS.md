# 📦 ASSET REQUEST LIST — Metro Dash

> **কে কী বানাবে:** প্রতিটা asset এই repo-র sandbox-এ AI image generator দিয়ে
> বানানো হয়, তারপর `tool/slice_sprites.py` দিয়ে chroma-key + trim + pivot।
> কোনো third-party art নয়, কোনো লোগো নয়।
>
> **অবস্থা:** ✅ = গেমে বসানো · 🔄 = বানানো আছে, বসানো বাকি · ⬜ = বানাতে হবে

---

## 0. কীভাবে একটা asset "done" হয়

```
1. generate  →  docs/art/<name>-raw.png        (chroma #00FF00 বা seamless texture)
2. process   →  assets/sprites/<name>.png      python3 tool/slice_sprites.py ...
3. register  →  lib/core/assets.dart           (এক লাইন, key → path)
4. wire      →  painter/world-এ draw call
5. proof     →  magenta proof sheet + flutter analyze + smoke test
```

আকারের নিয়ম: single file ≤ 1 MB, মোট `assets/` ≤ 8 MB, sprite উচ্চতা 260–640 px
(স্ক্রিনে কত বড় দেখা যাবে তার ওপর), texture 512×512।

---

## 1. Rail line ও ground (এখন সবচেয়ে বেশি দরকার)

| # | Asset | কী লাগবে | কেন | স্ট্যাটাস |
|---|---|---|---|---|
| R1 | `texture_ballast` | 512² seamless, শক্ত করে বসানো ছোট পাথর | rail-এর নিচের বিছানা | ✅ |
| R2 | `texture_grass` | 512² seamless ঘাস | দুই পাশের বাঁধ | ✅ |
| R3 | `texture_concrete` | 512² seamless পুরনো কনক্রিট | parapet দেয়াল | ✅ |
| **R4** | `texture_sleeper` | 512² **কাঠের sleeper** (দাগ, ফাটল, বোল্ট) | এখন sleeper শুধু রঙের ব্লক — texture হলে rail-ই "আসল" লাগবে | ⬜ **HIGH** |
| **R5** | `rail_head_strip` | 512×64 **ইস্পাতের rail head** আড়াআড়ি প্রোফাইল: উজ্জ্বল মাথা, দাগ, মরচে | rail-এর শাইন এখন গ্রেডিয়েন্ট, আসল ধাতুর feel দরকার | ⬜ **HIGH** |
| **R6** | `prop_signal` | রেল সিগন্যাল পোল (লাল/সবুজ বাতি) 1টা sprite | track-এর পাশে depth cue | ⬜ MED |
| **R7** | `prop_catenary` | ওভারহেড বিদ্যুতের খুঁটি + তারের bracket | metro rail-এর পরিচিত চেহারা | ⬜ MED |
| **R8** | `prop_marker` | ছোট কিলোমিটার পোস্ট / সাদা-কালো স্টোন | track-এর পাশে ছোট detail | ⬜ LOW |

## 2. Runner (Batch 1 / worker B)

| # | Asset | কী লাগবে | স্ট্যাটাস |
|---|---|---|---|
| P1 | `runner_run_0/1` | পেছন থেকে run cycle ২ ফ্রেম | ✅ |
| P2 | `runner_air` | লাফের pose | ✅ |
| **P3** | `runner_run_2/3` | **run cycle ৪ ফ্রেমে** (গোড়ালি-টো দুলুনি আলাদা) | ⬜ HIGH |
| **P4** | `runner_roll` (৪–৬ ফ্রেম) | রোল/স্লাইড | ⬜ HIGH |
| **P5** | `runner_hit` (৪ ফ্রেম) | ধাক্কা → পড়ে যাওয়া | ⬜ HIGH |
| **P6** | `runner_idle` (৪ ফ্রেম) | title screen-এ শ্বাস | ⬜ MED |

## 3. Obstacle ও collectible

| # | Asset | স্ট্যাটাস |
|---|---|---|
| O1 | `barrier_low` (gate) | ✅ |
| O2 | `barrier_high` (banner) | ✅ |
| O3 | `train` (face-on coach) | ✅ |
| O4 | `cones` | ✅ |
| O5 | `coin` | ✅ |
| **O6** | `barrier_low_2` — **দ্বিতীয় gate ভ্যারিয়েন্ট** (আলাদা রঙ/জীর্ণ) | ⬜ MED |
| **O7** | `train_side` — **পাশ থেকে দেখা লম্বা coach** (কয়েক lane জুড়ে) | ⬜ MED |
| **O8** | `coin_spin` (৬ ফ্রেম) — এখন coin স্ট্যাটিক, spin হলে প্রাণ আসবে | ⬜ MED |
| **O9** | `powerup_magnet`, `powerup_x2`, `powerup_sneaker` | ⬜ LOW (v2 feature) |

## 4. Effect ও particle

| # | Asset | কেন | স্ট্যাটাস |
|---|---|---|---|
| **E1** | `dust_puff` (৫ ফ্রেম) | landing/দৌড়ে ধুলো | ⬜ HIGH |
| **E2** | `crash_burst` (৬ ফ্রেম) | ধাক্কার impact | ⬜ MED |
| **E3** | `speed_streak` | দ্রুত হলে পাশ দিয়ে streak | ⬜ LOW |

## 5. City ও street (worker A)

| # | Asset | স্ট্যাটাস |
|---|---|---|
| C1 | `bg_skyline` (bridge + city) | ✅ |
| C2 | `house_0/1/2` | ✅ |
| **C3** | `house_4/5/6` — আরও ৩টা বাড়ি (variety: ছাদে মোরগ, নীল বাড়ি, দোকান) | ⬜ MED |
| **C4** | `prop_cart` — cha/jhalmuri চালানো গাড়ি | ⬜ MED |
| **C5** | `prop_stall` — ছাউনি দেওয়া দোকান | ⬜ MED |
| **C6** | `bg_sky_night` + `city_night` | ⬜ LOW (Batch 2) |

## 6. UI ও audio

| # | Asset | স্ট্যাটাস |
|---|---|---|
| U1 | icons (pause/sound/coin) — এখন Material icon | ✅ |
| **U2** | font: Baloo Da 2 (বাংলা) + Rubik (Latin), SIL OFL | ⬜ HIGH |
| **U3** | logo `metro_dash_logo.png` | ⬜ MED |
| A1 | SFX: jump, land, roll, coin, whoosh, crash, powerup, best, ui_click | ⬜ Batch 2 |
| A2 | music_day (loop) + music_day_intense | ⬜ Batch 2 |

---

## 7. এই batch-এ কে কী নেবে (Batch 1)

| Worker | নিজের ফাইল | এই লিস্ট থেকে |
|---|---|---|
| **A (world)** | `lib/world/**` | R4, R5, R6, R7, R8, C3, C4, C5 |
| **B (runner)** | `lib/entities/runner.dart`, `lib/systems/input_controller.dart` | P3, P4, P5, P6 |
| **C (spawner)** | `lib/entities/{obstacle,coin}.dart`, `lib/systems/{spawn_director,difficulty}.dart` | O6, O7, O8, O9, E1, E2, E3 |
| **Captain** | `lib/core/**`, UI, services | U2, U3, A1, A2 |

> Worker-এর ফাইল মালিকানা `docs/briefs/BATCH1_WORKER_*.md`-তে লক করা আছে।
> **নতুন sprite বানালে worker শুধু report-এ path দেবে** — `lib/core/assets.dart`-এ
> key যোগ করবে Captain (একই ফাইলে দুইজনের হাত পড়া বন্ধ রাখতে)।

---

## 8. এখনকার ⬜ HIGH তালিকা (সবচেয়ে বেশি "real" ফিরবে)

```
R4 texture_sleeper        R5 rail_head_strip
P3 runner_run_2/3         P4 runner_roll        P5 runner_hit
E1 dust_puff              U2 fonts
```

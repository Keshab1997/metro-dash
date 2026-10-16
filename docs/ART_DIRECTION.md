# 🎨 ART DIRECTION — Metro Dash (style bible)

> দুটো reference image দিয়ে style **lock** করা হয়েছে। প্রতিটা নতুন asset এই দুই ছবির পরিবারভুক্ত হতে হবে।

## 1. Reference (locked, repo-তে committed)

| | |
|---|---|
| **Key art**<br>`docs/art/key-art.png` | Golden hour, তিনটা rail লাইন horizon-এ converge, রানার পিছনে-উপরে camera, হাওড়া-ধাঁচের steel truss bridge দূরে, ট্রাম, হলুদ অ্যাম্বাসেডর taxi, উৎসবের string lights + pennants, graffiti দেওয়াল, ballast + wooden sleeper, ভাসমান gold coin, dust puffs, motion streaks |
| **Character**<br>`docs/art/character-ref.png` | Original teen runner — teal hoodie (rolled sleeves), orange backpack, dark curly hair, dark blue joggers, black left knee pad, orange/white sneakers, friendly confident face। **এই ফাইলটাই sprite generation-এর parent।** |

> দুটো ছবিই AI-generated, original, কোনো ব্র্যান্ড/লোগো নেই। "Subway Surfers" শুধু *ঘরানা*সূচক 비교 — কোনো উপাদান copy করা হয়নি এবং হবে না।

## 2. Camera & composition

- Chase cam; horizon সবসময় উপরের `~42%` লাইনে (portrait)।
- তিন lane `x = −1, 0, +1`; center lane-এ sun ডান দিকে ছোট offset-এ (symmetry ভাঙার জন্য)।
- প্রসপেক্ট: নিচের দিকে জিনিস বড়, দূরে ছোট (`1/z` law) — blur নেই, শুধু haze fade।

## 3. Palette (locked — `lib/core/palette.dart`-এর সাথে অভিন্ন)

| Role | Hex | ব্যবহার |
|---|---|---|
| `skyTop` | `#7EC8E3` | আকাশের উপরে |
| `horizonWarm` | `#FFD9A0` | horizon glow |
| `sunGlow` | `#FF9E7A` | sun + rim light উষ্ণতা |
| `railSteel` | `#9AA3A8` | rail, truss |
| `ballast` | `#8E7F6E` | নিচের পাথর/মাটি |
| `concrete` | `#C9C4BC` | দেওয়াল, প্ল্যাটফর্ম |
| `hoodie` / `hoodieLit` | `#1F9E8F` / `#2BB3A3` | হিরো hoodie (open/shadow) |
| `accent` | `#FF8A3D` | backpack, cone, button, sneaker |
| `coin` / `coinDeep` | `#FFC63D` / `#E08A18` | কয়েন |
| `danger` | `#E5484D` | barrier stripe, hit flash |
| `ink` | `#2A2320` | আউটলাইন, টেক্সট |
| `paper` | `#FFF6E6` | প্যানেল/HUD কার্ড |

**নিয়ম:** emissive/glow শুধু কয়েন, powerup, string light, sun-এ। বাকি সব flat-lit।

## 4. Lighting

- Sun: horizon-এর বাঁয়ে-কাছে, `~10°` উপরে; উষ্ণ rim light entity-র **ডান-উপর** দিকে।
- Shadow: নিচে-বাঁয়ে লম্বা soft ellipse, opacity `~25%`, entity-র সাথে scale করে।
- প্রতিটা sprite-এ আলো **একটাই direction** — generation prompt-এ `uniform lighting from upper-left` লিখে ধারাবাহিকতা রাখা হবে।

## 5. World motifs (Kolkata flavor, brand-free)

ট্রাম · হলুদ-কালো taxi silhouette · হাওড়া-ধাঁচের steel truss bridge · চায়ের stall + jhalmuri cart · ছাদে জলের ট্যাংকি · উৎসবের pennant + string light · graffiti concrete wall · পুরনো লোহার grille gate · পোস্টার-লাগানো দেওয়াল।

> লেখা (Bangla/English) sprite-এ **unreadable motif** হিসেবে থাকবে — আসল বাক্য নয়; এতে localization issue ও অশ্লীল-দুর্ঘটনা দুটোই এড়ানো যায়।

## 6. Line-work ও detail budget

| Element | Detail level |
|---|---|
| Hero (near, screen-এর ১/৫ অংশ) | সর্বোচ্চ detail, স্পষ্ট মুখ, সেল-শেড ~২ step |
| Obstacle (near) | মধ্যম detail, silhouette স্পষ্ট (form-first) |
| World props | মধ্যম-কম; সরল shape, বড় রঙের বলয় |
| দূরের city/sky | শুধু silhouette + haze — detail লাগবে না |
| Particles/dust | text-free, এক রঙ + opacity |

**Silhouette test:** grayscale-এ convert করলে obstacle ↔ coin ↔ runner একсеকেন্ডে আলাদা করা যাবে — এটাই colorblind-safe চেক।

## 7. UI/HUD style

- Cream panel (`paper`) + নরম shadow (y `+4`, blur `12`, opacity 18%)।
- বাটন: pill, `accent` fill, হালকা bottom-dark edge; pressed = scale `0.96` + edge flatten।
- টেক্সট: **Baloo Da 2** (Bangla/display) + **Rubik** (Latin/UI) — দুটোই SIL OFL।
- Icons: এক stroke weight (`2.5` @ 24px), গোল corner, `ink` অথবা `paper`।

## 8. Motion principles

1. **Anticipation → action → follow-through**: obstacle-এর sway আগে, তারপর hit; না হলে ঘুষি লাগে না।
2. **সবকিছু সাথে সাথে নয়** — camera `0.1 s` দেরিতে reach করে (lag), এতে speed বোঝা যায়।
3. **Consistent easing:** UI `easeOutCubic 200ms`, world/lane `easeOutQuad 140ms`, heavy things (train) `280ms`।
4. **Speed readability:** world-এর সাথে speed lines/streak dust যোগ হবে — HUD-এ "speed number" দেখানো হবে না, camera-ই speed বলে দেবে।

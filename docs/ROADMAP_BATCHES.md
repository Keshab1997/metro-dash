# 🗺️ ROADMAP & BATCH PLAN — পুরনো গেম → Metro Dash

> Captain-এর কাজের ক্রম। প্রতিটা batch-এর শেষে: gate চালানো → `main`-এ push → Keshab-কে ৫ লাইনের report + web preview link।
> **Worker কখনো `main` ছোঁবে না; এক batch-এ দুই worker এক ফাইল ছোঁবে না।**

---

## Batch 0 — Captain solo: ভিত খোঁড়া (reboot)

**লক্ষ্য:** পুরনো Puppy Dash ডিলিট, Flame skeleton দাঁড়ানো, repo সবুজ।

| ধাপ | কী |
|---|---|
| 1 | `lib/main.dart` (পুরনো) **ডিলিট**; `lib/` পুনর্গঠন `docs/TECH_ARCHITECTURE.md` §2 layout-এ |
| 2 | `pubspec.yaml`: `flame` + `shared_preferences` pin, assets section, fonts → Captain একাই ছোঁবে |
| 3 | `core/palette.dart`, `core/config.dart` (Tune class), `core/strings.dart` (EN+BN), `core/assets.dart` |
| 4 | `game/projection.dart` + `game/camera_rig.dart` + `game/run_state.dart` — **frozen interfaces** (A/B/C এর ভিত্তি) |
| 5 | খালি-but-চলমান scene: sky + rail placeholder (canvas rect দিয়ে), title → countdown → running state machine |
| 6 | `test/game_smoke_test.dart` — boot → title → tap → running |
| 7 | README rewrite (নতুন গেম, কীভাবে খেলবে, preview link), `web/index.html` title/meta update |
| 8 | Gate: `python3 tool/preflight.py` + `flutter test test/game_smoke_test.dart` + (নিজের ঝুঁকি মনে হলে) `flutter analyze` |
| 9 | `main`-এ push → Keshab-কে report + preview link → **তিনটা brief হস্তান্তর** (A/B/C) |

**Acceptance:** preview URL-এ app খোলে, TAP-এ countdown→running হয়, তিনটা placeholder lane দেখা যায়, gate সবুজ, পুরনো `Puppy Dash` শব্দ কোডে/README-তে নেই।

---

## Batch 1 — A ∥ B ∥ C — parallel (কোনো ফাইল share নেই)

| Worker | Workstream | মালিকানা (ফাইল) | Deliverable | নিজের check |
|---|---|---|---|---|
| **A — World** | rails, environment, skyline, parallax | `lib/world/**`, `assets/sprites/rail_*`, `props_*`, `city_*`, `sky*`, `grass_*` | দৌড়ানোর জায়গা: 3 lane rail + sleeper + ballast + পাঁশের props + দূরের bridge/city, সব `Projection` দিয়ে | `python3 tool/preflight.py` |
| **B — Runner** | hero entity + input + animation | `lib/entities/runner.dart`, `lib/systems/input_controller.dart`, `assets/sprites/runner_*` | swipe/keys → lane change/jump/roll, `run/jump_*/roll/hit` animation, squash-stretch | `flutter test test/runner_input_test.dart` (নিজে লিখবে) |
| **C — Spawner** | obstacles, coins, fairness, difficulty | `lib/entities/obstacle.dart`, `coin.dart`, `lib/systems/spawn_director.dart`, `difficulty.dart`, `assets/sprites/barrier_* / train / cones / coin / dust_*` | §GDD 5.3 fairness guarantee + difficulty curve + object pool, unit test প্রমাণ | `flutter test test/spawn_fairness_test.dart` (নিজে লিখবে) |
| **Captain** | integration: camera, collision rules, scoring, HUD, services, title/game-over UI | `lib/game/**`, `lib/systems/collision.dart`, `scoring.dart`, `lib/services/**`, `lib/ui/**`, `lib/main.dart` | প্রতিটা batch-এ merge → খেলার যোগ্য build | preflight + smoke test |

**Frozen interfaces (brief-এ verbatim যাবে):**

```dart
// A
class TrackBuilder { void build(World w, double fromZ, double toZ); }
class Environment { void placeProps(double fromZ, double toZ); }

// B
class Runner extends PositionComponent {
  void intent(LaneIntent i);       // enum LaneIntent { left, right, jump, roll }
  bool get isRolling; double get height;   // collision-এর জন্য
  void die(); void reset();
}
enum LaneIntent { left, right, jump, roll }

// C
class SpawnDirector {
  SpawnDirector({required int seed});
  void update(double runnerZ, double speed);      // spawn/kill
  List<Hitbox> activeHitboxes();                  // Captain-এর collision এটাই পড়বে
}
class Difficulty { static double speedAt(double meters); static double density(double meters); }
```

**Batch 1-এর gate (Captain):** preflight + smoke + fairness test + ৬০ সেকেন্ডের manual run preview-এ।

---

## Batch 2 — Polish & sound (A ∥ B ∥ C আবার, ভিন্ন কাজে)

| Worker | কাজ |
|---|---|
| A | night set (skyline lit, neon, fog), weather hint, tile polish |
| B | powerup pickups (magnet/×2/sneakers) + runner animation polish (near-miss lean) |
| C | moving train, powerup spawn logic, difficulty re-tune (playtest числа) |
| Captain | particles, screen shake, hit-stop, audio service + SFX/মিউজিক, title/game-over/settings final, save, haptics, reduced-motion, BN/EN strings final |

**Gate:** preflight + full `flutter test` + `flutter analyze` (Captain-এর সিদ্ধান্তে) + preview playtest।

---

## Batch 3 — Release candidate

- Perf: frame time নমুনা (Flame `FpsComponent` debug), draw call ≤ 90, asset total ≤ 8 MB, watertight asset registration table।
- Web release build CI-তে সবুজ; Android APK CI-তে (`manual-build.yml`, Keshab চালাবেন)।
- README: screenshot/gif + কলকাতা flavor + credits (asset license)।
- **Tag/release = Keshab-এর এক্সপ্লিসিট সিদ্ধান্ত** (Captain কখনো নিজে tag দেয় না)।

---

## v2 idea-parking (এখন করছি না, হারিয়েও যাবে না)

moving trains full rule-set · hoverboard/jetpack · revive (coins) · store/skins (রানার variation) · dog companion pet (পুরনো repo নামের homage) · daily challenge · leaderboard (backend → Keshab-এর অনুমতি লাগবে) · iOS · gamepad।

---

## প্রতিটা batch-এর Keshab-facing report format

```
Batch <n>: A merged (<sha7>), B merged (<sha7>), C pending — <why>
Changed: <one line per merged workstream>
Evidence: preflight ok / <test> passed / preview link
Not touched: <deliberately left alone>
Next: <next split>
```

**এখনকার অবস্থান:** Batch 0-এর আগে — শুধু docs (এই ফাইলগুলো)। Keshab "কোড শুরু" বললেই Batch 0 চালু।

# 🏗️ TECH ARCHITECTURE — Metro Dash

> **কোড:** এখনো নেই। এই ফাইল Batch 0/1-এর worker brief-এর ভিত্তি — এখানকার নাম/সিগনেচার **frozen interface**, worker এগুলো verbatim ব্যবহার করবে।

---

## 1. Stack সিদ্ধান্ত

| সিদ্ধান্ত | কারণ |
|---|---|
| **Flutter + Flame** (`flame ^1.x`, pin করবে Captain) | sprite animation, camera, effects, collision, component lifecycle — সব বাক্সে আছে; Flutter widget layer-এ UI/মেনু, game layer-এ Canvas — দুটোই এক repo-তে |
| **2D sprite + pseudo-3D projection** (পুরো 3D modelling pipeline **নয়**) | AI-জেনারেটেড sprite দিয়েই "আসল 3D feel" আসে (§4-এর projection); iteration কয়েক মিনিটে, asset খরচ কম, mid-range ফোনে 60 fps সহজ |
| **`enhanced` কিছুই না / assets CDN নয়** | সব asset repo-তে bundle — web preview, APK, offline সব একই |
| **State management: না** | game state = Flame components + কয়েকটা plain service; Provider/Riverpod লাগবে না, যোগ করলে complexity বাড়ে |
| **Backend: নেই** | save = `shared_preferences` local |

`pubspec.yaml` dependencies (Batch 0-এ Captain লক করবে):

```yaml
dependencies:
  flame: ^1.2x.0          # exact version Batch 0-এ pin
  shared_preferences: ^2.x
  flutter: { sdk: flutter }
dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^6.0.0
```

> ⚠️ কোনো worker `pubspec.yaml` ছোঁবে না। নতুন dependency দরকার হলে brief-এর report-এ বলবে — Captain যোগ করবে।

---

## 2. Folder layout (worker ownership map)

```
lib/
├── main.dart                     ┐
├── core/                         │  CAPTAIN
│   ├── palette.dart              │  (shared surface —
│   ├── config.dart   (tunables)  │   worker এখানে হাত দেয় না)
│   ├── strings.dart  (EN+BN)     │
│   └── assets.dart   (path const)┘
├── game/
│   ├── metro_dash_game.dart      ┐
│   ├── camera_rig.dart           │  CAPTAIN (integration surface)
│   ├── run_state.dart            │  states: loading,title,countdown,running,paused,over
│   └── projection.dart           ┘  ★ §4 — WORLD worker-এর সাথে একসাথে freeze
├── systems/
│   ├── input_controller.dart     ← A/input worker
│   ├── spawn_director.dart       ← C worker (fairness §5.3)
│   ├── difficulty.dart           ← C worker
│   ├── scoring.dart              ← CAPTAIN
│   └── collision.dart            ← CAPTAIN (rules, hitbox table)
├── entities/
│   ├── runner.dart               ← B worker (states: idle,run,jump,fall,roll,hit)
│   ├── obstacle.dart             ← C worker (ids: barrier_low, barrier_high, train, cones)
│   ├── coin.dart                 ← C worker
│   └── powerup.dart              ← C worker (v2)
├── world/
│   ├── track_builder.dart        ← A worker (rails, sleepers, ballast)
│   ├── environment.dart          ← A worker (props placement, parallax layers)
│   └── skyline.dart              ← A worker (bridge, city, sky)
├── services/
│   ├── audio_service.dart        ← CAPTAIN (v1: silent stub → Batch 2-এ ভরে)
│   ├── save_service.dart         ← CAPTAIN
│   ├── haptics_service.dart      ← CAPTAIN
│   └── settings_service.dart     ← CAPTAIN
└── ui/
    ├── hud.dart                  ← CAPTAIN
    ├── title_screen.dart         ← CAPTAIN
    ├── game_over_screen.dart     ← CAPTAIN
    ├── pause_overlay.dart        ← CAPTAIN
    └── settings_sheet.dart       ← CAPTAIN
assets/
├── sprites/  ← §ASSET_PIPELINE (worker নিজের area-র asset আনে)
├── audio/
└── fonts/
test/
├── spawn_fairness_test.dart      ← C worker
├── difficulty_test.dart          ← C worker
├── scoring_test.dart             ← CAPTAIN
└── game_smoke_test.dart          ← CAPTAIN
```

**Batch-1 parallel map (দেখো `docs/ROADMAP_BATCHES.md`):**
`world/** + A-এর assets` → A · `entities/runner.dart + systems/input_controller.dart + runner assets` → B · `entities/obstacle.dart, coin.dart, powerup.dart, systems/spawn_director.dart, difficulty.dart + test দুটো` → C · বাকি সব → Captain.

---

## 3. Data flow (এক ফ্রেমে কী হয়)

```
Swipe/Tap ─► InputController ─(intent: lane|jump|roll)─► Runner
                                                          │ position (x,y,z)
        ┌─────────────────────────────────────────────────┘
        ▼
  CameraRig.update(runner.z)                     SpawnDirector.update(z, speed)
        │                                                 │ spawn/kill entities
        ▼                                                 ▼
  Projection(world→screen)  ◄──── render (back-to-front by z) ──── Obstacle/Coin/World
        │                                                 │
        └──► Collision.resolve(runner, entities) ──hit──► Scoring.finish() ──► GameOver
                                                          │
                                                    SaveService.write(best, coins)
```

- **Update order প্রতি tick-এ fix:** `input → runner → spawn → collision → scoring → audio events` (একই order না হলে fairness test flaky হবে)।
- **কোনো entity টানে না নিজের ভাগ্য** — সিদ্ধান্ত শুধু systems-এ।

---

## 4. Projection (`lib/game/projection.dart`) — সবচেয়ে গুরুত্বপূর্ণ ৩০ লাইন

```dart
/// world → screen. সব renderable এর একমাত্র সত্য।
class Projection {
  Projection({required this.viewport, required CameraRig cam});

  /// world (x, y, z) → screen pixel + sprite scale (1/z law) + depth key
  Projected project(double x, double y, double z) {
    final dz = (z - cam.z).clamp(0.001, 400.0);
    final s  = focal / dz;                       // focal = viewport.h * 0.5 / tan(fov/2)
    return Projected(
      screen: Offset(viewport.w / 2 + (x - cam.x) * s * pxPerUnit,
                     horizonZ + (cam.y - y) * s * pxPerUnit),
      scale: s,
      depth: dz,                                  // sort key (বড় = কাছে = পরে আঁকো)
    );
  }
}
```

**Invariants (worker-দের জন্য লিখিত আইন):**
1. `scale` শুধু `z`-এর function; lane-এর জন্য আলাদা scale **নয়**।
2. সব sprite anchor = **bottom-center** (`Anchor.bottomCenter`) — pivot math এখানেই শেষ।
3. Horizon-এর উপরে (`depth > farZ`) কিছুই আঁকবে না; `fade` zone শেষ `40 u`-তে alpha `1→0`।
4. Sorting: `depth` ascending → আগে দূরের জিনিস। z-fighting লাগবে না, কখনো same-depth দুটো entity spawn হবে না (lane আলাদা)।

---

## 5. Tunables (`lib/core/config.dart`) — magic number নিষিদ্ধ

```dart
abstract final class Tune {
  static const laneX        = [-1.0, 0.0, 1.0];   // world x
  static const laneChange   = 0.14;               // s
  static const jumpAirtime  = 0.62;  static const jumpApex = 1.10;
  static const rollDuration = 0.55;  static const rollHeight = 0.90;
  static const inputBuffer  = 0.15;               // s
  static const speedStart   = 11.0;  static const speedCap = 26.0;
  static const camHeight    = 2.6;   static const camDist = 6.5;
  static const spawnAhead   = 60.0;               // u — কত দূরে spawn হবে
  static const minReact     = 0.65;               // s — fairness floor
  static const freeLaneWin  = 25.0;               // u — §GDD 5.3
  static const coinValue    = 5;     static const styleBonus = 5;
  static const nearMissDist = 0.25;               // u
  static const poolSizes    = (obstacles: 32, coins: 96, dust: 64, popups: 16);
}
```

Worker **নতুন tuneable যোগ করলেই `config.dart`-এ নাম দিয়ে comment লিখবে** — সংখ্যা কোডের ভেতরে ছড়াবে না।

---

## 6. Save schema (`services/save_service.dart`)

```jsonc
// shared_preferences keys — prefix "mdr."
{
  "mdr.best_score": 12340,        // int
  "mdr.total_coins": 480,         // int (persistent, v2 store-এ খরচ হবে)
  "mdr.runs": 57,                 // int
  "mdr.sound": true, "mdr.music": true, "mdr.haptics": true,
  "mdr.reduced_motion": false, "mdr.lang": "bn",
  "mdr.schema": 1                 // migration anchor
}
```

- `SaveService.load()` app-এ একবার, `write()` debounce `500 ms`।
- Save corrupt হলে → defaults-এ fallback, কোনো throw নয় (crash = রivery থেকে বাদ)।

---

## 7. Assets pipeline (বিস্তারিত: `docs/ASSET_PIPELINE.md`)

| ধাপ | Tool | Output |
|---|---|---|
| 1. AI generation | এই sandbox-এর image generator | PNG (1024²+) — character ref/key art ইতিমধ্যে `docs/art/`-এ |
| 2. Post-process | Python + Pillow (sandbox-এ install) | background removal, trim, pivot align, frame split |
| 3. Animation | নন-স্ট্যান্ডার্ড নয় — প্রতিটা animation = **sprite strip** (horizontal, সমান ফ্রেম) | `assets/sprites/runner_run.png` ইত্যাদি |
| 4. Atlas | Captain pack করে (Pillow script, `tool/pack_atlas.py` — Batch 1-এ বানাব) | `atlas_1.png` ≤ 2048² + `.json` frame table |
| 5. Audio | Python synthesis (numpy → wav → ogg) + curated CC0 pack | `assets/audio/*.ogg` |

---

## 8. Gate, CI, deploy (এখনকার repo থেকেই নেওয়া — বদলাবে না)

| জিনিস | নিয়ম |
|---|---|
| **প্রতি change** | `python3 tool/preflight.py` (~1 s) — এটাই worker-এর একমাত্র check |
| **Dart test** | শুধু নিজের এক test file: `flutter test test/<name>_test.dart` |
| **`flutter analyze` / full test** | Captain-এর সিদ্ধান্ত — shared surface/risky diff-এ |
| **কখনো নয়** | `flutter build apk/aab/web`, `gradlew`, CI-র জন্য অপেক্ষা |
| **CI** | `.github/workflows/ci.yml` — **manual dispatch**, Keshab একটা batch-এ একবার চালাবেন |
| **Web preview** | `web-preview.yml` **push-এ অটো** → প্রতিটা batch-এর পরেই browser-এ খেলা যাবে (GitHub Pages, `preview/<branch>`) |
| **Release/tag** | Captain কখনো নয় — Keshab-এর এক্সপ্লিসিট নির্দেশ লাগবে |
| **Flutter SDK (sandbox)** | `/var/tmp`-এ wiped প্রতি turn; দরকারে: `bash <(curl -fsSL https://raw.githubusercontent.com/Keshab1997/flutter-bootstrap/main/setup.sh) --root /var/tmp/flutter --quiet --json` (~50 s) |

### Build targets

| Target | কমান্ড (শুধু Captain/local) | কখন |
|---|---|---|
| Web dev | `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080` | ফিচার যাচাইতে |
| Web release | `flutter build web --release --base-href /dog-road-runner/preview/<branch>/` | CI করে |
| Android | শুধু CI (`manual-build.yml`), লোকালে কখনো নয় | APK চাইলে Keshab Actions থেকে |

---

## 9. Testing strategy

| Level | কী | কে |
|---|---|---|
| Unit | spawn fairness (§GDD 5.3), difficulty curve monotonicity, scoring math, save round-trip | worker নিজের ফাইলে |
| Widget smoke | app boot → title render → tap → `running` state (পুরনো `test/game_test.dart`-এর উত্তরসূরি) | Captain |
| Manual | browser preview-এ ১ মিনিট খেলা, তিন input + crash + retry | Keshab (preview link প্রতিটা batch-এ) |

**Flaky-প্রতিরোধ:** system test-এ `Random` কখনো seed ছাড়া নয় — `SpawnDirector(seed:)` inject করবে (interface frozen)।

---

## 10. Code conventions

- Dart 3 style, `flutter_lints` clean, `const` যেখানে সম্ভব; `dart format` (80 col)।
- Comment বাংলা/ইংরেজি মিশ্রণ ঠিক আছে, কিন্তু **comment বলে "কেন"**, "কী" নয় (`// speed-cap এখানে, কারণ তারপরেই spawn gap কমে যায়`)।
- নতুন public class/method-এর নাম brief-এ freeze হবে; worker নিজে থেকে rename করবে না।
- কোনো `print` নেই (release-এ debug print বাদ); logging দরকার হলে `assert` + `debugPrint` গার্ড।

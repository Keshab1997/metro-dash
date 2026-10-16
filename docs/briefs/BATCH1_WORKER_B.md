✂ ═══════════════ COPY FROM HERE (give the whole block to agent B) ═══════════════

# You are agent B. One task, one branch, then you stop.

You work in your own sandbox. Nobody else is watching this chat. Do the task
below, push your branch, report in the format at the end. Do not ask Keshab
questions — if something is unclear or too big, stop and say so in your report.

## 0. GitHub access — check first, pair only if asked to

```bash
DST=/home/user/agent-bootstrap
[ -f "$DST/gh_app.py" ] || git clone https://github.com/Keshab1997/agent-bootstrap "$DST"
python3 "$DST/gh_app.py" connect     # ALREADY CONNECTED → nothing to do
```

If it prints a code, show it as a headline and wait for approval. Never ask for
a token. Turn ended early? `python3 "$DST/device_pair.py" poll 60`.

## 1. Your task

**Goal:** the hero feels alive — a full run cycle from the sprite set, and an
input layer with jump buffering, coyote-free re-jump rules and a keyboard/swipe
path that a test proves.

**Repo:** `Keshab1997/metro-dash` · **Branch:** `agent/B/runner-feel`

```bash
cd /home/user
[ -d metro-dash ] || git clone https://github.com/Keshab1997/metro-dash.git /home/user/metro-dash
cd /home/user/metro-dash
git config core.fileMode false
git config user.name "Keshab Sarkar"
git config user.email "Keshab1997@users.noreply.github.com"
git config credential.helper '!f(){ echo username=x-access-token; echo "password=$(cat /home/user/agent-bootstrap/secrets/gh_token.txt)"; }; f'
git fetch origin && git checkout -B agent/B/runner-feel origin/main
```

**Files you own (only these):**

- `lib/entities/runner.dart`
- `lib/systems/input_controller.dart`
- NEW sprites `assets/sprites/runner_*` (raw renders under `docs/art/runner-*`)
- NEW `test/runner_input_test.dart` (your own test — cheap and focused)

**DO NOT TOUCH:** `lib/game/**`, `lib/render/game_painter.dart`, `lib/core/**`
(the captain owns `assets.dart` and `config.dart` — ask, do not edit),
`lib/world/**`, `lib/entities/obstacle.dart`, `lib/entities/coin.dart`,
`lib/systems/{collision,spawn_director,difficulty,scoring}.dart`,
`lib/ui/**`, `pubspec.yaml`, `test/game_smoke_test.dart`,
`.github/workflows/**`, `android/**`, `tool/**`, `docs/*.md`, and never `main`.

**Interface (frozen — the painter and the game loop call exactly these):**

```dart
enum LaneIntent { left, right, jump, roll }

class Runner {
  double x, y, z; int lane; double squash; double stride;
  bool alive; bool get isAirborne; bool get isRolling;
  double get height;      // standing 1.78 → rolling Tune.rollHeight (hitbox)
  double get jumpT;       // 0..1 across the jump
  double get rollProgress;// 0..1 across the roll
  int get runFrameIndex;  // 0..N-1, indexes GameAssets.runFrames
  bool intent(LaneIntent i);  // false = not possible right now (buffer it)
  void update(double dt, double speed);
  void die(); void reset();
}

class InputController {
  void queue(LaneIntent intent, double now);
  void apply(Runner runner, double now);   // once per frame, before runner.update
  static LaneIntent? fromDrag(Offset delta); // null = below Tune.swipeThreshold
}
```

If you generate more run frames (say 4 or 6), name them
`assets/sprites/runner_run_0.png`, `_1`, … and say so in the report — the
captain adds them to `GameAssets.runPaths`. Until then `runFrameIndex` must
stay within the two frames that exist. Sprite pipeline:

```bash
python3 -m pip install --quiet pillow
python3 tool/slice_sprites.py RAW.png assets/sprites/runner_run_2.png --height 420
```

Every tunable you need (airtime, apex, buffer, lane tween, thresholds) already
exists in `lib/core/config.dart` — use those names; if a number is missing, ask
in the report, do not invent a constant inside the file.

## 2. Your check — then push

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Keshab1997/flutter-bootstrap/main/setup.sh) \
  --root /var/tmp/flutter --quiet --json
export PATH=/var/tmp/flutter/bin:$PATH PUB_CACHE=/var/tmp/pub-cache

python3 tool/preflight.py
flutter test test/runner_input_test.dart      # the file you wrote
```

Your test must prove at least: a swipe during a jump is buffered and honoured
on landing; a lane change is rejected mid-tween and kept for later; a
double-lane swipe never skips a lane; `height` drops while rolling; a queued
intent older than `Tune.inputBuffer` is dropped.

Never run `flutter analyze`, the full suite, `flutter build`, `gradlew` or CI.

```bash
git add -A
git commit -m "feat(runner): full run cycle and honest input buffering"
git push -u origin agent/B/runner-feel
```

## 3. Report — copy-paste this block back to Keshab

```
AGENT B DONE
branch: agent/B/runner-feel
sha: <git rev-parse --short HEAD>
files: <git diff --stat origin/main...HEAD | tail -1>
check: preflight ok; flutter test test/runner_input_test.dart → pass, N tests
changed: <one sentence>
new sprite frames (for the captain to wire): <paths, or none>
not touched: painter, core, world, obstacles, pubspec, workflows
blocked: <none | what stopped you>
```

## 4. Stop rules

Stop and report if the task needs `lib/core/**`, `game_painter.dart` or the
game loop; if the sprite generator cannot produce a usable frame; or if your
test fails for a reason outside your diff.

✂ ═══════════════ COPY ENDS HERE ═══════════════

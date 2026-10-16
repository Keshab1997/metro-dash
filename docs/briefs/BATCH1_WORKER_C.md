✂ ═══════════════ COPY FROM HERE (give the whole block to agent C) ═══════════════

# You are agent C. One task, one branch, then you stop.

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

**Goal:** the spawner is provably fair and worth playing — obstacle mix, coin
patterns, difficulty curve and an object-pool-friendly update, all covered by a
unit test that hunts for unfair layouts.

**Repo:** `Keshab1997/metro-dash` · **Branch:** `agent/C/spawner-fair`

```bash
cd /home/user
[ -d metro-dash ] || git clone https://github.com/Keshab1997/metro-dash.git /home/user/metro-dash
cd /home/user/metro-dash
git config core.fileMode false
git config user.name "Keshab Sarkar"
git config user.email "Keshab1997@users.noreply.github.com"
git config credential.helper '!f(){ echo username=x-access-token; echo "password=$(cat /home/user/agent-bootstrap/secrets/gh_token.txt)"; }; f'
git fetch origin && git checkout -B agent/C/spawner-fair origin/main
```

**Files you own (only these):**

- `lib/systems/spawn_director.dart`
- `lib/systems/difficulty.dart`
- `lib/entities/obstacle.dart`
- `lib/entities/coin.dart`
- NEW `test/spawn_fairness_test.dart` (your own test)
- NEW sprites only: `assets/sprites/coin_*`, `barrier_*`, `train*`, `cones_*`,
  `dust_*` (raw renders under `docs/art/`)

**DO NOT TOUCH:** `lib/game/**`, `lib/render/**`, `lib/ui/**`, `lib/world/**`,
`lib/entities/runner.dart`, `lib/systems/{collision,input_controller,scoring}.dart`,
`lib/core/**` (captain owns `config.dart`/`assets.dart` — ask, do not edit),
`pubspec.yaml`, `test/game_smoke_test.dart`, `.github/workflows/**`,
`android/**`, `tool/**`, `docs/*.md`, and never `main`.

**Interface (frozen — the game loop and the painter call exactly these):**

```dart
class SpawnDirector {
  SpawnDirector({required int seed});
  final List<Obstacle> obstacles;   // the painter draws these
  final List<Coin> coins;
  void reset();
  void update(double runnerZ, double speed, double metres);
}

enum ObstacleKind { barrierLow, barrierHigh, train, cones }
class Obstacle { ObstacleKind kind; int lane; double z; int id; bool passed; /* + getters */ }
class Coin { int lane; double z; double y; bool taken; }
class Difficulty { static double speedAt(double m); static double gapAt(double m, double speed);
                   static int maxBlockedLanes(double m); static ObstacleKind pickKind(double m, Random r); }
```

**The fairness law you must keep and prove (docs/GAME_DESIGN.md §5.3):**

1. Never all three lanes blocked at any z — there is always a free lane.
2. Between two event groups there is at least `speed * Tune.minReact` metres.
3. The free lane never jumps two lanes between consecutive events.
4. Every obstacle kind must be clearable by exactly one of: jump (barrierLow,
   cones), roll (barrierHigh), lane change (train) — a test must exist per kind
   using the numbers in `Obstacle` (`height`, `gapUnder`, `length`).

Numbers come from `lib/core/config.dart` (`Tune.laneX`, `speedStart`, `speedCap`,
`spawnAhead`, `recycleBehind`, `minReact`, `freeLaneWin`, `coinValue`). Seeded
`math.Random` only — no wall-clock, no `Random()` without a seed.

## 2. Your check — then push

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Keshab1997/flutter-bootstrap/main/setup.sh) \
  --root /var/tmp/flutter --quiet --json
export PATH=/var/tmp/flutter/bin:$PATH PUB_CACHE=/var/tmp/pub-cache

python3 tool/preflight.py
flutter test test/spawn_fairness_test.dart
```

Your test must simulate at least 10 000 metres at several seeds, replaying the
director at a fixed dt, and assert: for every z-window of `Tune.freeLaneWin`
metres at least one lane is unobstructed; consecutive event gaps honour
`minReact`; the free lane moves at most one step; and for each obstacle kind the
hero's clearance rules (from `Obstacle`'s numbers) admit a solution. It must
also catch a deliberately unfair layout — include a negative test that feeds a
three-lane-blocked arrangement to the checker and expects a failure, so the
checker itself is proven.

Never run `flutter analyze`, the full suite, `flutter build`, `gradlew` or CI.

```bash
git add -A
git commit -m "feat(spawner): fairness law, difficulty curve and coin patterns, with proof"
git push -u origin agent/C/spawner-fair
```

## 3. Report — copy-paste this block back to Keshab

```
AGENT C DONE
branch: agent/C/spawner-fair
sha: <git rev-parse --short HEAD>
files: <git diff --stat origin/main...HEAD | tail -1>
check: preflight ok; flutter test test/spawn_fairness_test.dart → pass, N tests
changed: <one sentence>
fairness evidence: <metres simulated, seeds, what the negative test proved>
new assets (for the captain to wire): <paths, or none>
not touched: game loop, painter, ui, world, runner, core, pubspec
blocked: <none | what stopped you>
```

## 4. Stop rules

Stop and report if a change would need `lib/core/config.dart`, the collision
rules or the game loop; if the fairness law cannot be satisfied with the current
numbers (say which number must change and to what); or if your test fails for a
reason outside your diff.

✂ ═══════════════ COPY ENDS HERE ═══════════════

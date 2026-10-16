✂ ═══════════════ COPY FROM HERE (give the whole block to agent A) ═══════════════

# You are agent A. One task, one branch, then you stop.

You work in your own sandbox. Nobody else is watching this chat. Do the task
below, push your branch, report in the format at the end. Do not ask Keshab
questions — if something is unclear or too big, stop and say so in your report.

## 0. GitHub access — check first, pair only if asked to

```bash
DST=/home/user/agent-bootstrap
[ -f "$DST/gh_app.py" ] || git clone https://github.com/Keshab1997/agent-bootstrap "$DST"
python3 "$DST/gh_app.py" connect     # ALREADY CONNECTED → nothing to do
```

If it prints a code like `XXXX-XXXX`, show it as a headline and wait for
Keshab's approval. Never ask him for a token. Turn ended before he approved?
`python3 "$DST/device_pair.py" poll 60` — same code, still valid ~15 min.

## 1. Your task

**Goal:** the corridor looks like a real place at golden hour — layered city
depth beside the track, richer rails and a warmer, denser street life — using
AI-generated sprites, without touching gameplay.

**Repo:** `Keshab1997/metro-dash` · **Branch:** `agent/A/world-art`

```bash
cd /home/user
[ -d metro-dash ] || git clone https://github.com/Keshab1997/metro-dash.git /home/user/metro-dash
cd /home/user/metro-dash
git config core.fileMode false
git config user.name "Keshab Sarkar"
git config user.email "Keshab1997@users.noreply.github.com"
git config credential.helper '!f(){ echo username=x-access-token; echo "password=$(cat /home/user/agent-bootstrap/secrets/gh_token.txt)"; }; f'
git fetch origin && git checkout -B agent/A/world-art origin/main
```

**Files you own (only these):**

- `lib/world/skyline.dart`
- `lib/world/track_builder.dart`
- `lib/world/environment.dart`
- NEW sprite files only under `assets/sprites/` whose names start with
  `city_`, `prop_`, `sky_`, `grass_`, `rail_`
- NEW raw renders you keep as provenance under `docs/art/` with your prefixes

**DO NOT TOUCH:** `lib/game/**`, `lib/systems/**`, `lib/entities/**`,
`lib/ui/**`, `lib/render/**`, `lib/core/**` (ask the captain — he owns
`assets.dart`), `pubspec.yaml`, `pubspec.lock`, `test/**`,
`.github/workflows/**`, `android/**`, `ios/**`, `tool/**`, `docs/*.md`, and
never `main`.

**Interface (frozen — keep these signatures working exactly):**

```dart
class Skyline   { void update(double dt); void paint(Canvas, Size, Projection, GameAssets?); }
class TrackBuilder { void paint(Canvas, Size, Projection); }
class Environment  { Environment({int seed = 7}); void update(double runnerZ); void paint(Canvas, Projection, double time); void reset(); }
```

`Projection` gives you `project(x, y, z)`, `groundQuad(...)`, `uprightQuad(...)`,
`wallQuad(...)`, `fadeAt(z)`, `horizonY`, `camZ`, `nearZ`. World units: lane
centres are `Tune.laneX` (±1), `y = 0` is the rail head, the visible range is
`Tune.viewNear .. Tune.viewFar`. **Do not add sprites the captain has not wired
into `lib/core/assets.dart`** — if you generate new images, list their exact
paths in your report and the captain will load them; until then draw with
canvas primitives.

Art rules: palette in `lib/core/palette.dart` only; the sun is left-of-centre
and every lit face points up-left; below-the-horizon geometry must stay
readable at 360 px wide. Generate images in this sandbox (image generation is
available), then chroma-key and pivot them with:

```bash
python3 -m pip install --quiet pillow
python3 tool/slice_sprites.py RAW.png assets/sprites/NAME.png --height 420
```

## 2. Your checks — then push

Install the SDK once (no credentials, ~50 s):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Keshab1997/flutter-bootstrap/main/setup.sh) \
  --root /var/tmp/flutter --quiet --json
export PATH=/var/tmp/flutter/bin:$PATH PUB_CACHE=/var/tmp/pub-cache
```

Run exactly these two, and only these:

```bash
python3 tool/preflight.py
flutter test test/game_smoke_test.dart
```

Never run `flutter analyze`, the full suite, `flutter build`, `gradlew` or CI.

```bash
git add -A
git commit -m "feat(world): layer the city, the rails and the street at golden hour"
git push -u origin agent/A/world-art
```

## 3. Report — copy-paste this block back to Keshab

```
AGENT A DONE
branch: agent/A/world-art
sha: <git rev-parse --short HEAD>
files: <git diff --stat origin/main...HEAD | tail -1>
check: preflight ok; flutter test test/game_smoke_test.dart → pass
changed: <one sentence>
new assets (for the captain to wire): <paths, or none>
not touched: gameplay, systems, core, pubspec, tests, workflows
blocked: <none | what stopped you>
```

## 4. Stop rules

Stop and report if the change needs a file you do not own, if a new sprite has
to be loaded by `lib/core/assets.dart`, if the smoke test fails for a reason
outside your diff, or if you would need to change gameplay to make the art work.

✂ ═══════════════ COPY ENDS HERE ═══════════════

# 📚 Metro Dash — ডিজাইন ডকুমেন্টেশন

> **Repo:** `Keshab1997/dog-road-runner` · **তারিখ:** 2026-10-17 · **স্ট্যাটাস:** ডিজাইন লক, কোড Batch 0-এ শুরু

পুরনো "Puppy Dash" prototype → **সম্পূর্ণ নতুন গেম**: Subway Surfers-ঘরানার 3-lane endless runner, কলকাতা-themed, AI-jenerated real-feel asset, pseudo-3D perspective।

## কোন ফাইলে কী

| ফাইল | কী পাবে |
|---|---|
| **[GAME_DESIGN.md](GAME_DESIGN.md)** | গেম কেমন হবে — loop, camera, controls, obstacle, fairness rule, scoring, UI, audio, perf budget, অ-লক্ষ্য, খোলা সিদ্ধান্ত |
| **[TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md)** | কী দিয়ে বানাব — Flame stack, folder layout + worker ownership, projection math, tunables, save schema, gate/CI/deploy, testing |
| **[ASSET_PIPELINE.md](ASSET_PIPELINE.md)** | asset কোথা থেকে — AI prompt, sprite spec, post-process, audio list, registration table |
| **[ROADMAP_BATCHES.md](ROADMAP_BATCHES.md)** | কোন ক্রমে — Batch 0 (reboot) → Batch 1 (A∥B∥C) → polish → RC |
| **[ART_DIRECTION.md](ART_DIRECTION.md)** | দেখতে কেমন — palette hex, lighting, motif, motion principles |
| **[art/key-art.png](art/key-art.png)**, **[art/character-ref.png](art/character-ref.png)** | style lock করা reference ছবি (AI-generated, original) |

## এক নজরে সিদ্ধান্ত

- **গেম:** 3 lane · swipe (left/right/jump/roll) · coins · powerup · fairness-guaranteed spawn · local save
- **স্টাইল:** stylized-3D look, golden-hour Kolkata (ট্রাম, Ambassador taxi, Howrah-ধাঁচের bridge, festival lights), original teen runner (teal hoodie + orange backpack)
- **টেক:** Flutter + Flame, 2D sprite + `1/z` perspective projection, সব asset repo-তে bundled, backend নেই
- **পুরনোটা:** `lib/main.dart` (Puppy Dash, 717 লাইন) **Batch 0-তে ডিলিট** — কিছুই reuse করা হবে না
- **ডেলিভারি:** Captain Batch 0 → তারপর worker A/B/C প্রতিটা আলাদা ফাইলে parallel → প্রতিটা batch-এর পর web preview link

## Keshab-এর জন্য খোলা সিদ্ধান্ত (না বললে ডিফল্ট)

| # | প্রশ্ন | ডিফল্ট |
|---|---|---|
| D1 | গেমের নাম + repo rename? | **Metro Dash** (repo rename নয়) |
| D2 | হিরোর নাম? | `Raju` (শুধু internal) |
| D3 | ডগ (পুরনো repo নাম) থাকবে? | v2-তে unlockable pet |
| D4 | কোড কখন শুরু? | Keshab বললেই Batch 0 |

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only progress storage. No account, no backend
/// (docs/GAME_DESIGN.md §12). Every call is failure-tolerant: a broken store
/// costs the player a high score, never a crash.
class SaveService {
  static const _kBest = 'mdr.best_score';
  static const _kCoins = 'mdr.total_coins';
  static const _kRuns = 'mdr.runs';
  static const _kSound = 'mdr.sound';
  static const _kMusic = 'mdr.music';
  static const _kLang = 'mdr.lang';

  SharedPreferences? _prefs;
  Timer? _debounce;

  int best = 0;
  int totalCoins = 0;
  int runs = 0;
  bool sound = true;
  bool music = true;
  String lang = 'en';

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final p = _prefs!;
      best = p.getInt(_kBest) ?? 0;
      totalCoins = p.getInt(_kCoins) ?? 0;
      runs = p.getInt(_kRuns) ?? 0;
      sound = p.getBool(_kSound) ?? true;
      music = p.getBool(_kMusic) ?? true;
      lang = p.getString(_kLang) ?? 'en';
    } catch (_) {
      _prefs = null; // memory-only session
    }
  }

  void recordRun({required int score, required int coins}) {
    runs++;
    totalCoins += coins;
    if (score > best) best = score;
    _schedule();
  }

  void setLang(String code) {
    lang = code;
    _schedule();
  }

  void setSound(bool on) {
    sound = on;
    _schedule();
  }

  void setMusic(bool on) {
    music = on;
    _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _write);
  }

  Future<void> _write() async {
    final p = _prefs;
    if (p == null) return;
    try {
      await p.setInt(_kBest, best);
      await p.setInt(_kCoins, totalCoins);
      await p.setInt(_kRuns, runs);
      await p.setBool(_kSound, sound);
      await p.setBool(_kMusic, music);
      await p.setString(_kLang, lang);
    } catch (_) {
      // ignore — the session keeps working from memory
    }
  }
}

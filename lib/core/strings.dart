/// Player-facing copy in English and Bangla (docs/GAME_DESIGN.md §8).
class Strings {
  const Strings(this.code);

  final String code; // 'en' | 'bn'

  static const _en = <String, String>{
    'title': 'METRO DASH',
    'tagline': 'Sunset run across the city',
    'play': 'PLAY',
    'retry': 'RETRY',
    'menu': 'MENU',
    'resume': 'RESUME',
    'restart': 'RESTART',
    'quit': 'QUIT',
    'best': 'BEST',
    'score': 'SCORE',
    'coins': 'COINS',
    'paused': 'PAUSED',
    'gameOver': 'NICE RUN!',
    'newBest': 'NEW BEST!',
    'hint': 'Swipe to move · up to jump · down to roll',
    'loading': 'Warming up…',
  };

  static const _bn = <String, String>{
    'title': 'মেট্রো ড্যাশ',
    'tagline': 'সন্ধ্যার আলোয় শহরের দৌড়',
    'play': 'খেলো',
    'retry': 'আবার',
    'menu': 'মেনু',
    'resume': 'চালু রাখো',
    'restart': 'নতুন করে',
    'quit': 'বন্ধ',
    'best': 'সেরা',
    'score': 'স্কোর',
    'coins': 'কয়েন',
    'paused': 'থেমে আছে',
    'gameOver': 'দারুণ দৌড়!',
    'newBest': 'নতুন রেকর্ড!',
    'hint': 'সোয়াইপ করে লাইন বদলাও · উপরে লাফ · নিচে রোল',
    'loading': 'প্রস্তুতি চলছে…',
  };

  String t(String key) => (code == 'bn' ? _bn : _en)[key] ?? key;
}

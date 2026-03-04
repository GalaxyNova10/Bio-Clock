/// Maps produce names to their accurate Unicode emoji.
/// Used by inventory cards, detail sheets, and scan results.
class ProduceEmoji {
  ProduceEmoji._();

  /// Master lookup table. Key = lowercase produce name (or substring).
  /// Lookup is done via [getEmoji] which checks for substring matches.
  static const Map<String, String> _table = {
    // ── Leafy Greens ─────────────────────────────────────────
    'spinach': '🥬',
    'lettuce': '🥬',
    'kale': '🥬',
    'cabbage': '🥦',
    'bok choy': '🥬',
    'arugula': '🥬',
    'watercress': '🥬',
    'swiss chard': '🥬',
    'collard': '🥬',
    'endive': '🥬',

    // ── Cruciferous ───────────────────────────────────────────
    'broccoli': '🥦',
    'cauliflower': '🥦',
    'brussels': '🥦',

    // ── Root Vegetables ───────────────────────────────────────
    'carrot': '🥕',
    'radish': '🌶️',
    'turnip': '🫚',
    'beet': '🫐',
    'beetroot': '🫐',
    'parsnip': '🥕',
    'sweet potato': '🍠',
    'yam': '🍠',
    'potato': '🥔',

    // ── Fruiting Vegetables ───────────────────────────────────
    'tomato': '🍅',
    'bell pepper': '🫑',
    'pepper': '🌶️',
    'chili': '🌶️',
    'chilli': '🌶️',
    'eggplant': '🍆',
    'aubergine': '🍆',
    'zucchini': '🥒',
    'courgette': '🥒',
    'cucumber': '🥒',
    'pumpkin': '🎃',
    'squash': '🎃',
    'corn': '🌽',
    'maize': '🌽',

    // ── Alliums ───────────────────────────────────────────────
    'onion': '🧅',
    'garlic': '🧄',
    'leek': '🧄',
    'shallot': '🧅',
    'chive': '🌿',
    'scallion': '🌿',
    'spring onion': '🌿',

    // ── Mushrooms ─────────────────────────────────────────────
    'mushroom': '🍄',
    'portobello': '🍄',
    'shiitake': '🍄',

    // ── Herbs ─────────────────────────────────────────────────
    'herb': '🌿',
    'basil': '🌿',
    'mint': '🌿',
    'parsley': '🌿',
    'cilantro': '🌿',
    'coriander': '🌿',
    'thyme': '🌿',
    'rosemary': '🌿',
    'dill': '🌿',
    'sage': '🌿',
    'oregano': '🌿',

    // ── Legumes / Pods ────────────────────────────────────────
    'pea': '🫛',
    'bean': '🫛',
    'edamame': '🫛',
    'snap pea': '🫛',
    'green bean': '🫛',

    // ── Citrus Fruits ─────────────────────────────────────────
    'lemon': '🍋',
    'lime': '🍋',
    'orange': '🍊',
    'mandarin': '🍊',
    'clementine': '🍊',
    'tangerine': '🍊',
    'grapefruit': '🍊',

    // ── Tropical Fruits ───────────────────────────────────────
    'banana': '🍌',
    'mango': '🥭',
    'pineapple': '🍍',
    'coconut': '🥥',
    'papaya': '🍈',
    'guava': '🍈',
    'passion fruit': '🍈',
    'dragon fruit': '🍈',
    'lychee': '🍈',
    'jackfruit': '🍈',
    'durian': '🍈',
    'kiwi': '🥝',

    // ── Stone Fruits ──────────────────────────────────────────
    'peach': '🍑',
    'nectarine': '🍑',
    'plum': '🫐',
    'cherry': '🍒',
    'apricot': '🍑',

    // ── Berries ───────────────────────────────────────────────
    'strawberry': '🍓',
    'blueberry': '🫐',
    'raspberry': '🍓',
    'blackberry': '🍇',
    'grape': '🍇',
    'cranberry': '🍓',
    'gooseberry': '🍓',

    // ── Common Tree Fruits ────────────────────────────────────
    'apple': '🍎',
    'pear': '🍐',
    'watermelon': '🍉',
    'melon': '🍈',
    'honeydew': '🍈',
    'cantaloupe': '🍈',
    'fig': '🫐',
    'pomegranate': '🫐',
    'avocado': '🥑',

    // ── Celery / Stalks ───────────────────────────────────────
    'celery': '🥬',
    'fennel': '🌿',
    'asparagus': '🥦',
    'artichoke': '🥦',
  };

  /// Returns the most accurate emoji for a produce [name].
  ///
  /// Strategy:
  /// 1. Exact lowercase match.
  /// 2. Check if the table key is contained in [name] (e.g. "Fresh Spinach" → "spinach").
  /// 3. Check if [name] is contained in the table key.
  /// 4. Fallback: 🥗 (salad bowl — clearly food-related but not wrong).
  static String getEmoji(String name) {
    final lower = name.toLowerCase().trim();

    // 1. Exact match
    if (_table.containsKey(lower)) return _table[lower]!;

    // 2. Table key is a substring of the produce name
    //    e.g. name = "Fresh Spinach", key = "spinach" → match
    for (final entry in _table.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // 3. Produce name is a substring of a table key
    //    e.g. name = "pepper", key = "bell pepper" → match on "pepper"
    for (final entry in _table.entries) {
      if (entry.key.contains(lower)) return entry.value;
    }

    // 4. Fallback
    return '🥗';
  }
}

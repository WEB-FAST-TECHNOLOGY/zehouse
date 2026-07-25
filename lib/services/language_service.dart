import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final String region;
  final String flag;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.region,
    required this.flag,
  });
}

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  static LanguageService get instance => _instance;
  LanguageService._internal();

  static const String _prefKey = 'selected_language_code';

  // Supported locales that have translation files
  static const Set<String> _supportedTranslationCodes = {
    'fr',
    'en',
    'ar',
    'es',
    'pt',
  };

  // Optional BuildContext for locale switching — set by the app
  BuildContext? _context;
  void setContext(BuildContext ctx) => _context = ctx;

  String _currentCode = 'fr';
  String get currentCode => _currentCode;

  LanguageModel get currentLanguage => allLanguages.firstWhere(
    (l) => l.code == _currentCode,
    orElse: () => allLanguages.first,
  );

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCode = prefs.getString(_prefKey) ?? 'fr';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_currentCode == code) return;
    _currentCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);

    // Switch easy_localization locale if a translation file exists
    if (_context != null) {
      final translationCode = _supportedTranslationCodes.contains(code)
          ? code
          : 'fr';
      try {
        await _context!.setLocale(Locale(translationCode));
      } catch (_) {}
    }

    notifyListeners();
  }

  // ─── EUROPE (36) ───────────────────────────────────────────────────────────
  static const List<LanguageModel> europeLanguages = [
    LanguageModel(
      code: 'fr',
      name: 'Français',
      nativeName: 'Français',
      region: 'Europe',
      flag: '🇫🇷',
    ),
    LanguageModel(
      code: 'en',
      name: 'Anglais',
      nativeName: 'English',
      region: 'Europe',
      flag: '🇬🇧',
    ),
    LanguageModel(
      code: 'es',
      name: 'Espagnol',
      nativeName: 'Español',
      region: 'Europe',
      flag: '🇪🇸',
    ),
    LanguageModel(
      code: 'de',
      name: 'Allemand',
      nativeName: 'Deutsch',
      region: 'Europe',
      flag: '🇩🇪',
    ),
    LanguageModel(
      code: 'it',
      name: 'Italien',
      nativeName: 'Italiano',
      region: 'Europe',
      flag: '🇮🇹',
    ),
    LanguageModel(
      code: 'pt',
      name: 'Portugais',
      nativeName: 'Português',
      region: 'Europe',
      flag: '🇵🇹',
    ),
    LanguageModel(
      code: 'nl',
      name: 'Néerlandais',
      nativeName: 'Nederlands',
      region: 'Europe',
      flag: '🇳🇱',
    ),
    LanguageModel(
      code: 'el',
      name: 'Grec',
      nativeName: 'Ελληνικά',
      region: 'Europe',
      flag: '🇬🇷',
    ),
    LanguageModel(
      code: 'pl',
      name: 'Polonais',
      nativeName: 'Polski',
      region: 'Europe',
      flag: '🇵🇱',
    ),
    LanguageModel(
      code: 'cs',
      name: 'Tchèque',
      nativeName: 'Čeština',
      region: 'Europe',
      flag: '🇨🇿',
    ),
    LanguageModel(
      code: 'hu',
      name: 'Hongrois',
      nativeName: 'Magyar',
      region: 'Europe',
      flag: '🇭🇺',
    ),
    LanguageModel(
      code: 'ro',
      name: 'Roumain',
      nativeName: 'Română',
      region: 'Europe',
      flag: '🇷🇴',
    ),
    LanguageModel(
      code: 'bg',
      name: 'Bulgare',
      nativeName: 'Български',
      region: 'Europe',
      flag: '🇧🇬',
    ),
    LanguageModel(
      code: 'sr',
      name: 'Serbe',
      nativeName: 'Српски',
      region: 'Europe',
      flag: '🇷🇸',
    ),
    LanguageModel(
      code: 'hr',
      name: 'Croate',
      nativeName: 'Hrvatski',
      region: 'Europe',
      flag: '🇭🇷',
    ),
    LanguageModel(
      code: 'sl',
      name: 'Slovène',
      nativeName: 'Slovenščina',
      region: 'Europe',
      flag: '🇸🇮',
    ),
    LanguageModel(
      code: 'sk',
      name: 'Slovaque',
      nativeName: 'Slovenčina',
      region: 'Europe',
      flag: '🇸🇰',
    ),
    LanguageModel(
      code: 'uk',
      name: 'Ukrainien',
      nativeName: 'Українська',
      region: 'Europe',
      flag: '🇺🇦',
    ),
    LanguageModel(
      code: 'ru',
      name: 'Russe',
      nativeName: 'Русский',
      region: 'Europe',
      flag: '🇷🇺',
    ),
    LanguageModel(
      code: 'be',
      name: 'Biélorusse',
      nativeName: 'Беларуская',
      region: 'Europe',
      flag: '🇧🇾',
    ),
    LanguageModel(
      code: 'lt',
      name: 'Lituanien',
      nativeName: 'Lietuvių',
      region: 'Europe',
      flag: '🇱🇹',
    ),
    LanguageModel(
      code: 'lv',
      name: 'Letton',
      nativeName: 'Latviešu',
      region: 'Europe',
      flag: '🇱🇻',
    ),
    LanguageModel(
      code: 'et',
      name: 'Estonien',
      nativeName: 'Eesti',
      region: 'Europe',
      flag: '🇪🇪',
    ),
    LanguageModel(
      code: 'fi',
      name: 'Finnois',
      nativeName: 'Suomi',
      region: 'Europe',
      flag: '🇫🇮',
    ),
    LanguageModel(
      code: 'sv',
      name: 'Suédois',
      nativeName: 'Svenska',
      region: 'Europe',
      flag: '🇸🇪',
    ),
    LanguageModel(
      code: 'no',
      name: 'Norvégien',
      nativeName: 'Norsk',
      region: 'Europe',
      flag: '🇳🇴',
    ),
    LanguageModel(
      code: 'da',
      name: 'Danois',
      nativeName: 'Dansk',
      region: 'Europe',
      flag: '🇩🇰',
    ),
    LanguageModel(
      code: 'is',
      name: 'Islandais',
      nativeName: 'Íslenska',
      region: 'Europe',
      flag: '🇮🇸',
    ),
    LanguageModel(
      code: 'ga',
      name: 'Irlandais',
      nativeName: 'Gaeilge',
      region: 'Europe',
      flag: '🇮🇪',
    ),
    LanguageModel(
      code: 'cy',
      name: 'Gallois',
      nativeName: 'Cymraeg',
      region: 'Europe',
      flag: '🏴󠁧󠁢󠁷󠁬󠁳󠁿',
    ),
    LanguageModel(
      code: 'ca',
      name: 'Catalan',
      nativeName: 'Català',
      region: 'Europe',
      flag: '🏴',
    ),
    LanguageModel(
      code: 'eu',
      name: 'Basque',
      nativeName: 'Euskara',
      region: 'Europe',
      flag: '🏴',
    ),
    LanguageModel(
      code: 'mt',
      name: 'Maltais',
      nativeName: 'Malti',
      region: 'Europe',
      flag: '🇲🇹',
    ),
    LanguageModel(
      code: 'sq',
      name: 'Albanais',
      nativeName: 'Shqip',
      region: 'Europe',
      flag: '🇦🇱',
    ),
  ];

  // ─── AFRIQUE (19) ──────────────────────────────────────────────────────────
  static const List<LanguageModel> africaLanguages = [
    LanguageModel(
      code: 'ar',
      name: 'Arabe',
      nativeName: 'العربية',
      region: 'Afrique',
      flag: '🌍',
    ),
    LanguageModel(
      code: 'sw',
      name: 'Swahili',
      nativeName: 'Kiswahili',
      region: 'Afrique',
      flag: '🌍',
    ),
    LanguageModel(
      code: 'ha',
      name: 'Hausa',
      nativeName: 'Hausa',
      region: 'Afrique',
      flag: '🌍',
    ),
    LanguageModel(
      code: 'yo',
      name: 'Yoruba',
      nativeName: 'Yorùbá',
      region: 'Afrique',
      flag: '🌍',
    ),
    LanguageModel(
      code: 'ig',
      name: 'Igbo',
      nativeName: 'Igbo',
      region: 'Afrique',
      flag: '🌍',
    ),
    LanguageModel(
      code: 'am',
      name: 'Amharique',
      nativeName: 'አማርኛ',
      region: 'Afrique',
      flag: '🇪🇹',
    ),
    LanguageModel(
      code: 'om',
      name: 'Oromo',
      nativeName: 'Afaan Oromoo',
      region: 'Afrique',
      flag: '🌍',
    ),
    LanguageModel(
      code: 'zu',
      name: 'Zulu',
      nativeName: 'isiZulu',
      region: 'Afrique',
      flag: '🇿🇦',
    ),
    LanguageModel(
      code: 'xh',
      name: 'Xhosa',
      nativeName: 'isiXhosa',
      region: 'Afrique',
      flag: '🇿🇦',
    ),
    LanguageModel(
      code: 'sn',
      name: 'Shona',
      nativeName: 'chiShona',
      region: 'Afrique',
      flag: '🇿🇼',
    ),
    LanguageModel(
      code: 'wo',
      name: 'Wolof',
      nativeName: 'Wolof',
      region: 'Afrique',
      flag: '🇸🇳',
    ),
    LanguageModel(
      code: 'bm',
      name: 'Bambara',
      nativeName: 'Bamanankan',
      region: 'Afrique',
      flag: '🇲🇱',
    ),
    LanguageModel(
      code: 'ln',
      name: 'Lingala',
      nativeName: 'Lingála',
      region: 'Afrique',
      flag: '🇨🇩',
    ),
    LanguageModel(
      code: 'so',
      name: 'Somali',
      nativeName: 'Soomaali',
      region: 'Afrique',
      flag: '🇸🇴',
    ),
    LanguageModel(
      code: 'ti',
      name: 'Tigrinya',
      nativeName: 'ትግርኛ',
      region: 'Afrique',
      flag: '🇪🇷',
    ),
    LanguageModel(
      code: 'ff',
      name: 'Peul',
      nativeName: 'Fulfulde',
      region: 'Afrique',
      flag: '🌍',
    ),
    LanguageModel(
      code: 'rw',
      name: 'Kinyarwanda',
      nativeName: 'Kinyarwanda',
      region: 'Afrique',
      flag: '🇷🇼',
    ),
    LanguageModel(
      code: 'rn',
      name: 'Kirundi',
      nativeName: 'Kirundi',
      region: 'Afrique',
      flag: '🇧🇮',
    ),
    LanguageModel(
      code: 'mg',
      name: 'Malgache',
      nativeName: 'Malagasy',
      region: 'Afrique',
      flag: '🇲🇬',
    ),
  ];

  // ─── ASIE (30) ─────────────────────────────────────────────────────────────
  static const List<LanguageModel> asiaLanguages = [
    LanguageModel(
      code: 'zh',
      name: 'Chinois',
      nativeName: '中文',
      region: 'Asie',
      flag: '🇨🇳',
    ),
    LanguageModel(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      region: 'Asie',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'bn',
      name: 'Bengali',
      nativeName: 'বাংলা',
      region: 'Asie',
      flag: '🇧🇩',
    ),
    LanguageModel(
      code: 'ur',
      name: 'Ourdou',
      nativeName: 'اردو',
      region: 'Asie',
      flag: '🇵🇰',
    ),
    LanguageModel(
      code: 'ja',
      name: 'Japonais',
      nativeName: '日本語',
      region: 'Asie',
      flag: '🇯🇵',
    ),
    LanguageModel(
      code: 'ko',
      name: 'Coréen',
      nativeName: '한국어',
      region: 'Asie',
      flag: '🇰🇷',
    ),
    LanguageModel(
      code: 'vi',
      name: 'Vietnamien',
      nativeName: 'Tiếng Việt',
      region: 'Asie',
      flag: '🇻🇳',
    ),
    LanguageModel(
      code: 'th',
      name: 'Thaï',
      nativeName: 'ภาษาไทย',
      region: 'Asie',
      flag: '🇹🇭',
    ),
    LanguageModel(
      code: 'fil',
      name: 'Filipino',
      nativeName: 'Filipino',
      region: 'Asie',
      flag: '🇵🇭',
    ),
    LanguageModel(
      code: 'id',
      name: 'Indonésien',
      nativeName: 'Bahasa Indonesia',
      region: 'Asie',
      flag: '🇮🇩',
    ),
    LanguageModel(
      code: 'ms',
      name: 'Malais',
      nativeName: 'Bahasa Melayu',
      region: 'Asie',
      flag: '🇲🇾',
    ),
    LanguageModel(
      code: 'my',
      name: 'Birman',
      nativeName: 'မြန်မာဘာသာ',
      region: 'Asie',
      flag: '🇲🇲',
    ),
    LanguageModel(
      code: 'km',
      name: 'Khmer',
      nativeName: 'ភាសាខ្មែរ',
      region: 'Asie',
      flag: '🇰🇭',
    ),
    LanguageModel(
      code: 'lo',
      name: 'Lao',
      nativeName: 'ພາສາລາວ',
      region: 'Asie',
      flag: '🇱🇦',
    ),
    LanguageModel(
      code: 'mn',
      name: 'Mongol',
      nativeName: 'Монгол',
      region: 'Asie',
      flag: '🇲🇳',
    ),
    LanguageModel(
      code: 'ne',
      name: 'Népalais',
      nativeName: 'नेपाली',
      region: 'Asie',
      flag: '🇳🇵',
    ),
    LanguageModel(
      code: 'si',
      name: 'Cinghalais',
      nativeName: 'සිංහල',
      region: 'Asie',
      flag: '🇱🇰',
    ),
    LanguageModel(
      code: 'ta',
      name: 'Tamoul',
      nativeName: 'தமிழ்',
      region: 'Asie',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'te',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      region: 'Asie',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'kn',
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      region: 'Asie',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'ml',
      name: 'Malayalam',
      nativeName: 'മലയാളം',
      region: 'Asie',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'mr',
      name: 'Marathi',
      nativeName: 'मराठी',
      region: 'Asie',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'gu',
      name: 'Gujarati',
      nativeName: 'ગુજરાતી',
      region: 'Asie',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'pa',
      name: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
      region: 'Asie',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'fa',
      name: 'Persan',
      nativeName: 'فارسی',
      region: 'Asie',
      flag: '🇮🇷',
    ),
    LanguageModel(
      code: 'he',
      name: 'Hébreu',
      nativeName: 'עברית',
      region: 'Asie',
      flag: '🇮🇱',
    ),
    LanguageModel(
      code: 'tr',
      name: 'Turc',
      nativeName: 'Türkçe',
      region: 'Asie',
      flag: '🇹🇷',
    ),
    LanguageModel(
      code: 'az',
      name: 'Azéri',
      nativeName: 'Azərbaycan',
      region: 'Asie',
      flag: '🇦🇿',
    ),
    LanguageModel(
      code: 'kk',
      name: 'Kazakh',
      nativeName: 'Қазақша',
      region: 'Asie',
      flag: '🇰🇿',
    ),
    LanguageModel(
      code: 'uz',
      name: 'Ouzbek',
      nativeName: 'Oʻzbek',
      region: 'Asie',
      flag: '🇺🇿',
    ),
  ];

  // ─── MOYEN-ORIENT (20) ─────────────────────────────────────────────────────
  static const List<LanguageModel> middleEastLanguages = [
    LanguageModel(
      code: 'ar-ME',
      name: 'Arabe (Moyen-Orient)',
      nativeName: 'العربية',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'ku',
      name: 'Kurde (Kurmandji)',
      nativeName: 'Kurdî',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'ku-s',
      name: 'Kurde (Sorani)',
      nativeName: 'کوردی',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'ps',
      name: 'Pachto',
      nativeName: 'پښتو',
      region: 'Moyen-Orient',
      flag: '🇦🇫',
    ),
    LanguageModel(
      code: 'prs',
      name: 'Dari',
      nativeName: 'دری',
      region: 'Moyen-Orient',
      flag: '🇦🇫',
    ),
    LanguageModel(
      code: 'tk',
      name: 'Turkmène',
      nativeName: 'Türkmençe',
      region: 'Moyen-Orient',
      flag: '🇹🇲',
    ),
    LanguageModel(
      code: 'tg',
      name: 'Tadjik',
      nativeName: 'Тоҷикӣ',
      region: 'Moyen-Orient',
      flag: '🇹🇯',
    ),
    LanguageModel(
      code: 'hy',
      name: 'Arménien',
      nativeName: 'Հայերեն',
      region: 'Moyen-Orient',
      flag: '🇦🇲',
    ),
    LanguageModel(
      code: 'ka',
      name: 'Géorgien',
      nativeName: 'ქართული',
      region: 'Moyen-Orient',
      flag: '🇬🇪',
    ),
    LanguageModel(
      code: 'bal',
      name: 'Baloutche',
      nativeName: 'بلوچی',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'sd',
      name: 'Sindhi',
      nativeName: 'سنڌي',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'ug',
      name: 'Ouïghour',
      nativeName: 'ئۇيغۇرچە',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'yi',
      name: 'Yiddish',
      nativeName: 'ייִדיש',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'arc',
      name: 'Araméen',
      nativeName: 'ܐܪܡܝܐ',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'aii',
      name: 'Assyrien',
      nativeName: 'ܐܬܘܪܝܐ',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'syc',
      name: 'Syriaque',
      nativeName: 'ܣܘܪܝܝܐ',
      region: 'Moyen-Orient',
      flag: '🌙',
    ),
    LanguageModel(
      code: 'lrc',
      name: 'Luri',
      nativeName: 'لری',
      region: 'Moyen-Orient',
      flag: '🇮🇷',
    ),
    LanguageModel(
      code: 'mzn',
      name: 'Mazandarani',
      nativeName: 'مازرونی',
      region: 'Moyen-Orient',
      flag: '🇮🇷',
    ),
    LanguageModel(
      code: 'glk',
      name: 'Gilaki',
      nativeName: 'گیلکی',
      region: 'Moyen-Orient',
      flag: '🇮🇷',
    ),
    LanguageModel(
      code: 'az-IR',
      name: 'Azéri d\'Iran',
      nativeName: 'آذربایجانی',
      region: 'Moyen-Orient',
      flag: '🇮🇷',
    ),
  ];

  static List<LanguageModel> get allLanguages => [
    ...europeLanguages,
    ...africaLanguages,
    ...asiaLanguages,
    ...middleEastLanguages,
  ];

  static Map<String, List<LanguageModel>> get byRegion => {
    'Europe': europeLanguages,
    'Afrique': africaLanguages,
    'Asie': asiaLanguages,
    'Moyen-Orient': middleEastLanguages,
  };
}

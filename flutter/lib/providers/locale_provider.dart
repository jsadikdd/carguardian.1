import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'en';
    _locale = Locale(saved);
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
    _locale = Locale(langCode);
    notifyListeners();
  }

  String get languageName {
    switch (_locale.languageCode) {
      case 'hi':
        return 'हिंदी';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }
}

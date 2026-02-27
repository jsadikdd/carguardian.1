import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const _prefKey = 'app_language';

  Locale get locale      => _locale;
  String get languageCode => _locale.languageCode;

  LanguageProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code  = prefs.getString(_prefKey) ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    notifyListeners();
  }
}

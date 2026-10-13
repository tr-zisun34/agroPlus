import 'package:flutter/material.dart';

import 'secure_storage.dart';

const supportedLanguageCodes = ['en', 'bn'];

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> loadSavedLocale() async {
    final savedCode = await SecureStorage.instance.getLanguageCode();
    if (savedCode != null && supportedLanguageCodes.contains(savedCode)) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> toggleLocale() async {
    _locale = _locale.languageCode == 'en' ? const Locale('bn') : const Locale('en');
    notifyListeners();
    await SecureStorage.instance.saveLanguageCode(_locale.languageCode);
  }
}

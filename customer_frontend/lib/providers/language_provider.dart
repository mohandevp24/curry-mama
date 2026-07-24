import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  bool _isTamil = false; // Default to English

  bool get isTamil => _isTamil;

  void toggleLanguage() {
    _isTamil = !_isTamil;
    notifyListeners();
  }

  String t(String english, String tamil) {
    return _isTamil ? tamil : english;
  }
}

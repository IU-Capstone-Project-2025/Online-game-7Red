import 'dart:convert';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Map<String, Map<String, String>> _localizedStrings;
  
  AppLocalizations(this._localizedStrings);

  String getString(String id, String languageCode) {
    return _localizedStrings[id]?[languageCode] ?? 
           _localizedStrings[id]?['en'] ?? 
           '$id not found';
  }

  static Future<AppLocalizations> load() async {
    final jsonString = await rootBundle.loadString('lib/assets/localization.json');
    final jsonList = json.decode(jsonString) as List;
    
    final localizedMap = <String, Map<String, String>>{};
    for (var item in jsonList) {
      localizedMap[item['id']] = {
        'en': item['en'],
        'ru': item['ru'],
      };
    }
    
    return AppLocalizations(localizedMap);
  }
}
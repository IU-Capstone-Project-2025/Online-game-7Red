import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DayProvider extends ChangeNotifier {
  int _day = 0;
  int get day => _day;
  set day(int value) {
    _day = value;
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/localization.dart';

// Provider
class GameProvider extends ChangeNotifier {
  // For manipulation with ID of user
  int _myID = -1;
  int get myID => _myID;
  set myID(int value) {
    _myID = value;
    notifyListeners();
  }

  // For manipulation with name of user
  String _myName = 'HavNotName';
  String get myName => _myName;
  set myName(String value) {
    _myName = value;
    notifyListeners();
  }

  // For manipulation with email of user
  String _email = 'NavNotEmail';
  String get email => _email;
  set email(String value) {
    _email = value;
    notifyListeners();
  }

  // For manipulation with password of user
  String _password = 'NavNotPass';
  String get password => _password;
  set password(String value) {
    _password = value;
    notifyListeners();
  }

  // For manipulation with ID of the current room in which the user is
  String _roomId = '00000';
  String get roomId => _roomId;
  set roomId(String value) {
    _roomId = value;
    notifyListeners();
  }

  // For manipulation with password of the current room in which the user is
  String _roomPassword = '00000';
  String get roomPassword => _roomPassword;
  set roomPassword(String value) {
    _roomPassword = value;
    notifyListeners();
  }

  // For manipulation with ready status of the user
  bool _ready = false;
  bool get ready => _ready;
  set ready(bool value) {
    _ready = value;
    notifyListeners();
  }

  // For indicate that the game is against AI
  bool _aiGame = false;
  bool get aiGame => _aiGame;
  set aiGame(bool value) {
    _aiGame = value;
    notifyListeners();
  }

  // For manipulation with number of players in the room
  int _playerNum = 0;
  int get playerNum => _playerNum;
  set playerNum(int value) {
    _playerNum = value;
    notifyListeners();
  }

  String _languageCode = 'en';
  String get languageCode => _languageCode;

  AppLocalizations? _localizations;
  AppLocalizations? get localizations => _localizations;

  void toggleLanguage() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _languageCode = _languageCode == 'ru' ? 'en' : 'ru';
    await prefs.setString('languageCode', _languageCode);
    notifyListeners();
  }

  Future<void> loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('languageCode') ?? 'en';
    notifyListeners();
  }

  Future<void> initialize() async {
    await loadLanguage();
    _localizations = await AppLocalizations.load();
  }

  // For saving the information about the user after registration/signin
  void saveMyPersonalInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('myName', _myName);
    await prefs.setInt('myID', _myID);
    await prefs.setString('email', _email);
    await prefs.setString('password', _password);
  }

  // For loading the information about the user
   void loadMyPersonalInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _myName = prefs.getString('myName') ?? 'HaveNotName';
    _myID = prefs.getInt('myID') ?? -1;
    _email = prefs.getString('email') ?? 'NavNotEmail';
    notifyListeners();
  }

  // For clearing the information about the user after signout
  void clearMyPersonalInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('myName');
    await prefs.remove('myID');
    await prefs.remove('email');
    await prefs.remove('password');
    _myName = 'HaveNotName';
    _myID = -1;
    _email = 'NavNotEmail';
    _password = 'NavNotPass';
    notifyListeners();
  }

  // For saving the information about the current room
  void saveRoomInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('roomId', _roomId);
    await prefs.setString('roomPassword', _roomPassword);
  }

  // For loading the information about the current room
  void loadRoomInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _roomId = prefs.getString('roomId') ?? '00000';
    _roomPassword = prefs.getString('roomPassword') ?? '00000';
    notifyListeners();
  }

  // For clearing the information about the current room
  void clearRoomInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomId');
    await prefs.remove('roomPassword');
    _roomId = '00000';
    _roomPassword = '00000';
    notifyListeners();
  }

  // For saving the ready status
  void saveReady() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ready', _ready);
  }

  // For clearing the ready status
  void clearReady() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('ready');
    _ready = false;
    notifyListeners();
  }

  // For saving the information about the AI-state game
  void aiGameSave() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiGame', _aiGame);
  }
}
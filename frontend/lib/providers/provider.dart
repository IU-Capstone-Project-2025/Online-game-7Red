import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class GameProvider extends ChangeNotifier {
  int _myID = -1;
  int get myID => _myID;
  set myID(int value) {
    _myID = value;
    notifyListeners();
  }

  String _myName = 'HavNotName';
  String get myName => _myName;
  set myName(String value) {
    _myName = value;
    notifyListeners();
  }

  String _email = 'NavNotEmail';
  String get email => _email;
  set email(String value) {
    _email = value;
    notifyListeners();
  }

  String _password = 'NavNotPass';
  String get password => _password;
  set password(String value) {
    _password = value;
    notifyListeners();
  }

  String _roomId = '00000';
  String get roomId => _roomId;
  set roomId(String value) {
    _roomId = value;
    notifyListeners();
  }

  String _roomPassword = '00000';
  String get roomPassword => _roomPassword;
  set roomPassword(String value) {
    _roomPassword = value;
    notifyListeners();
  }

  bool _ready = false;
  bool get ready => _ready;
  set ready(bool value) {
    _ready = value;
    notifyListeners();
  }

  void saveMyPersonalInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('myName', _myName);
    await prefs.setInt('myID', _myID);
    await prefs.setString('email', _email);
    await prefs.setString('password', _password);
  }

   void loadIdAndName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _myName = prefs.getString('myName') ?? 'HaveNotName';
    _myID = prefs.getInt('myID') ?? -1;
    notifyListeners();
  }

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

  void saveRoomInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('roomId', _roomId);
    await prefs.setString('roomPassword', _roomPassword);
  }

  void loadRoomInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _roomId = prefs.getString('roomId') ?? '00000';
    _roomPassword = prefs.getString('roomPassword') ?? '00000';
    notifyListeners();
  }

  void clearRoomInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomId');
    await prefs.remove('roomPassword');
    _roomId = '00000';
    _roomPassword = '00000';
    notifyListeners();
  }

  void saveReady() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ready', _ready);
  }

  void clearReady() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('ready');
    _ready = false;
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import '../database/models.dart';

/// The logged-in user and when they last logged in
class SessionService with ChangeNotifier {
  DbUser? _loggedInUser;
  bool firstLogin = false;
  String? _loginTime;
  String? get logTime => _loginTime;
  DbUser? get loggedInUser => _loggedInUser;

  void setLoggedInUser(DbUser user){
    _loggedInUser = user;
    notifyListeners();
  }

  void setUserProfilePicture(String pic){
    loggedInUser!.profilePicture = pic;
    notifyListeners();
  }
  void setUserFriends(int friends){
    loggedInUser!.numFriends = friends;
    notifyListeners();
  }

  void setLoginTime(String? logint){
    _loginTime = logint;
    if(_loginTime == null){
      firstLogin = true;
    }
    notifyListeners();
  }
}

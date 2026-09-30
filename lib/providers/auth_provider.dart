import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../models/user_model.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({UserService? userService})
    : _userService = userService ?? UserService() {
    _authSubscription = _userService.idTokenChanges.listen(
      _handleFirebaseSession,
    );
    _restoreSession();
  }

  final UserService _userService;
  StreamSubscription<User?>? _authSubscription;
  UserModel? _user;
  LoginType? _loginType;
  bool _initialized = false;

  UserModel? get user => _user;
  LoginType? get loginType => _loginType;
  bool get initialized => _initialized;

  Future<void> _restoreSession() async {
    await _userService.initialize();
    if (_userService.loginType == LoginType.dummyJson &&
        await _userService.isLoggedIn()) {
      _setSession(await _userService.getUserData(), LoginType.dummyJson);
      return;
    }

    if (_userService.currentUser != null) {
      _setSession(await _userService.getUserData(), LoginType.firebase);
      return;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> signIn({
    required LoginType loginType,
    required String identifier,
    required String password,
  }) async {
    if (loginType == LoginType.dummyJson) {
      await _userService.signInWithDummyJson(
        username: identifier,
        password: password,
      );
    } else {
      await _userService.signIn(email: identifier, password: password);
    }
    _setSession(await _userService.getUserData(), loginType);
  }

  Future<void> createAccount({
    required String fName,
    required String lName,
    required int age,
    required String contactNo,
    required String username,
    required String emailAddress,
    required String password,
  }) async {
    await _userService.createAccount(
      fName: fName,
      lName: lName,
      age: age,
      contactNo: contactNo,
      username: username,
      email: emailAddress,
      password: password,
    );
    _setSession(await _userService.getUserData(), LoginType.firebase);
  }

  Future<void> refreshUserData() async {
    _user = await _userService.getUserData();
    notifyListeners();
  }

  Future<void> updateUsername(String username) async {
    await _userService.updateUsername(username);
    _user = _user?.copyWith(username: username.trim());
    notifyListeners();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) => _userService.resetPasswordFromCurrentPassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  Future<void> deleteAccount({String? email, String? password}) async {
    await _userService.deleteAccount(email: email, password: password);
    _user = null;
    _loginType = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _userService.signOut();
    _user = null;
    _loginType = null;
    notifyListeners();
  }

  Future<void> _handleFirebaseSession(User? firebaseUser) async {
    if (_userService.loginType == LoginType.dummyJson) return;
    if (firebaseUser == null) {
      _user = null;
      _loginType = null;
    } else {
      try {
        _user = await _userService.getUserData();
        _loginType = LoginType.firebase;
      } catch (_) {
        _user = null;
        _loginType = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  void _setSession(UserModel user, LoginType loginType) {
    _user = user;
    _loginType = loginType;
    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

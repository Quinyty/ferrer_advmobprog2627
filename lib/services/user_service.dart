import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';
import '../models/user_model.dart';

//LAB5 ENHANCEMENT 1,2,3
final ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};
  final firebase.FirebaseAuth firebaseAuth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  LoginType? _loginType;

  LoginType? get loginType => _loginType;
  firebase.User? get currentUser => firebaseAuth.currentUser;
  Stream<firebase.User?> get authStateChanges =>
      firebaseAuth.authStateChanges();
  Stream<firebase.User?> get idTokenChanges => firebaseAuth.idTokenChanges();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLoginType = prefs.getString('loginType');

    if (savedLoginType == LoginType.dummyJson.name &&
        (prefs.getString('accessToken') ?? '').isNotEmpty) {
      _loginType = LoginType.dummyJson;
    } else if (currentUser != null) {
      _loginType = LoginType.firebase;
      await _syncChatDirectoryProfile(currentUser!);
    } else {
      _loginType = null;
    }
  }

  //LAB5 ENHANCEMENT 1: Keep the DummyJSON demo login separate from Firebase Auth.
  Future<Map<String, dynamic>> signInWithDummyJson({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_responseMessage(response.body));
    }

    final userData = jsonDecode(response.body) as Map<String, dynamic>;
    await saveUserData(userData);
    return userData;
  }

  Future<Map<String, dynamic>> loginUser(
    String email,
    String password, {
    bool useFirebase = true,
  }) async {
    if (!useFirebase) {
      data = await signInWithDummyJson(username: email, password: password);
      return data;
    }

    final credential = await signIn(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return a signed-in user.');
    }

    final profile = await getUserData();
    data = {
      'uid': user.uid,
      'id': user.uid,
      'email': user.email ?? email,
      'username': profile.username,
      'firstName': profile.fName,
      'lastName': profile.lName,
      'age': profile.age,
      'contactNo': profile.contactNo,
      'accessToken': profile.accessToken,
      'token': profile.accessToken,
    };
    return data;
  }

  //LAB5 ENHANCEMENT 2: Firebase email/password authentication and account creation.
  Future<firebase.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    _loginType = LoginType.firebase;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', LoginType.firebase.name);
    if (credential.user != null) {
      await _syncChatDirectoryProfile(credential.user!);
    }
    return credential;
  }

  Future<firebase.UserCredential> createAccount({
    required String email,
    required String password,
    String fName = '',
    String lName = '',
    int? age,
    String contactNo = '',
    String username = '',
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Firebase did not return a user.');

    final displayName = username.trim().isNotEmpty
        ? username.trim()
        : '$fName $lName'.trim();
    if (displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
      await user.reload();
    }
    await _saveFirebaseProfile(
      user.uid,
      fName: fName,
      lName: lName,
      age: age,
      contactNo: contactNo,
      username: displayName,
    );
    _loginType = LoginType.firebase;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', LoginType.firebase.name);
    return credential;
  }

  //LAB5 ENHANCEMENT 1: Cache only the DummyJSON demo session, never a password.
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstname', user.firstname);
    await prefs.setString('lastname', user.lastname);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('loginType', LoginType.dummyJson.name);
    _loginType = LoginType.dummyJson;

    //* Support generic token key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  //LAB5 ENHANCEMENT 3: Return the active provider's user profile to the profile screen.
  Future<UserModel> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final activeLoginType =
        _loginType ??
        (prefs.getString('loginType') == LoginType.dummyJson.name
            ? LoginType.dummyJson
            : null);

    if (activeLoginType == LoginType.dummyJson) {
      final data = {
        'id': prefs.getInt('id') ?? 0,
        'username': prefs.getString('username') ?? '',
        'email': prefs.getString('email') ?? '',
        'firstName': prefs.getString('firstname') ?? '',
        'lastName': prefs.getString('lastname') ?? '',
        'gender': prefs.getString('gender') ?? '',
        'image': prefs.getString('image') ?? '',
        'accessToken': prefs.getString('accessToken') ?? '',
        'refreshToken': prefs.getString('refreshToken') ?? '',
      };
      return UserModel.fromDummyJson(data);
    }

    final firebaseUser = currentUser;
    if (firebaseUser == null) {
      throw StateError('No signed-in user was found.');
    }

    final profile = await _readFirebaseProfile(prefs, firebaseUser.uid);
    final token = await firebaseUser.getIdToken();
    _loginType = LoginType.firebase;
    return UserModel.fromFirebase(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username:
          (profile['username'] as String?) ?? firebaseUser.displayName ?? '',
      fName: (profile['fName'] as String?) ?? '',
      lName: (profile['lName'] as String?) ?? '',
      age: profile['age'] as int?,
      contactNo: (profile['contactNo'] as String?) ?? '',
      accessToken: token ?? '',
    );
  }

  Future<Map<String, dynamic>> getDummyJsonData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstname': prefs.getString('firstname') ?? '',
      'lastname': prefs.getString('lastname') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  //* Retrieve User model from SharedPreferences *//
  Future<User> getLoggedInUser() async {
    final user = await getUserData();
    return User(
      id: int.tryParse(user.id) ?? 0,
      username: user.username,
      email: user.email,
      firstname: user.fName,
      lastname: user.lName,
      gender: user.gender,
      image: user.image,
      accessToken: user.accessToken,
      refreshToken: user.refreshToken,
    );
  }

  //LAB5 ENHANCEMENT 1: Firebase owns its auth session; DummyJSON uses its cached token.
  Future<bool> isLoggedIn() async {
    await initialize();
    if (_loginType == LoginType.firebase) return currentUser != null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> refreshIdToken() async {
    final user = currentUser;
    if (user == null) return null;
    return user.getIdToken(true);
  }

  Future<void> updateUsername(String username) async {
    final updatedUsername = username.trim();
    if (updatedUsername.isEmpty) {
      throw ArgumentError('Username cannot be empty.');
    }

    if (_loginType == LoginType.dummyJson) {
      final current = await getDummyJsonData();
      final id = current['id'];
      final response = await http.put(
        Uri.parse('$host/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': updatedUsername}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_responseMessage(response.body));
      }
      await saveUserData({...current, 'username': updatedUsername});
      return;
    }

    final user = currentUser;
    if (user == null) throw StateError('No Firebase user is signed in.');
    await user.updateDisplayName(updatedUsername);
    final prefs = await SharedPreferences.getInstance();
    final profile = await _readFirebaseProfile(prefs, user.uid);
    await _saveFirebaseProfile(
      user.uid,
      fName: (profile['fName'] as String?) ?? '',
      lName: (profile['lName'] as String?) ?? '',
      age: profile['age'] as int?,
      contactNo: (profile['contactNo'] as String?) ?? '',
      username: updatedUsername,
    );
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('A Firebase email account is required.');
    }
    if (newPassword.length < 8) {
      throw ArgumentError('The new password must be at least 8 characters.');
    }

    final credential = firebase.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount({String? email, String? password}) async {
    if (_loginType == LoginType.dummyJson) {
      final userData = await getDummyJsonData();
      final response = await http.delete(
        Uri.parse('$host/users/${userData['id']}'),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_responseMessage(response.body));
      }
      await signOut();
      return;
    }

    final user = currentUser;
    if (user == null) throw StateError('No Firebase user is signed in.');
    if (email != null && password != null) {
      final credential = firebase.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
    await _deleteFirebaseProfile(user.uid);
    await user.delete();
    await signOut();
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'id',
      'username',
      'email',
      'firstname',
      'lastname',
      'gender',
      'image',
      'accessToken',
      'refreshToken',
      'token',
      'loginType',
    ]) {
      await prefs.remove(key);
    }
    _loginType = null;
  }

  Future<void> logout() => signOut();

  Future<void> _saveFirebaseProfile(
    String uid, {
    required String fName,
    required String lName,
    required int? age,
    required String contactNo,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = {
      'uid': uid,
      'fName': fName,
      'lName': lName,
      'age': age,
      'contactNo': contactNo,
      'username': username,
    };
    await prefs.setString('firebaseProfile_$uid', jsonEncode(profile));
    try {
      await firestore
          .collection('users')
          .doc(uid)
          .set(profile, SetOptions(merge: true));
      await firestore.collection('chat_users').doc(uid).set({
        'uid': uid,
        'fName': fName,
        'lName': lName,
        'username': username,
        'emailAddress': firebaseAuth.currentUser?.email ?? '',
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      debugPrint('Could not sync Firebase profile: ${error.message}');
    }
  }

  Future<void> _syncChatDirectoryProfile(firebase.User user) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await _readFirebaseProfile(prefs, user.uid);
    try {
      await firestore.collection('chat_users').doc(user.uid).set({
        'uid': user.uid,
        'fName': profile['fName'] ?? '',
        'lName': profile['lName'] ?? '',
        'username': profile['username'] ?? user.displayName ?? '',
        'emailAddress': user.email ?? '',
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      debugPrint('Could not publish chat profile: ${error.message}');
    }
  }

  Future<Map<String, dynamic>> _readFirebaseProfile(
    SharedPreferences prefs,
    String uid,
  ) async {
    try {
      final snapshot = await firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        final profile = snapshot.data() ?? {};
        await prefs.setString('firebaseProfile_$uid', jsonEncode(profile));
        return profile;
      }
    } on FirebaseException catch (error) {
      debugPrint('Could not load Firebase profile: ${error.message}');
    }

    final json = prefs.getString('firebaseProfile_$uid');
    if (json == null) return {};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> _deleteFirebaseProfile(String uid) async {
    try {
      await Future.wait([
        firestore.collection('users').doc(uid).delete(),
        firestore.collection('chat_users').doc(uid).delete(),
      ]);
    } on FirebaseException catch (error) {
      debugPrint('Could not delete Firebase profile: ${error.message}');
    }
  }

  String _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['message'] ?? decoded['error'] ?? body).toString();
      }
    } catch (_) {
      return body;
    }
    return body;
  }
}

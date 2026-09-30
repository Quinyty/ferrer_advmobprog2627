import 'package:flutter/material.dart';

import '../services/user_service.dart';

// Enhancement 1: Custom splash screen UI with persistent authentication check.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 6500)); // Simulate a loading delay

    if (!mounted) return;

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: userData,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/nuicon.jpeg',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

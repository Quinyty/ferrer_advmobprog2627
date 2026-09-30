import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';

//LAB5 ENHANCEMENT 2: Select DummyJSON demo login or Firebase Authentication.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'emilys');
  final _passwordController = TextEditingController(text: 'emilyspass');
  LoginType _loginType = LoginType.dummyJson;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().signIn(
        loginType: _loginType,
        identifier: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $error')));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
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
                        'Welcome',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SegmentedButton<LoginType>(
                        segments: const [
                          ButtonSegment(
                            value: LoginType.dummyJson,
                            label: Text('DummyJSON'),
                            icon: Icon(Icons.api),
                          ),
                          ButtonSegment(
                            value: LoginType.firebase,
                            label: Text('Firebase'),
                            icon: Icon(Icons.verified_user_outlined),
                          ),
                        ],
                        selected: {_loginType},
                        onSelectionChanged: _isLoading
                            ? null
                            : (selection) {
                                setState(() {
                                  _loginType = selection.first;
                                  _usernameController.clear();
                                  _passwordController.clear();
                                });
                              },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: _loginType == LoginType.firebase
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: _loginType == LoginType.firebase
                              ? 'Email address'
                              : 'Username',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            _loginType == LoginType.firebase
                                ? Icons.email_outlined
                                : Icons.person,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _loginType == LoginType.firebase
                                ? 'Please enter your email address.'
                                : 'Please enter your username.';
                          }
                          if (_loginType == LoginType.firebase &&
                              !value.trim().contains('@')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B4BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_loginType == LoginType.firebase) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushNamed(context, '/signup'),
                          child: const Text('Create a Firebase account'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/nuicon.jpeg',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        const Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

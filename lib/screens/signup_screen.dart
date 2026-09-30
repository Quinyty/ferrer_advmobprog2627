import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

//LAB5 ENHANCEMENT 2: Firebase signup collects and validates the requested profile fields.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().createAccount(
        fName: _fNameController.text.trim(),
        lName: _lNameController.text.trim(),
        age: int.parse(_ageController.text),
        contactNo: _contactNoController.text.trim(),
        username: _usernameController.text.trim(),
        emailAddress: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account creation failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter your $label.' : null;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _fNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _required(value, 'first name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _required(value, 'last name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 1 || age > 120) {
                    return 'Enter an age from 1 to 120.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactNoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _required(value, 'contact number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final error = _required(value, 'username');
                  if (error != null) return error;
                  if (value!.trim().length < 3) {
                    return 'Username must be at least 3 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@')) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters.';
                  }
                  if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                      !RegExp(r'\d').hasMatch(value)) {
                    return 'Include at least one letter and one number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showPassword,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != _passwordController.text
                    ? 'Passwords do not match.'
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isLoading ? null : _createAccount,
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

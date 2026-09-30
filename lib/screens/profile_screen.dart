import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';

//LAB5 ENHANCEMENT 3: Display provider-specific user data and account actions.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isWorking = false;

  Future<UserModel> _loadUser() {
    return _userService.getUserData();
  }

  Future<void> _updateUsername(UserModel user) async {
    final controller = TextEditingController(text: user.username);
    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (username == null || username.length < 3 || !mounted) return;
    await _runAction(
      () => context.read<AuthProvider>().updateUsername(username),
      'Username updated.',
    );
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final passwords = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, (current.text, next.text)),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    if (passwords == null || !mounted) return;
    await _runAction(
      () => context.read<AuthProvider>().resetPasswordFromCurrentPassword(
        currentPassword: passwords.$1,
        newPassword: passwords.$2,
      ),
      'Password updated.',
    );
  }

  Future<void> _deleteAccount(UserModel user) async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action cannot be undone.'),
            if (user.loginType == LoginType.firebase) ...[
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      password.dispose();
      return;
    }
    if (user.loginType == LoginType.firebase && password.text.isEmpty) {
      password.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your current password.')),
      );
      return;
    }

    setState(() => _isWorking = true);
    try {
      await context.read<AuthProvider>().deleteAccount(
        email: user.loginType == LoginType.firebase ? user.email : null,
        password: user.loginType == LoginType.firebase ? password.text : null,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete account: $error')),
        );
      }
    } finally {
      password.dispose();
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isWorking = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: _loadUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('No saved user found.'));
        }

        final user = snapshot.data!;
        final isFirebase = user.loginType == LoginType.firebase;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 3,
                margin: EdgeInsets.zero,
                shadowColor: Colors.deepPurple.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage: user.image.isNotEmpty
                            ? NetworkImage(user.image)
                            : null,
                        child: user.image.isEmpty
                            ? Text(
                                user.fName.isNotEmpty
                                    ? user.fName[0]
                                    : user.username.isNotEmpty
                                    ? user.username[0]
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        user.fullName.isEmpty ? user.username : user.fullName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _profileInfoRow(
                        Icons.verified_user_outlined,
                        'Login type',
                        isFirebase ? 'Firebase Auth' : 'DummyJSON',
                      ),
                      const SizedBox(height: 8),
                      _profileInfoRow(
                        Icons.email_outlined,
                        'Email',
                        user.email,
                      ),
                      if (user.age != null) ...[
                        const SizedBox(height: 8),
                        _profileInfoRow(
                          Icons.cake_outlined,
                          'Age',
                          '${user.age}',
                        ),
                      ],
                      if (user.contactNo.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _profileInfoRow(
                          Icons.phone_outlined,
                          'Contact number',
                          user.contactNo,
                        ),
                      ],
                      if (!isFirebase && user.gender.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _profileInfoRow(
                          Icons.transgender_outlined,
                          'Gender',
                          user.gender,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _profileInfoRow(
                        Icons.confirmation_number_outlined,
                        'User ID',
                        user.id,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isWorking ? null : () => _updateUsername(user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update username'),
                ),
              ),
              if (isFirebase)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isWorking ? null : _changePassword,
                    icon: const Icon(Icons.lock_reset_outlined),
                    label: const Text('Change password'),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isWorking ? null : () => _deleteAccount(user),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete account'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isWorking
                      ? null
                      : () async {
                          if (!mounted) return;

                          final navigator = Navigator.of(context);
                          await context.read<AuthProvider>().signOut();

                          if (!mounted) return;

                          navigator.pushNamedAndRemoveUntil(
                            '/signin',
                            (route) => false,
                          );
                        },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A59),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.deepPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

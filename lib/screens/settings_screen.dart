import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

//LAB5 ENHANCEMENT 1: Log out clears the active session and returns to sign-in.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Enhancement 3: Add settings page to move the dark/light mode switch.
          SwitchListTile(
            title: Text(themeProvider.isDark ? 'Dark Mode' : 'Light Mode'),
            subtitle: Text(
              themeProvider.isDark
                  ? 'Dark mode is enabled'
                  : 'Light mode is enabled',
            ),
            value: themeProvider.isDark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              try {
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signin',
                  (_) => false,
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not log out: $error')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

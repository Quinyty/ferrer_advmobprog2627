import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/user_service.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(userService: userService.value),
        ),
      ],
      child: const RoblesAdvMobProg(),
    ),
  );
}

class RoblesAdvMobProg extends StatelessWidget {
  const RoblesAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Commerce App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/chat': (context) => Scaffold(
          appBar: AppBar(title: const Text('Chats')),
          body: const ChatScreen(),
        ),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(username: ''),
      },
    );
  }
}

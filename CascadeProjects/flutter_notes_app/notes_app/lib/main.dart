import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/notes_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'services/database_helper.dart';
import 'secrets.dart';

String get geminiApiKey {
  // Try to get from .env file first
  final envKey = dotenv.env['GEMINI_API_KEY'];
  if (envKey != null && envKey.isNotEmpty) {
    return envKey.trim();
  }
  // Fallback to compile-time environment variable
  final compileTimeKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (compileTimeKey.isNotEmpty) {
    return compileTimeKey;
  }
  // Final fallback to secrets.dart
  return GEMINI_API_KEY;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    debugPrint('You can still use compile-time environment variables.');
  }
  
  await DatabaseHelper.instance.init(); // DB ready
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotesProvider()..loadNotes(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Notes App',
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const AuthGate(),    // <-- Changed here
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: DatabaseHelper.instance.getAnyUser(),  // checks if a user exists
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // First-time user → go to Signup
        if (!snapshot.hasData || snapshot.data == null) {
          return const SignUpScreen();
        }

        // User exists → go to Login
        return const LoginScreen();
      },
    );
  }
}

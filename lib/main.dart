import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'storage/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local Hive database
  await DatabaseService().init();

  runApp(const TournamentOrganizerApp());
}

class TournamentOrganizerApp extends StatelessWidget {
  const TournamentOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const deepDarkBackground = Color(0xFF0B0C10); // Deep Obsidian Background
    const orangeAccent = Color(0xFFFF8C00); // Deep premium orange accent
    const brightOrange = Color(0xFFFFA500); // Secondary bright orange
    const darkGrayCard = Color(0xFF1F2833); // Slate metallic card color

    return MaterialApp(
      title: 'Tournament Organizer',
      debugShowCheckedModeBanner: false,

      themeMode: ThemeMode.dark,

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeAccent,
          brightness: Brightness.dark,
          primary: orangeAccent,
          secondary: brightOrange,
          surface: deepDarkBackground,
          surfaceContainerLow: darkGrayCard,
          surfaceContainerHighest: const Color(0xFF2E3A4D),
        ),
        scaffoldBackgroundColor: deepDarkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: deepDarkBackground,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: orangeAccent),
        ),
        cardTheme: CardThemeData(
          color: darkGrayCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withAlpha((255 * 0.05).toInt()),
              width: 1.0,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkGrayCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withAlpha((255 * 0.08).toInt()),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withAlpha((255 * 0.08).toInt()),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: orangeAccent, width: 2.0),
          ),
          labelStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orangeAccent,
            foregroundColor: deepDarkBackground,
            shadowColor: Colors.black.withAlpha((255 * 0.2).toInt()),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeAccent,
          brightness: Brightness.light,
        ),
      ),

      home: const SplashScreen(),
    );
  }
}

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
    const deepDarkBackground = Color(0xFF0A1210); // Deep Emerald Grey Background
    const greenAccent = Color(0xFF00CC66); // Viridian Accent Green
    const mintHighlight = Color(0xFFCCFFDD); // Mint highlight
    const darkGrayCard = Color(0xFF121E1B); // Green-tinted dark gray card

    return MaterialApp(
      title: 'Tournament Organizer',
      debugShowCheckedModeBanner: false,

      themeMode: ThemeMode.dark,

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: greenAccent,
          brightness: Brightness.dark,
          primary: greenAccent,
          secondary: mintHighlight,
          surface: deepDarkBackground,
          surfaceContainerLow: darkGrayCard,
          surfaceContainerHighest: const Color(0xFF1B2F2A),
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
          iconTheme: IconThemeData(color: greenAccent),
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
            borderSide: const BorderSide(color: greenAccent, width: 2.0),
          ),
          labelStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: greenAccent,
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
          seedColor: greenAccent,
          brightness: Brightness.light,
        ),
      ),

      home: const SplashScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
//import 'package:google_fonts/google_fonts.dart';

import 'core/supabase_client.dart';
import 'providers/game_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/category_selection_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_screen.dart';
import 'screens/result_screen.dart';
import 'screens/multiplayer_result_screen.dart';
import 'screens/multiplayer_lobby_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/user_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/rendering.dart'; // import required for RendererBinding

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  await UserPreferences.init();

  try {
    await SupabaseClientWrapper.initialize();
    debugPrint("DEBUG: Supabase initialized successfully");
  } catch (e) {
    debugPrint("CRITICAL ERROR: Supabase initialization failed: $e");
    // Prevent app from crashing immediately, maybe show error UI if possible,
    // but for now just log it so we see it in terminal.
  }

  // بنشغل الرادار قبل ما اللعبة تفتح
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://8381411a89eaa73fa1144023ecfdf4df@o4511010013118465.ingest.de.sentry.io/4511010015215696'; // الصق الـ DSN هنا
      // نسبة تتبع الأخطاء (1.0 يعني 100%)
      options.tracesSampleRate = 1.0;
    },
    // بنخلي Sentry هو اللي يشغل اللعبة
    appRunner: () {
      WidgetsFlutterBinding.ensureInitialized();
      RendererBinding.instance.ensureSemantics();
      runApp(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => GameProvider())],
          child: const MyApp(),
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = UserPreferences.language ?? 'ar'; // Default to Arabic

    return MaterialApp(
      title: 'Culture Challenge',
      debugShowCheckedModeBanner: false,
      locale: Locale(languageCode),
      supportedLocales: const [Locale('en', ''), Locale('ar', '')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ).copyWith(secondary: const Color(0xFFFF6584)),
        /*textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),*/
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            //textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D44),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/multiplayer_lobby': (context) => const MultiplayerLobbyScreen(),
        '/category': (context) => const CategorySelectionScreen(),
        '/lobby': (context) => const LobbyScreen(),
        '/game': (context) => const GameScreen(),
        '/result': (context) => const ResultScreen(),
        '/multiplayer_result': (context) => const MultiplayerResultScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}

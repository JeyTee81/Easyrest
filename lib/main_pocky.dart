import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/pocky_splash_screen.dart';
import 'screens/remote_setup_screen.dart';
import 'screens/connection_test_screen.dart';
import 'screens/pocky_orders_screen.dart';
import 'services/remote_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lancer l'application immédiatement avec le splash screen
  runApp(const EasyRestPockyApp());
}

class EasyRestPockyApp extends StatelessWidget {
  const EasyRestPockyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyRest Pocky',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        primaryColor: const Color(0xFFbfa14a),
        scaffoldBackgroundColor: const Color(0xFF231f2b),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF231f2b),
          foregroundColor: Color(0xFFbfa14a),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFbfa14a),
            foregroundColor: const Color(0xFF231f2b),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFbfa14a),
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      home: const PockySplashScreen(),
      routes: {
        '/setup': (context) => const RemoteSetupScreen(),
        '/test': (context) => const ConnectionTestScreen(),
        '/orders': (context) => const PockyOrdersScreen(),
      },
    );
  }
}

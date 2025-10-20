import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:window_manager/window_manager.dart'; // Temporairement commenté
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lancer l'application immédiatement avec le splash screen
  runApp(const EasyRestApp());
}

class EasyRestApp extends StatelessWidget {
  const EasyRestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyRest',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF231f2b),
        scaffoldBackgroundColor: const Color(0xFF231f2b),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFbfa14a),
          secondary: const Color(0xFFe7c68e),
          surface: const Color(0xFF231f2b),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF231f2b)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFfff8e1),
          border: OutlineInputBorder(),
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      home: const SplashScreen(),
    );
  }
}

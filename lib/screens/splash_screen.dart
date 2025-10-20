import 'package:flutter/material.dart';
import 'dart:async';
import '../services/postgresql_service.dart';
import '../services/api_service.dart';
import '../services/company_service.dart';
import '../services/touch_screen_service.dart';
import '../services/remote_server_service.dart';
import '../config/database_config.dart';
import 'company_setup_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  
  double _progress = 0.0;
  String _statusText = 'Initialisation...';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Animation pour la barre de progression
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Animation pour le logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Démarrer les animations
    _logoController.forward();
    _startInitialization();
  }

  void _startInitialization() async {
    // Démarrer la barre de progression
    _progressController.forward();
    
    // Initialisation des services avec progression
    await _initializeWithProgress();
    
    // Attendre que l'animation soit terminée
    await _progressController.forward();
    
    // Navigation vers l'écran approprié
    _navigateToNextScreen();
  }

  Future<void> _initializeWithProgress() async {
    final steps = [
      {'text': 'Chargement de la configuration...', 'duration': 0.2},
      {'text': 'Initialisation du service tactile...', 'duration': 0.15},
      {'text': 'Connexion à la base de données...', 'duration': 0.3},
      {'text': 'Test de la connexion API...', 'duration': 0.2},
      {'text': 'Démarrage du serveur distant...', 'duration': 0.15},
    ];

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      
      // Mettre à jour le texte de statut
      setState(() {
        _statusText = step['text'] as String;
      });

      // Exécuter l'étape correspondante
      await _executeStep(i);
      
      // Mettre à jour la progression
      setState(() {
        _progress = (i + 1) / steps.length;
      });

      // Attendre la durée spécifiée
      await Future.delayed(Duration(milliseconds: ((step['duration'] as double) * 1000).round()));
    }
  }

  Future<void> _executeStep(int stepIndex) async {
    try {
      switch (stepIndex) {
        case 0: // Configuration
          await DatabaseConfig.loadConfig();
          break;
        case 1: // Service tactile
          await TouchScreenService.initialize();
          break;
        case 2: // PostgreSQL
          await PostgreSQLService.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('PostgreSQL initialization timeout');
            },
          );
          break;
        case 3: // API
          await ApiService.testConnection().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('API connection timeout');
              return false;
            },
          );
          break;
        case 4: // Serveur distant
          await RemoteServerService().autoStartIfEnabled();
          break;
      }
    } catch (e) {
      debugPrint('Erreur à l\'étape $stepIndex: $e');
      // Continuer même en cas d'erreur
    }
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;
    
    setState(() {
      _isInitialized = true;
    });

    // Vérifier si c'est le premier lancement
    try {
      final companyService = CompanyService();
      final isFirstLaunch = await companyService.isFirstLaunch();
      
      if (mounted) {
        if (isFirstLaunch) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CompanySetupScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification du premier lancement: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompanySetupScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec animation
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Opacity(
                    opacity: _logoAnimation.value,
                    child: const Image(
                      image: AssetImage('assets/logo.png'),
                      height: 200,
                      width: 200,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // Titre de l'application
            const Text(
              'EasyRest',
              style: TextStyle(
                color: Color(0xFFbfa14a),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Système de gestion de restaurant',
              style: TextStyle(
                color: Color(0xFFe7c68e),
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Barre de progression
            Container(
              width: 300,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF3a3a3a),
                borderRadius: BorderRadius.circular(3),
              ),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFbfa14a),
                            Color(0xFFe7c68e),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Texte de statut
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusText,
                key: ValueKey(_statusText),
                style: const TextStyle(
                  color: Color(0xFFbfa14a),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Pourcentage de progression
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFe7c68e),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Écran de connexion simplifié pour la navigation
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _isManager = false;
  bool _isSuperUser = false;

  // PINs and roles
  final Map<String, Map<String, dynamic>> _pins = {
    '1234': {'isManager': false, 'isSuperUser': false, 'name': 'Employé'},
    '0000': {'isManager': true, 'isSuperUser': false, 'name': 'Manager'},
    '9999': {'isManager': true, 'isSuperUser': true, 'name': 'Super Utilisateur'},
  };

  void _login() {
    final pin = _pinController.text.trim();
    if (_pins.containsKey(pin)) {
      final userData = _pins[pin]!;
      setState(() {
        _isManager = userData['isManager'];
        _isSuperUser = userData['isSuperUser'];
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            isManager: _isManager,
            isSuperUser: _isSuperUser,
            staffName: userData['name'],
          ),
        ),
      );
    } else {
      setState(() {
        _error = "Code PIN incorrect";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFfff8e1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Image(
                image: AssetImage('assets/logo.png'),
                height: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                "Bienvenue sur EasyRest",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFbfa14a),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Code PIN',
                  errorText: _error,
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFbfa14a),
                  foregroundColor: const Color(0xFF231f2b),
                ),
                child: const Text('Connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

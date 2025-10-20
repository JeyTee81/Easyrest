import 'package:flutter/material.dart';
import 'dart:async';
import '../services/remote_data_service.dart';
import 'remote_setup_screen.dart';
import 'connection_test_screen.dart';

class PockySplashScreen extends StatefulWidget {
  const PockySplashScreen({super.key});

  @override
  State<PockySplashScreen> createState() => _PockySplashScreenState();
}

class _PockySplashScreenState extends State<PockySplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _logoController;
  late Animation<double> _progressAnimation;
  late Animation<double> _logoAnimation;

  final List<String> _steps = [
    'Initialisation...',
    'Vérification de la connexion...',
    'Chargement des données...',
    'Préparation de l\'interface...',
    'Terminé !',
  ];

  int _currentStep = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _startInitialization();
  }

  void _startInitialization() async {
    _logoController.forward();
    
    for (int i = 0; i < _steps.length; i++) {
      setState(() {
        _currentStep = i;
      });
      
      await _executeStep(i);
      _progressController.animateTo((i + 1) / _steps.length);
      
      // Pause entre les étapes
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _navigateToNextScreen();
  }

  Future<void> _executeStep(int stepIndex) async {
    try {
      switch (stepIndex) {
        case 0: // Initialisation
          debugPrint('Initialisation du service de données...');
          break;
        case 1: // Vérification de la connexion
          debugPrint('Vérification de la connexion...');
          final remoteDataService = RemoteDataService();
          await remoteDataService.initialize();
          break;
        case 2: // Chargement des données
          debugPrint('Chargement des données...');
          break;
        case 3: // Préparation de l'interface
          debugPrint('Préparation de l\'interface...');
          break;
        case 4: // Terminé
          debugPrint('Initialisation terminée');
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

    // Pour easyrest_pocky, vérifier la connexion au serveur distant
    try {
      final remoteDataService = RemoteDataService();
      await remoteDataService.initialize();
      
      if (mounted) {
        if (!remoteDataService.isConnected) {
          // Pas connecté, aller à l'écran de configuration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RemoteSetupScreen()),
          );
        } else {
          // Connecté, aller à l'écran de test pour vérifier
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ConnectionTestScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la connexion: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RemoteSetupScreen()),
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
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: const Image(
                      image: AssetImage('assets/logo.png'),
                      height: 100,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "EasyRest Pocky",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFbfa14a),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Contrôleur distant",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF231f2b),
                ),
              ),
              const SizedBox(height: 32),
              
              // Barre de progression
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: const Color(0xFF231f2b).withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFbfa14a)),
                    minHeight: 8,
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Étape actuelle
              Text(
                _steps[_currentStep],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF231f2b),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}





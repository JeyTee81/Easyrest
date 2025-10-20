import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TouchScreenService {
  static bool _isTouchScreen = false;
  static bool _isInitialized = false;

  /// Initialise le service de détection d'écran tactile
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Pour Windows, on peut détecter si l'écran supporte le tactile
    // Pour l'instant, on assume que c'est un écran tactile si on est sur Windows
    _isTouchScreen = defaultTargetPlatform == TargetPlatform.windows;
    _isInitialized = true;
  }

  /// Vérifie si l'écran supporte le tactile
  static bool get isTouchScreen => _isTouchScreen;

  /// Obtient la taille optimale des boutons selon le type d'écran
  static double get optimalButtonSize {
    return _isTouchScreen ? 48.0 : 40.0;
  }

  /// Obtient la taille optimale des icônes selon le type d'écran
  static double get optimalIconSize {
    return _isTouchScreen ? 28.0 : 24.0;
  }

  /// Obtient la taille optimale de la police selon le type d'écran
  static double get optimalFontSize {
    return _isTouchScreen ? 14.0 : 12.0;
  }

  /// Obtient l'espacement optimal selon le type d'écran
  static double get optimalSpacing {
    return _isTouchScreen ? 16.0 : 12.0;
  }

  /// Obtient le padding optimal selon le type d'écran
  static EdgeInsets get optimalPadding {
    return _isTouchScreen 
        ? const EdgeInsets.all(16.0) 
        : const EdgeInsets.all(12.0);
  }

  /// Obtient les contraintes optimales pour les boutons
  static BoxConstraints get optimalButtonConstraints {
    return BoxConstraints(
      minWidth: optimalButtonSize,
      minHeight: optimalButtonSize,
    );
  }

  /// Obtient le style de texte optimal
  static TextStyle get optimalTextStyle {
    return TextStyle(
      fontSize: optimalFontSize,
      fontWeight: FontWeight.w500,
    );
  }

  /// Obtient le style de titre optimal
  static TextStyle get optimalTitleStyle {
    return TextStyle(
      fontSize: optimalFontSize + 4,
      fontWeight: FontWeight.bold,
    );
  }

  /// Obtient le style de sous-titre optimal
  static TextStyle get optimalSubtitleStyle {
    return TextStyle(
      fontSize: optimalFontSize - 2,
      fontWeight: FontWeight.normal,
    );
  }

  /// Obtient la hauteur optimale pour les éléments de liste
  static double get optimalListTileHeight {
    return _isTouchScreen ? 72.0 : 56.0;
  }

  /// Obtient le ratio d'aspect optimal pour les grilles
  static double get optimalGridAspectRatio {
    return _isTouchScreen ? 0.9 : 1.0;
  }

  /// Obtient le nombre de colonnes optimal pour les grilles
  static int get optimalGridColumns {
    return _isTouchScreen ? 3 : 4;
  }

  /// Obtient la largeur maximale optimale pour le contenu
  static double get optimalMaxWidth {
    return _isTouchScreen ? 1000.0 : 1200.0;
  }
}










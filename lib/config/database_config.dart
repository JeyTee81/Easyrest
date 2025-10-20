import 'dart:io';

class DatabaseConfig {
  // Configuration par défaut pour PostgreSQL local
  static const String defaultHost = 'localhost';
  static const int defaultPort = 5432;
  static const String defaultDatabase = 'easyrest';
  static const String defaultUsername = 'postgres';
  static const String defaultPassword = 'easyrest_admin';
  
  // Configuration actuelle
  static String host = defaultHost;
  static int port = defaultPort;
  static String database = defaultDatabase;
  static String username = defaultUsername;
  static String password = defaultPassword;
  
  // Restaurant ID pour l'identification
  static String? restaurantId;
  static String? restaurantName;
  
  /// Initialise la configuration depuis les préférences partagées
  static Future<void> loadConfig() async {
    // TODO: Charger depuis SharedPreferences ou fichier de config
    // Pour l'instant, utiliser les valeurs par défaut
  }
  
  /// Sauvegarde la configuration
  static Future<void> saveConfig() async {
    // TODO: Sauvegarder dans SharedPreferences ou fichier de config
  }
  
  /// Teste la connexion à la base de données
  static Future<bool> testConnection() async {
    try {
      // TODO: Implémenter le test de connexion
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Génère une configuration par défaut pour un nouveau restaurant
  static void generateDefaultConfig(String restaurantName) {
    DatabaseConfig.restaurantName = restaurantName;
    DatabaseConfig.restaurantId = _generateRestaurantId();
    DatabaseConfig.database = 'easyrest_${DatabaseConfig.restaurantId}';
  }
  
  /// Génère un ID unique pour le restaurant
  static String _generateRestaurantId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'rest_$random';
  }
  
  /// Retourne l'URL de connexion PostgreSQL
  static String get connectionString {
    return 'postgresql://$username:$password@$host:$port/$database';
  }
  
  /// Retourne les paramètres de connexion
  static Map<String, dynamic> get connectionParams {
    return {
      'host': host,
      'port': port,
      'database': database,
      'username': username,
      'password': password,
    };
  }
}

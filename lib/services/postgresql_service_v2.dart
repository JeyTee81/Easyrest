import 'package:postgres/postgres.dart';
import '../config/database_config.dart';
import '../models/staff.dart';
import '../models/menu_item.dart';
import '../models/product.dart';
import '../models/table_restaurant.dart';
import '../models/order.dart';
import '../models/bill.dart';
import '../models/printer.dart';
import '../models/order_item.dart';
import '../models/cash_register_closing.dart';
import '../models/cash_register_opening.dart';
import '../models/room.dart';

class PostgreSQLServiceV2 {
  static Connection? _connection;
  static String? lastError;
  
  /// Initialise la connexion à PostgreSQL
  static Future<void> initialize() async {
    try {
      final config = DatabaseConfig.connectionParams;
      print('Configuration PostgreSQL:');
      print('  Hôte: ${config['host']}');
      print('  Port: ${config['port']}');
      print('  Base: ${config['database']}');
      print('  Utilisateur: ${config['username']}');
      
      print('Tentative de connexion...');
      _connection = await Connection.open(
        Endpoint(
          host: config['host'],
          port: config['port'],
          database: config['database'],
          username: config['username'],
          password: config['password'],
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
      
      print('✅ Connexion PostgreSQL réussie !');
      lastError = null;
    } catch (e) {
      lastError = 'Failed to connect to PostgreSQL: $e';
      print('❌ Erreur de connexion: $e');
      throw Exception(lastError);
    }
  }
  
  /// Ferme la connexion
  static Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }
  
  /// Vérifie si la connexion est active
  static bool get isConnected => _connection != null;
  
  /// Exécute une requête SELECT
  static Future<List<Map<String, dynamic>>> _select(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database not connected');
    }
    
    try {
      print('Exécution requête: $query');
      final results = await _connection!.execute(Sql.named(query), parameters: parameters ?? []);
      print('Résultats: ${results.length} lignes');
      return results.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      lastError = 'Query failed: $e';
      print('❌ Erreur requête: $e');
      throw Exception(lastError);
    }
  }
  
  /// Exécute une requête INSERT/UPDATE/DELETE
  static Future<int> _execute(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database not connected');
    }
    
    try {
      print('Exécution requête: $query');
      final results = await _connection!.execute(Sql.named(query), parameters: parameters ?? []);
      print('Lignes affectées: ${results.affectedRows}');
      return results.affectedRows;
    } catch (e) {
      lastError = 'Query failed: $e';
      print('❌ Erreur requête: $e');
      throw Exception(lastError);
    }
  }
  
  /// Exécute une requête INSERT et retourne l'ID généré
  static Future<int> _insertAndGetId(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database not connected');
    }
    
    try {
      print('Exécution requête: $query');
      final results = await _connection!.execute(Sql.named(query), parameters: parameters ?? []);
      if (results.isNotEmpty) {
        final id = results.first[0] as int;
        print('ID généré: $id');
        return id;
      }
      throw Exception('No ID returned from insert');
    } catch (e) {
      lastError = 'Insert failed: $e';
      print('❌ Erreur insert: $e');
      throw Exception(lastError);
    }
  }
  
  // ==================== STAFF OPERATIONS ====================
  
  static Future<List<Staff>> getStaff() async {
    try {
      final results = await _select('SELECT * FROM staff ORDER BY name');
      return results.map((data) => Staff.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get staff: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertStaff(Staff staff) async {
    try {
      final query = '''
        INSERT INTO staff (name, pin, role, is_active)
        VALUES (@name, @pin, @role, @is_active)
        RETURNING id
      ''';
      final id = await _insertAndGetId(query, [
        staff.name,
        staff.pin,
        staff.role,
        staff.isActive,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert staff: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateStaff(Staff staff) async {
    try {
      final query = '''
        UPDATE staff 
        SET name = @name, pin = @pin, role = @role, is_active = @is_active
        WHERE id = @id
      ''';
      await _execute(query, [
        staff.name,
        staff.pin,
        staff.role,
        staff.isActive,
        staff.id,
      ]);
      return staff.id!;
    } catch (e) {
      lastError = 'Failed to update staff: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteStaff(int id) async {
    try {
      await _execute('DELETE FROM staff WHERE id = @id', [id]);
    } catch (e) {
      lastError = 'Failed to delete staff: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== MENU ITEMS OPERATIONS ====================
  
  static Future<List<MenuItem>> getMenuItems() async {
    try {
      final results = await _select('SELECT * FROM menu_items ORDER BY name');
      return results.map((data) => MenuItem.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get menu items: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertMenuItem(MenuItem item) async {
    try {
      final query = '''
        INSERT INTO menu_items (name, price_ht, price_ttc, tva_rate, description, category, type, printer_id, is_available, is_preset_menu)
        VALUES (@name, @price_ht, @price_ttc, @tva_rate, @description, @category, @type, @printer_id, @is_available, @is_preset_menu)
        RETURNING id
      ''';
      final id = await _insertAndGetId(query, [
        item.name,
        item.priceHt,
        item.priceTtc,
        item.tvaRate,
        item.description,
        item.category,
        item.type,
        item.printerId,
        item.isAvailable,
        item.isPresetMenu,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert menu item: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateMenuItem(MenuItem item) async {
    try {
      final query = '''
        UPDATE menu_items 
        SET name = @name, price_ht = @price_ht, price_ttc = @price_ttc, tva_rate = @tva_rate, 
            description = @description, category = @category, type = @type, printer_id = @printer_id, 
            is_available = @is_available, is_preset_menu = @is_preset_menu
        WHERE id = @id
      ''';
      await _execute(query, [
        item.name,
        item.priceHt,
        item.priceTtc,
        item.tvaRate,
        item.description,
        item.category,
        item.type,
        item.printerId,
        item.isAvailable,
        item.isPresetMenu,
        item.id,
      ]);
      return item.id!;
    } catch (e) {
      lastError = 'Failed to update menu item: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteMenuItem(int id) async {
    try {
      await _execute('DELETE FROM menu_items WHERE id = @id', [id]);
    } catch (e) {
      lastError = 'Failed to delete menu item: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== UTILITY METHODS ====================
  
  static String? getLastError() => lastError;
  
  static Future<void> clearError() async {
    lastError = null;
  }
  
  /// Teste la connexion à la base de données
  static Future<bool> testConnection() async {
    try {
      if (_connection == null) {
        await initialize();
      }
      await _select('SELECT 1');
      return true;
    } catch (e) {
      print('❌ Test de connexion échoué: $e');
      return false;
    }
  }
}

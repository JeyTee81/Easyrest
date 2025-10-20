import 'postgresql_service.dart';
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

/// Service de compatibilité qui utilise PostgreSQL en arrière-plan
/// Remplace l'ancien service de base de données
class DatabaseService {
  // ==================== STAFF OPERATIONS ====================
  
  static Future<List<Staff>> getStaff() async {
    return await PostgreSQLService.getStaff();
  }
  
  static Future<int> insertStaff(Staff staff) async {
    return await PostgreSQLService.insertStaff(staff);
  }
  
  static Future<int> updateStaff(Staff staff) async {
    return await PostgreSQLService.updateStaff(staff);
  }
  
  static Future<void> deleteStaff(int id) async {
    return await PostgreSQLService.deleteStaff(id);
  }
  
  // ==================== MENU ITEMS OPERATIONS ====================
  
  static Future<List<MenuItem>> getMenuItems() async {
    return await PostgreSQLService.getMenuItems();
  }
  
  static Future<int> insertMenuItem(MenuItem item) async {
    return await PostgreSQLService.insertMenuItem(item);
  }
  
  static Future<int> updateMenuItem(MenuItem item) async {
    return await PostgreSQLService.updateMenuItem(item);
  }
  
  static Future<void> deleteMenuItem(int id) async {
    return await PostgreSQLService.deleteMenuItem(id);
  }
  
  // ==================== PRODUCTS OPERATIONS ====================
  
  static Future<List<Product>> getProducts() async {
    return await PostgreSQLService.getProducts();
  }
  
  static Future<int> insertProduct(Product product) async {
    return await PostgreSQLService.insertProduct(product);
  }
  
  static Future<int> updateProduct(Product product) async {
    return await PostgreSQLService.updateProduct(product);
  }
  
  static Future<void> deleteProduct(int id) async {
    return await PostgreSQLService.deleteProduct(id);
  }
  
  // ==================== TABLES OPERATIONS ====================
  
  static Future<List<TableRestaurant>> getTables() async {
    return await PostgreSQLService.getTables();
  }
  
  static Future<int> insertTable(TableRestaurant table) async {
    return await PostgreSQLService.insertTable(table);
  }
  
  static Future<int> updateTable(TableRestaurant table) async {
    return await PostgreSQLService.updateTable(table);
  }
  
  static Future<void> deleteTable(int id) async {
    return await PostgreSQLService.deleteTable(id);
  }
  
  // ==================== PRINTERS OPERATIONS ====================
  
  static Future<List<Printer>> getPrinters() async {
    return await PostgreSQLService.getPrinters();
  }
  
  static Future<int> insertPrinter(Printer printer) async {
    return await PostgreSQLService.insertPrinter(printer);
  }
  
  static Future<int> updatePrinter(Printer printer) async {
    return await PostgreSQLService.updatePrinter(printer);
  }
  
  static Future<void> deletePrinter(int id) async {
    return await PostgreSQLService.deletePrinter(id);
  }
  
  // ==================== UTILITY METHODS ====================
  
  static String? getLastError() => PostgreSQLService.getLastError();
  
  static Future<void> clearError() async {
    return await PostgreSQLService.clearError();
  }
  
  static Future<bool> testConnection() async {
    return await PostgreSQLService.testConnection();
  }
  
  // ==================== COMPATIBILITY METHODS ====================
  
  /// Méthodes de compatibilité pour l'ancien système
  static Future<String> getDatabasePath() async {
    return 'PostgreSQL Database';
  }
  
  static Future<String> getExternalStoragePath() async {
    return 'PostgreSQL Database';
  }
  
  static Future<String> getEasyRestDirectoryPath() async {
    return 'PostgreSQL Database';
  }
  
  static dynamic get database => null;
  
  static Future<void> resetDatabase() async {
    // Pour PostgreSQL, on ne peut pas facilement "reset" la base
    // Cette méthode est gardée pour la compatibilité
    throw UnimplementedError('Database reset not supported with PostgreSQL');
  }
}

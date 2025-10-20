import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/database_config.dart';
import '../models/staff.dart';
import '../models/menu_item.dart';
import '../models/product.dart';
import '../models/table_restaurant.dart';
import '../models/printer.dart';

class ApiService {
  static String? lastError;
  
  /// Base URL de l'API REST
  static String get baseUrl => 'http://${DatabaseConfig.host}:${DatabaseConfig.port + 1000}';
  
  /// Headers par défaut
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Exécute une requête GET
  static Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      lastError = 'GET request failed: $e';
      throw Exception(lastError);
    }
  }
  
  /// Exécute une requête POST
  static Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      lastError = 'POST request failed: $e';
      throw Exception(lastError);
    }
  }
  
  /// Exécute une requête PUT
  static Future<Map<String, dynamic>> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      lastError = 'PUT request failed: $e';
      throw Exception(lastError);
    }
  }
  
  /// Exécute une requête DELETE
  static Future<void> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      lastError = 'DELETE request failed: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== STAFF OPERATIONS ====================
  
  static Future<List<Staff>> getStaff() async {
    try {
      final response = await _get('/api/staff');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => Staff.fromMap(item)).toList();
    } catch (e) {
      lastError = 'Failed to get staff: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertStaff(Staff staff) async {
    try {
      final response = await _post('/api/staff', staff.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to insert staff: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateStaff(Staff staff) async {
    try {
      final response = await _put('/api/staff/${staff.id}', staff.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to update staff: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteStaff(int id) async {
    try {
      await _delete('/api/staff/$id');
    } catch (e) {
      lastError = 'Failed to delete staff: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== MENU ITEMS OPERATIONS ====================
  
  static Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await _get('/api/menu-items');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => MenuItem.fromMap(item)).toList();
    } catch (e) {
      lastError = 'Failed to get menu items: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertMenuItem(MenuItem item) async {
    try {
      final response = await _post('/api/menu-items', item.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to insert menu item: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateMenuItem(MenuItem item) async {
    try {
      final response = await _put('/api/menu-items/${item.id}', item.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to update menu item: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteMenuItem(int id) async {
    try {
      await _delete('/api/menu-items/$id');
    } catch (e) {
      lastError = 'Failed to delete menu item: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== PRODUCTS OPERATIONS ====================
  
  static Future<List<Product>> getProducts() async {
    try {
      final response = await _get('/api/products');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => Product.fromMap(item)).toList();
    } catch (e) {
      lastError = 'Failed to get products: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertProduct(Product product) async {
    try {
      final response = await _post('/api/products', product.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to insert product: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateProduct(Product product) async {
    try {
      final response = await _put('/api/products/${product.id}', product.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to update product: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteProduct(int id) async {
    try {
      await _delete('/api/products/$id');
    } catch (e) {
      lastError = 'Failed to delete product: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== TABLES OPERATIONS ====================
  
  static Future<List<TableRestaurant>> getTables() async {
    try {
      final response = await _get('/api/tables');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => TableRestaurant.fromMap(item)).toList();
    } catch (e) {
      lastError = 'Failed to get tables: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertTable(TableRestaurant table) async {
    try {
      final response = await _post('/api/tables', table.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to insert table: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateTable(TableRestaurant table) async {
    try {
      final response = await _put('/api/tables/${table.id}', table.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to update table: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteTable(int id) async {
    try {
      await _delete('/api/tables/$id');
    } catch (e) {
      lastError = 'Failed to delete table: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== PRINTERS OPERATIONS ====================
  
  static Future<List<Printer>> getPrinters() async {
    try {
      final response = await _get('/api/printers');
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => Printer.fromMap(item)).toList();
    } catch (e) {
      lastError = 'Failed to get printers: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertPrinter(Printer printer) async {
    try {
      final response = await _post('/api/printers', printer.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to insert printer: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updatePrinter(Printer printer) async {
    try {
      final response = await _put('/api/printers/${printer.id}', printer.toMap());
      return response['id'] as int;
    } catch (e) {
      lastError = 'Failed to update printer: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deletePrinter(int id) async {
    try {
      await _delete('/api/printers/$id');
    } catch (e) {
      lastError = 'Failed to delete printer: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== UTILITY METHODS ====================
  
  static String? getLastError() => lastError;
  
  static Future<void> clearError() async {
    lastError = null;
  }
  
  /// Teste la connexion à l'API
  static Future<bool> testConnection() async {
    try {
      await _get('/api/health');
      return true;
    } catch (e) {
      return false;
    }
  }
}


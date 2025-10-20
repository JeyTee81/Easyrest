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
import '../utils/type_parsers.dart';
import '../models/cash_register_opening.dart';
import '../models/cash_register_closing.dart';
import '../models/room.dart';
import '../models/reservation.dart';

class PostgreSQLService {
  static Connection? _connection;
  static String? lastError;
  
  /// Initialise la connexion à PostgreSQL
  static Future<void> initialize() async {
    try {
      final config = DatabaseConfig.connectionParams;
      print('🔌 PostgreSQL: Connecting to ${config['host']}:${config['port']}/${config['database']} as ${config['username']}');
      
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
      
      // Configuration de l'encodage pour les caractères français
      await _connection!.execute("SET client_encoding = 'UTF8'");
      await _connection!.execute("SET default_text_search_config = 'french'");
      
      print('✅ PostgreSQL: Connected successfully');
      lastError = null;
    } catch (e) {
      lastError = 'Failed to connect to PostgreSQL: $e';
      print('❌ PostgreSQL: Connection failed: $e');
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
  static Future<List<Map<String, dynamic>>> select(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      print('❌ PostgreSQL: Database not connected');
      throw Exception('Database not connected');
    }
    
    try {
      print('🔍 PostgreSQL: Executing query: $query');
      final results = await _connection!.execute(Sql(query), parameters: parameters ?? []);
      print('✅ PostgreSQL: Query executed successfully, ${results.length} rows returned');
      return results.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      lastError = 'Query failed: $e';
      print('❌ PostgreSQL: Query failed: $e');
      throw Exception(lastError);
    }
  }
  
  /// Exécute une requête INSERT/UPDATE/DELETE
  static Future<int> execute(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database not connected');
    }
    
    try {
      final results = await _connection!.execute(Sql(query), parameters: parameters ?? []);
      return results.affectedRows;
    } catch (e) {
      lastError = 'Query failed: $e';
      throw Exception(lastError);
    }
  }
  
  /// Exécute une requête INSERT et retourne l'ID généré
  static Future<int> insertAndGetId(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database not connected');
    }
    
    try {
      final results = await _connection!.execute(Sql(query), parameters: parameters ?? []);
      if (results.isNotEmpty) {
        return results.first[0] as int;
      }
      throw Exception('No ID returned from insert');
    } catch (e) {
      lastError = 'Insert failed: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== STAFF OPERATIONS ====================
  
  static Future<List<Staff>> getStaff() async {
    try {
      final results = await select('SELECT * FROM staff ORDER BY name');
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
        VALUES (\$1, \$2, \$3, \$4)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
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
        SET name = \$1, pin = \$2, role = \$3, is_active = \$4
        WHERE id = \$5
      ''';
      await execute(query, [
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
      await execute('UPDATE staff SET is_active = false WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete staff: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== MENU ITEM OPERATIONS ====================
  
  static Future<List<MenuItem>> getMenuItems() async {
    try {
      final results = await select('SELECT * FROM menu_items ORDER BY name');
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
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
        item.name,
        item.priceHt,
        item.priceTtc,
        item.tvaRate,
        item.description,
        item.category,
        item.type,
        item.printer,
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
        SET name = \$1, price_ht = \$2, price_ttc = \$3, tva_rate = \$4, 
            description = \$5, category = \$6, type = \$7, printer_id = \$8, 
            is_available = \$9, is_preset_menu = \$10
        WHERE id = \$11
      ''';
      await execute(query, [
        item.name,
        item.priceHt,
        item.priceTtc,
        item.tvaRate,
        item.description,
        item.category,
        item.type,
        item.printer,
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
      await execute('UPDATE menu_items SET is_available = false WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete menu item: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== PRODUCT OPERATIONS ====================
  
  static Future<List<Product>> getProducts() async {
    try {
      final results = await select('SELECT * FROM products ORDER BY name');
      return results.map((data) => Product.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get products: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertProduct(Product product) async {
    try {
      final query = '''
        INSERT INTO products (name, quantity, min_quantity, unit, description, price_ht, price_ttc, tva_rate)
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
        product.name,
        product.quantity,
        product.minQuantity,
        product.unit,
        product.description,
        product.priceHt,
        product.priceTtc,
        product.tvaRate,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert product: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateProduct(Product product) async {
    try {
      final query = '''
        UPDATE products 
        SET name = \$1, quantity = \$2, min_quantity = \$3, unit = \$4, 
            description = \$5, price_ht = \$6, price_ttc = \$7, tva_rate = \$8
        WHERE id = \$9
      ''';
      await execute(query, [
        product.name,
        product.quantity,
        product.minQuantity,
        product.unit,
        product.description,
        product.priceHt,
        product.priceTtc,
        product.tvaRate,
        product.id,
      ]);
      return product.id!;
    } catch (e) {
      lastError = 'Failed to update product: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteProduct(int id) async {
    try {
      await execute('DELETE FROM products WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete product: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== TABLE OPERATIONS ====================
  
  static Future<List<TableRestaurant>> getTables() async {
    try {
      final results = await select('SELECT * FROM tables ORDER BY number');
      return results.map((data) => TableRestaurant.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get tables: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertTable(TableRestaurant table) async {
    try {
      final query = '''
        INSERT INTO tables (number, capacity, room_id, status)
        VALUES (\$1, \$2, \$3, \$4)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
        table.number,
        table.capacity,
        table.roomId,
        table.status,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert table: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateTable(TableRestaurant table) async {
    try {
      final query = '''
        UPDATE tables 
        SET number = \$1, capacity = \$2, room_id = \$3, status = \$4
        WHERE id = \$5
      ''';
      await execute(query, [
        table.number,
        table.capacity,
        table.roomId,
        table.status,
        table.id,
      ]);
      return table.id!;
    } catch (e) {
      lastError = 'Failed to update table: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteTable(int id) async {
    try {
      await execute('UPDATE tables SET status = \'Inactive\' WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete table: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== PRINTER OPERATIONS ====================
  
  static Future<List<Printer>> getPrinters() async {
    try {
      final results = await select('SELECT * FROM printers ORDER BY name');
      return results.map((data) => Printer.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get printers: $e';
      throw Exception(lastError);
    }
  }
  
  // Note: Printer methods removed as we now use a simplified printer model
  // Printers are now managed as predefined constants in the Printer class
  
  // ==================== ORDER OPERATIONS ====================
  
  static Future<List<Order>> getOrders() async {
    try {
      final results = await select('SELECT * FROM orders ORDER BY created_at DESC');
      return results.map((data) => Order.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get orders: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertOrder(Order order) async {
    try {
      final query = '''
        INSERT INTO orders (table_id, status, total_ht, total_ttc, total_tva)
        VALUES (\$1, \$2, \$3, \$4, \$5)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
        order.tableId,
        order.status,
        order.totalHt,
        order.totalTtc,
        order.totalTva,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert order: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateOrder(Order order) async {
    try {
      final query = '''
        UPDATE orders 
        SET table_id = \$1, status = \$2, total_ht = \$3, total_ttc = \$4, total_tva = \$5
        WHERE id = \$6
      ''';
      await execute(query, [
        order.tableId,
        order.status,
        order.totalHt,
        order.totalTtc,
        order.totalTva,
        order.id,
      ]);
      return order.id!;
    } catch (e) {
      lastError = 'Failed to update order: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteOrder(int id) async {
    try {
      await execute('DELETE FROM orders WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete order: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== BILL OPERATIONS ====================
  
  static Future<List<Bill>> getBills() async {
    try {
      final results = await select('SELECT * FROM bills ORDER BY created_at DESC');
      return results.map((data) => Bill.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get bills: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertBill(Bill bill) async {
    try {
      final query = '''
        INSERT INTO bills (order_id, table_name, total_ht, total_ttc, total_tva, payment_method, status, archived)
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
        bill.orderId,
        bill.tableName,
        bill.totalHt,
        bill.totalTtc,
        bill.totalTva,
        bill.paymentMethod,
        bill.status,
        bill.archived,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert bill: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateBill(Bill bill) async {
    try {
      final query = '''
        UPDATE bills 
        SET order_id = \$1, table_name = \$2, total_ht = \$3, total_ttc = \$4, 
            total_tva = \$5, payment_method = \$6, status = \$7, archived = \$8
        WHERE id = \$9
      ''';
      await execute(query, [
        bill.orderId,
        bill.tableName,
        bill.totalHt,
        bill.totalTtc,
        bill.totalTva,
        bill.paymentMethod,
        bill.status,
        bill.archived,
        bill.id,
      ]);
      return bill.id!;
    } catch (e) {
      lastError = 'Failed to update bill: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteBill(int id) async {
    try {
      await execute('DELETE FROM bills WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete bill: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> archiveBillsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      
      // Only archive paid bills, not pending ones
      await execute(
        'UPDATE bills SET archived = TRUE WHERE created_at >= \$1 AND created_at < \$2 AND status = \$3',
        [startOfDay, endOfDay, 'paid']
      );
      
      print('Archived paid bills for date: ${date.day}/${date.month}/${date.year}');
    } catch (e) {
      lastError = 'Failed to archive bills by date: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== ROOM OPERATIONS ====================
  
  static Future<List<Room>> getRooms() async {
    try {
      final results = await select('SELECT * FROM rooms ORDER BY name');
      return results.map((data) => Room.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get rooms: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertRoom(Room room) async {
    try {
      final query = '''
        INSERT INTO rooms (name, description, is_active)
        VALUES (\$1, \$2, \$3)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
        room.name,
        room.description,
        room.isActive,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert room: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateRoom(Room room) async {
    try {
      final query = '''
        UPDATE rooms 
        SET name = \$1, description = \$2, is_active = \$3
        WHERE id = \$4
      ''';
      await execute(query, [
        room.name,
        room.description,
        room.isActive,
        room.id,
      ]);
      return room.id!;
    } catch (e) {
      lastError = 'Failed to update room: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteRoom(int id) async {
    try {
      await execute('UPDATE rooms SET is_active = false WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete room: $e';
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
      await select('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Force la réinitialisation de la connexion (utile après recréation de la base)
  static Future<void> forceReinitialize() async {
    try {
      print('🔄 PostgreSQL: Force reinitializing connection...');
      await close();
      await initialize();
      print('✅ PostgreSQL: Connection reinitialized successfully');
    } catch (e) {
      print('❌ PostgreSQL: Failed to reinitialize connection: $e');
      throw Exception('Failed to reinitialize PostgreSQL connection: $e');
    }
  }
  
  // ==================== MENU OPERATIONS ====================
  
  static Future<Map<String, int>> bulkImportMenuItems(List<MenuItem> menuItems) async {
    try {
      int successCount = 0;
      int errorCount = 0;
      
      for (final item in menuItems) {
        try {
          await insertMenuItem(item);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }
      
      return {
        'success': successCount,
        'errors': errorCount,
        'total': menuItems.length,
      };
    } catch (e) {
      lastError = 'Failed to bulk import menu items: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<MenuItem>> getPresetMenus() async {
    try {
      final results = await select('SELECT * FROM menu_items WHERE is_preset_menu = true ORDER BY name');
      return results.map((data) => MenuItem.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get preset menus: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<MenuItem>> getRegularMenuItems() async {
    try {
      final results = await select('SELECT * FROM menu_items WHERE is_preset_menu = false ORDER BY name');
      return results.map((data) => MenuItem.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get regular menu items: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertPresetMenu(MenuItem menu) async {
    try {
      final id = await insertAndGetId(
        'INSERT INTO menu_items (name, description, price_ht, price_ttc, tva_rate, category, type, is_preset_menu, is_available) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9) RETURNING id',
        [menu.name, menu.description, menu.priceHt, menu.priceTtc, menu.tvaRate, menu.category, menu.type, true, menu.isAvailable]
      );
      return id;
    } catch (e) {
      lastError = 'Failed to insert preset menu: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updatePresetMenu(MenuItem menu) async {
    try {
      await execute(
        'UPDATE menu_items SET name = \$1, description = \$2, price_ht = \$3, price_ttc = \$4, tva_rate = \$5, category = \$6, is_available = \$7 WHERE id = \$8',
        [menu.name, menu.description, menu.priceHt, menu.priceTtc, menu.tvaRate, menu.category, menu.isAvailable, menu.id]
      );
      return menu.id!;
    } catch (e) {
      lastError = 'Failed to update preset menu: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deletePresetMenu(int id) async {
    try {
      await execute('DELETE FROM menu_items WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete preset menu: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<MenuItem>> getMenuItemsByCategory(String category) async {
    try {
      final results = await select('SELECT * FROM menu_items WHERE category = \$1 ORDER BY name', [category]);
      return results.map((data) => MenuItem.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get menu items by category: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<String>> getMenuCategories() async {
    try {
      final results = await select('SELECT DISTINCT category FROM menu_items ORDER BY category');
      return results.map((data) => data['category'] as String).toList();
    } catch (e) {
      lastError = 'Failed to get menu categories: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== ORDER ITEM OPERATIONS ====================
  
  static Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      final results = await select('SELECT * FROM order_items WHERE order_id = \$1 ORDER BY id', [orderId]);
      return results.map((data) => OrderItem.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get order items: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertOrderItem(OrderItem item) async {
    try {
      final id = await insertAndGetId(
        'INSERT INTO order_items (order_id, menu_item_id, name, quantity, price_ht, price_ttc, tva_rate, total_ht, total_ttc, total_tva) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10) RETURNING id',
        [item.orderId, item.menuItemId, item.name, item.quantity, item.priceHt, item.priceTtc, item.tvaRate, item.totalHt, item.totalTtc, item.totalTva]
      );
      return id;
    } catch (e) {
      lastError = 'Failed to insert order item: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateOrderItem(OrderItem item) async {
    try {
      await execute(
        'UPDATE order_items SET quantity = \$1, price_ht = \$2, price_ttc = \$3, tva_rate = \$4, total_ht = \$5, total_ttc = \$6, total_tva = \$7 WHERE id = \$8',
        [item.quantity, item.priceHt, item.priceTtc, item.tvaRate, item.totalHt, item.totalTtc, item.totalTva, item.id]
      );
      return item.id!;
    } catch (e) {
      lastError = 'Failed to update order item: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteOrderItem(int id) async {
    try {
      await execute('DELETE FROM order_items WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete order item: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== BILL OPERATIONS ====================
  
  static Future<List<Bill>> getBillsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final results = await select(
        'SELECT * FROM bills WHERE created_at >= \$1 AND created_at < \$2 AND (archived = FALSE OR archived IS NULL) ORDER BY created_at DESC',
        [startOfDay, endOfDay]
      );
      return results.map((data) => Bill.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get bills by date: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<Bill>> getPendingBillsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      
      final results = await select(
        'SELECT * FROM bills WHERE created_at >= \$1 AND created_at < \$2 AND status = \$3 AND (archived = FALSE OR archived IS NULL) ORDER BY created_at DESC',
        [startOfDay, endOfDay, 'pending']
      );
      
      return results.map((data) => Bill.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get pending bills by date: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<Bill>> getBillsByPaymentMethod(String paymentMethod) async {
    try {
      final results = await select(
        'SELECT * FROM bills WHERE payment_method = \$1 AND (archived = FALSE OR archived IS NULL) ORDER BY created_at DESC',
        [paymentMethod]
      );
      return results.map((data) => Bill.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get bills by payment method: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<Map<String, double>> getDailyTotals(DateTime date) async {
    try {
      // Check if database is connected
      if (_connection == null) {
        print('❌ Database not connected, attempting to reconnect...');
        await initialize();
      }
      
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      
      print('Getting daily totals for date: ${date.day}/${date.month}/${date.year}');
      print('Date range: $startOfDay to $endOfDay');
      
      // Get payment method totals
      final paymentResults = await select(
        'SELECT payment_method, SUM(total_ttc) as total FROM bills WHERE created_at >= \$1 AND created_at < \$2 AND status = \$3 AND (archived = FALSE OR archived IS NULL) GROUP BY payment_method',
        [startOfDay, endOfDay, 'paid']
      );
      
      print('Payment results: $paymentResults');
      
      // Get overall totals
      final overallResults = await select(
        'SELECT SUM(total_ht) as total_ht, SUM(total_ttc) as total_ttc, SUM(total_tva) as total_tva FROM bills WHERE created_at >= \$1 AND created_at < \$2 AND status = \$3 AND (archived = FALSE OR archived IS NULL)',
        [startOfDay, endOfDay, 'paid']
      );
      
      print('Overall results: $overallResults');
      
      final totals = <String, double>{};
      
      // Add payment method totals
      for (final row in paymentResults) {
        final method = row['payment_method'] as String?;
        if (method != null) {
          final amount = parseDouble(row['total']);
          totals[method] = amount;
        }
      }
      
      // Add overall totals
      if (overallResults.isNotEmpty) {
        final overallRow = overallResults.first;
        totals['totalHt'] = parseDouble(overallRow['total_ht']);
        totals['totalTtc'] = parseDouble(overallRow['total_ttc']);
        totals['totalTva'] = parseDouble(overallRow['total_tva']);
      } else {
        // Initialize with zeros if no results
        totals['totalHt'] = 0.0;
        totals['totalTtc'] = 0.0;
        totals['totalTva'] = 0.0;
      }
      
      print('Final totals: $totals');
      return totals;
    } catch (e) {
      lastError = 'Failed to get daily totals: $e';
      print('Error in getDailyTotals: $e');
      throw Exception(lastError);
    }
  }
  
  // ==================== PRESET MENU COMPOSITION OPERATIONS ====================
  
  static Future<void> addItemToPresetMenu({required int presetMenuId, required int menuItemId, required String group}) async {
    try {
      await execute(
        'INSERT INTO preset_menu_items (preset_menu_id, menu_item_id, group_name) VALUES (\$1, \$2, \$3)',
        [presetMenuId, menuItemId, group]
      );
    } catch (e) {
      lastError = 'Failed to add item to preset menu: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> removeItemFromPresetMenu({required int presetMenuId, required int menuItemId, required String group}) async {
    try {
      await execute(
        'DELETE FROM preset_menu_items WHERE preset_menu_id = \$1 AND menu_item_id = \$2',
        [presetMenuId, menuItemId]
      );
    } catch (e) {
      lastError = 'Failed to remove item from preset menu: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<Map<String, List<MenuItem>>> getPresetMenuComposition(int presetMenuId) async {
    try {
      final results = await select(
        'SELECT mi.*, pmi.group_name FROM menu_items mi JOIN preset_menu_items pmi ON mi.id = pmi.menu_item_id WHERE pmi.preset_menu_id = \$1 ORDER BY pmi.group_name, mi.name',
        [presetMenuId]
      );
      
      final Map<String, List<MenuItem>> groupedItems = {};
      for (final row in results) {
        final groupName = row['group_name'] as String;
        final item = MenuItem.fromMap(row);
        
        if (!groupedItems.containsKey(groupName)) {
          groupedItems[groupName] = [];
        }
        groupedItems[groupName]!.add(item);
      }
      
      return groupedItems;
    } catch (e) {
      lastError = 'Failed to get preset menu composition: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> clearPresetMenuComposition(int presetMenuId) async {
    try {
      await execute('DELETE FROM preset_menu_items WHERE preset_menu_id = \$1', [presetMenuId]);
    } catch (e) {
      lastError = 'Failed to clear preset menu composition: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== CASH REGISTER OPERATIONS ====================
  
  static Future<int> insertCashRegisterOpening(CashRegisterOpening opening) async {
    try {
      final id = await insertAndGetId(
        'INSERT INTO cash_register_openings (date, shift_number, initial_cash_amount, opened_by, opened_at) VALUES (\$1, \$2, \$3, \$4, \$5) RETURNING id',
        [opening.date, opening.shiftNumber, opening.initialCashAmount, opening.openedBy, opening.openedAt]
      );
      return id;
    } catch (e) {
      lastError = 'Failed to insert cash register opening: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<CashRegisterOpening?> getActiveCashRegisterOpening(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final results = await select(
        'SELECT * FROM cash_register_openings WHERE date >= \$1 AND date < \$2 AND is_active = true ORDER BY opened_at DESC LIMIT 1',
        [startOfDay, endOfDay]
      );
      if (results.isEmpty) return null;
      return CashRegisterOpening.fromMap(results.first);
    } catch (e) {
      lastError = 'Failed to get active cash register opening: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<bool> isCashRegisterOpenForDate(DateTime date) async {
    try {
      final opening = await getActiveCashRegisterOpening(date);
      return opening != null;
    } catch (e) {
      lastError = 'Failed to check if cash register is open: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<CashRegisterOpening>> getCashRegisterOpeningsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final results = await select(
        'SELECT * FROM cash_register_openings WHERE date >= \$1 AND date < \$2 ORDER BY opened_at DESC',
        [startOfDay, endOfDay]
      );
      return results.map((data) => CashRegisterOpening.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get cash register openings by date: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> getNextShiftNumber(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final results = await select(
        'SELECT COALESCE(MAX(shift_number), 0) + 1 as next_shift FROM cash_register_openings WHERE date >= \$1 AND date < \$2',
        [startOfDay, endOfDay]
      );
      return results.first['next_shift'] as int;
    } catch (e) {
      lastError = 'Failed to get next shift number: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> closeCashRegisterOpening(int openingId) async {
    try {
      await execute(
        'UPDATE cash_register_openings SET is_active = false WHERE id = \$1',
        [openingId]
      );
    } catch (e) {
      lastError = 'Failed to close cash register opening: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertCashRegisterClosing(CashRegisterClosing closing) async {
    try {
      print('Inserting cash register closing:');
      print('  Date: ${closing.date}');
      print('  Shift: ${closing.shiftNumber}');
      print('  Total HT: ${closing.totalHt}');
      print('  Total TTC: ${closing.totalTtc}');
      print('  Payment methods: ${closing.paymentMethods}');
      print('  Payment methods as string: ${closing.paymentMethods.toString()}');
      
      // Convert payment methods to proper JSON
      final paymentMethodsJson = closing.paymentMethods.map((key, value) => MapEntry(key, value));
      
      final id = await insertAndGetId(
        'INSERT INTO cash_register_closings (date, shift_number, total_ht, total_ttc, total_tva, payment_methods, number_of_bills, expected_cash_amount, actual_cash_amount, cash_difference, closed_by, closed_at, notes) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13) RETURNING id',
        [closing.date, closing.shiftNumber, closing.totalHt, closing.totalTtc, closing.totalTva, paymentMethodsJson, closing.numberOfBills, closing.expectedCashAmount, closing.actualCashAmount, closing.cashDifference, closing.closedBy, closing.closedAt, closing.notes]
      );
      print('  Cash register closing inserted with ID: $id');
      return id;
    } catch (e) {
      lastError = 'Failed to insert cash register closing: $e';
      print('  Error inserting cash register closing: $e');
      throw Exception(lastError);
    }
  }
  
  static Future<List<CashRegisterClosing>> getCashRegisterClosings({DateTime? startDate, DateTime? endDate}) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      final end = endDate ?? DateTime.now();
      final results = await select(
        'SELECT * FROM cash_register_closings WHERE closed_at >= \$1 AND closed_at <= \$2 ORDER BY closed_at DESC',
        [start, end]
      );
      return results.map((data) => CashRegisterClosing.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get cash register closings: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<CashRegisterClosing?> getCashRegisterClosingByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final results = await select(
        'SELECT * FROM cash_register_closings WHERE closed_at >= \$1 AND closed_at < \$2 ORDER BY closed_at DESC LIMIT 1',
        [startOfDay, endOfDay]
      );
      if (results.isEmpty) return null;
      return CashRegisterClosing.fromMap(results.first);
    } catch (e) {
      lastError = 'Failed to get cash register closing by date: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<Map<String, double>> getMonthlyTotals(int year, int month) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);
      final results = await select(
        'SELECT payment_method, SUM(total_ttc) as total FROM bills WHERE created_at >= \$1 AND created_at < \$2 AND status = \$3 GROUP BY payment_method',
        [startOfMonth, endOfMonth, 'paid']
      );
      
      final totals = <String, double>{};
      for (final row in results) {
        totals[row['payment_method'] as String] = (row['total'] as num).toDouble();
      }
      return totals;
    } catch (e) {
      lastError = 'Failed to get monthly totals: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<bool> isCashRegisterClosedForDate(DateTime date) async {
    try {
      final closing = await getCashRegisterClosingByDate(date);
      return closing != null;
    } catch (e) {
      lastError = 'Failed to check if cash register is closed: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== ORDER OPERATIONS ====================
  
  static Future<List<Order>> getOrdersByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final results = await select(
        'SELECT * FROM orders WHERE created_at >= \$1 AND created_at < \$2 ORDER BY created_at DESC',
        [startOfDay, endOfDay]
      );
      return results.map((data) => Order.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get orders by date: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<Order?> getOrderById(int orderId) async {
    try {
      final results = await select('SELECT * FROM orders WHERE id = \$1', [orderId]);
      if (results.isEmpty) return null;
      return Order.fromMap(results.first);
    } catch (e) {
      lastError = 'Failed to get order by id: $e';
      throw Exception(lastError);
    }
  }

  static Future<List<OrderItem>> getOrderItemsByOrderId(int orderId) async {
    try {
      final results = await select('SELECT * FROM order_items WHERE order_id = \$1', [orderId]);
      return results.map((data) => OrderItem.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get order items by order id: $e';
      throw Exception(lastError);
    }
  }

  // ==================== RESERVATION OPERATIONS ====================
  
  static Future<List<Reservation>> getReservations() async {
    try {
      final results = await select('SELECT * FROM reservations ORDER BY reservation_date, reservation_time');
      return results.map((data) => Reservation.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get reservations: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<Reservation>> getReservationsByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD
      final results = await select(
        'SELECT * FROM reservations WHERE reservation_date = \$1 ORDER BY reservation_time',
        [dateStr]
      );
      return results.map((data) => Reservation.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get reservations by date: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<Reservation?> getReservationById(int id) async {
    try {
      final results = await select('SELECT * FROM reservations WHERE id = \$1', [id]);
      if (results.isEmpty) return null;
      return Reservation.fromMap(results.first);
    } catch (e) {
      lastError = 'Failed to get reservation by id: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertReservation(Reservation reservation) async {
    try {
      final query = '''
        INSERT INTO reservations (
          customer_name, customer_phone, customer_email, reservation_date, 
          reservation_time, number_of_guests, table_ids, special_requests, status
        )
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
        reservation.customerName,
        reservation.customerPhone,
        reservation.customerEmail,
        reservation.reservationDate.toIso8601String().split('T')[0],
        '${reservation.reservationTime.hour.toString().padLeft(2, '0')}:${reservation.reservationTime.minute.toString().padLeft(2, '0')}',
        reservation.numberOfGuests,
        reservation.tableIds.join(','),
        reservation.specialRequests,
        reservation.status,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert reservation: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updateReservation(Reservation reservation) async {
    try {
      final query = '''
        UPDATE reservations 
        SET customer_name = \$1, customer_phone = \$2, customer_email = \$3,
            reservation_date = \$4, reservation_time = \$5, number_of_guests = \$6,
            table_ids = \$7, special_requests = \$8, status = \$9, updated_at = NOW()
        WHERE id = \$10
      ''';
      await execute(query, [
        reservation.customerName,
        reservation.customerPhone,
        reservation.customerEmail,
        reservation.reservationDate.toIso8601String().split('T')[0],
        '${reservation.reservationTime.hour.toString().padLeft(2, '0')}:${reservation.reservationTime.minute.toString().padLeft(2, '0')}',
        reservation.numberOfGuests,
        reservation.tableIds.join(','),
        reservation.specialRequests,
        reservation.status,
        reservation.id,
      ]);
      return reservation.id!;
    } catch (e) {
      lastError = 'Failed to update reservation: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deleteReservation(int id) async {
    try {
      await execute('DELETE FROM reservations WHERE id = \$1', [id]);
    } catch (e) {
      lastError = 'Failed to delete reservation: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<Reservation>> getReservationsByTableId(int tableId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final results = await select(
        'SELECT * FROM reservations WHERE reservation_date = \$1 AND table_ids LIKE \$2 ORDER BY reservation_time',
        [dateStr, '%$tableId%']
      );
      return results.map((data) => Reservation.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get reservations by table id: $e';
      throw Exception(lastError);
    }
  }
  
}

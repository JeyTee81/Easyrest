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
import '../models/cash_register_opening.dart';
import '../models/cash_register_closing.dart';
import '../models/room.dart';

class PostgreSQLService {
  static Connection? _connection;
  static String? lastError;
  
  /// Initialise la connexion à PostgreSQL
  static Future<void> initialize() async {
    try {
      final config = DatabaseConfig.connectionParams;
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
      
      lastError = null;
    } catch (e) {
      lastError = 'Failed to connect to PostgreSQL: $e';
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
      throw Exception('Database not connected');
    }
    
    try {
      final results = await _connection!.execute(Sql(query), parameters: parameters ?? []);
      return results.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      lastError = 'Query failed: $e';
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
        VALUES ($name, $pin, $role, $is_active)
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
        SET name = $name, pin = $pin, role = $role, is_active = $is_active
        WHERE id = $id
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
      await execute('DELETE FROM staff WHERE id = $id', [id]);
    } catch (e) {
      lastError = 'Failed to delete staff: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== MENU ITEMS OPERATIONS ====================
  
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
      await execute('DELETE FROM menu_items WHERE id = $id', [id]);
    } catch (e) {
      lastError = 'Failed to delete menu item: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== PRODUCTS OPERATIONS ====================
  
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
        VALUES ($name, $quantity, $min_quantity, $unit, $description, $price_ht, $price_ttc, $tva_rate)
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
        SET name = $name, quantity = $quantity, min_quantity = $min_quantity, unit = $unit, 
            description = $description, price_ht = $price_ht, price_ttc = $price_ttc, tva_rate = $tva_rate
        WHERE id = $id
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
      await execute('DELETE FROM products WHERE id = $id', [id]);
    } catch (e) {
      lastError = 'Failed to delete product: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== TABLES OPERATIONS ====================
  
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
        VALUES ($number, $capacity, $room_id, $status)
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
        SET number = $number, capacity = $capacity, room_id = $room_id, status = $status
        WHERE id = $id
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
      await execute('DELETE FROM tables WHERE id = $id', [id]);
    } catch (e) {
      lastError = 'Failed to delete table: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== PRINTERS OPERATIONS ====================
  
  static Future<List<Printer>> getPrinters() async {
    try {
      final results = await select('SELECT * FROM printers ORDER BY name');
      return results.map((data) => Printer.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get printers: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertPrinter(Printer printer) async {
    try {
      final query = '''
        INSERT INTO printers (name, ip_address, port, location, is_active)
        VALUES ($name, $ip_address, $port, $location, $is_active)
        RETURNING id
      ''';
      final id = await insertAndGetId(query, [
        printer.name,
        printer.ipAddress,
        printer.port,
        printer.location,
        printer.isActive,
      ]);
      return id;
    } catch (e) {
      lastError = 'Failed to insert printer: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> updatePrinter(Printer printer) async {
    try {
      final query = '''
        UPDATE printers 
        SET name = $name, ip_address = $ip_address, port = $port, location = $location, is_active = $is_active
        WHERE id = $id
      ''';
      await execute(query, [
        printer.name,
        printer.ipAddress,
        printer.port,
        printer.location,
        printer.isActive,
        printer.id,
      ]);
      return printer.id!;
    } catch (e) {
      lastError = 'Failed to update printer: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> deletePrinter(int id) async {
    try {
      await execute('DELETE FROM printers WHERE id = $id', [id]);
    } catch (e) {
      lastError = 'Failed to delete printer: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== ORDERS OPERATIONS ====================
  
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
        VALUES ($table_id, $status, $total_ht, $total_ttc, $total_tva)
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
        SET table_id = $table_id, status = $status, total_ht = $total_ht, 
            total_ttc = $total_ttc, total_tva = $total_tva
        WHERE id = $id
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
      await execute('DELETE FROM orders WHERE id = $id', [id]);
    } catch (e) {
      lastError = 'Failed to delete order: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== BILLS OPERATIONS ====================
  
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
        INSERT INTO bills (order_id, table_name, total_ht, total_ttc, total_tva, payment_method, status)
        VALUES ($order_id, $table_name, $total_ht, $total_ttc, $total_tva, $payment_method, $status)
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
        SET order_id = $order_id, table_name = $table_name, total_ht = $total_ht, 
            total_ttc = $total_ttc, total_tva = $total_tva, payment_method = $payment_method, status = $status
        WHERE id = $id
      ''';
      await execute(query, [
        bill.orderId,
        bill.tableName,
        bill.totalHt,
        bill.totalTtc,
        bill.totalTva,
        bill.paymentMethod,
        bill.status,
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
      await execute('DELETE FROM bills WHERE id = $id', [id]);
    } catch (e) {
      lastError = 'Failed to delete bill: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== ROOMS OPERATIONS ====================
  
  static Future<List<Room>> getRooms() async {
    try {
      final results = await select('SELECT * FROM rooms WHERE is_active = true ORDER BY name');
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
        VALUES ($name, $description, $is_active)
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
        SET name = $name, description = $description, is_active = $is_active
        WHERE id = $id
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
      await execute('UPDATE rooms SET is_active = false WHERE id = $id', [id]);
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
        'INSERT INTO menu_items (name, description, price_ht, price_ttc, tva_rate, category, is_preset_menu, is_available) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8) RETURNING id',
        [menu.name, menu.description, menu.priceHt, menu.priceTtc, menu.tvaRate, menu.category, true, menu.isAvailable]
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
      await execute('DELETE FROM menu_items WHERE id = $id', [id]);
    } catch (e) {
      lastError = 'Failed to delete preset menu: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<MenuItem>> getMenuItemsByCategory(String category) async {
    try {
      final results = await select('SELECT * FROM menu_items WHERE category = $category ORDER BY name', [category]);
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
      final results = await select('SELECT * FROM order_items WHERE order_id = $order_id ORDER BY id', [orderId]);
      return results.map((data) => OrderItem.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get order items: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertOrderItem(OrderItem item) async {
    try {
      final id = await insertAndGetId(
        'INSERT INTO order_items (order_id, menu_item_id, quantity, price_ht, price_ttc, tva_rate, total_ht, total_ttc, total_tva) VALUES ($order_id, $menu_item_id, $quantity, $price_ht, $price_ttc, $tva_rate, $total_ht, $total_ttc, $total_tva) RETURNING id',
        [item.orderId, item.menuItemId, item.quantity, item.priceHt, item.priceTtc, item.tvaRate, item.totalHt, item.totalTtc, item.totalTva]
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
        'UPDATE order_items SET quantity = $quantity, price_ht = $price_ht, price_ttc = $price_ttc, tva_rate = $tva_rate, total_ht = $total_ht, total_ttc = $total_ttc, total_tva = $total_tva WHERE id = $id',
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
      await execute('DELETE FROM order_items WHERE id = $id', [id]);
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
        'SELECT * FROM bills WHERE created_at >= $start AND created_at < $end ORDER BY created_at DESC',
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
        'SELECT * FROM bills WHERE created_at >= $start AND created_at < $end AND status = $status ORDER BY created_at DESC',
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
        'SELECT * FROM bills WHERE payment_method = $payment_method ORDER BY created_at DESC',
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
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final results = await select(
        'SELECT payment_method, SUM(total_amount) as total FROM bills WHERE created_at >= $start AND created_at < $end AND status = $status GROUP BY payment_method',
        [startOfDay, endOfDay, 'paid']
      );
      
      final totals = <String, double>{};
      for (final row in results) {
        totals[row['payment_method'] as String] = (row['total'] as num).toDouble();
      }
      return totals;
    } catch (e) {
      lastError = 'Failed to get daily totals: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== PRESET MENU COMPOSITION OPERATIONS ====================
  
  static Future<void> addItemToPresetMenu({required int presetMenuId, required int menuItemId, required String group}) async {
    try {
      await execute(
        'INSERT INTO preset_menu_items (preset_menu_id, menu_item_id) VALUES ($preset_menu_id, $menu_item_id)',
        [presetMenuId, menuItemId]
      );
    } catch (e) {
      lastError = 'Failed to add item to preset menu: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> removeItemFromPresetMenu({required int presetMenuId, required int menuItemId, required String group}) async {
    try {
      await execute(
        'DELETE FROM preset_menu_items WHERE preset_menu_id = $preset_menu_id AND menu_item_id = $menu_item_id',
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
        'SELECT mi.* FROM menu_items mi JOIN preset_menu_items pmi ON mi.id = pmi.menu_item_id WHERE pmi.preset_menu_id = $preset_menu_id ORDER BY mi.name',
        [presetMenuId]
      );
      final items = results.map((data) => MenuItem.fromMap(data)).toList();
      return {'items': items};
    } catch (e) {
      lastError = 'Failed to get preset menu composition: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<void> clearPresetMenuComposition(int presetMenuId) async {
    try {
      await execute('DELETE FROM preset_menu_items WHERE preset_menu_id = $preset_menu_id', [presetMenuId]);
    } catch (e) {
      lastError = 'Failed to clear preset menu composition: $e';
      throw Exception(lastError);
    }
  }
  
  // ==================== CASH REGISTER OPERATIONS ====================
  
  static Future<int> insertCashRegisterOpening(CashRegisterOpening opening) async {
    try {
      final id = await insertAndGetId(
        'INSERT INTO cash_register_openings (date, shift_number, initial_cash_amount, opened_by, opened_at) VALUES ($date, $shift_number, $initial_cash_amount, $opened_by, $opened_at) RETURNING id',
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
        'SELECT * FROM cash_register_openings WHERE date >= $start AND date < $end AND closed_at IS NULL ORDER BY opened_at DESC LIMIT 1',
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
        'SELECT * FROM cash_register_openings WHERE date >= $start AND date < $end ORDER BY opened_at DESC',
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
        'SELECT COALESCE(MAX(shift_number), 0) + 1 as next_shift FROM cash_register_openings WHERE date >= $start AND date < $end',
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
        'UPDATE cash_register_openings SET closed_at = $closed_at WHERE id = $id',
        [DateTime.now(), openingId]
      );
    } catch (e) {
      lastError = 'Failed to close cash register opening: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<int> insertCashRegisterClosing(CashRegisterClosing closing) async {
    try {
      final id = await insertAndGetId(
        'INSERT INTO cash_register_closings (date, shift_number, total_ht, total_ttc, total_tva, payment_methods, number_of_bills, expected_cash_amount, actual_cash_amount, cash_difference, closed_by, closed_at, notes) VALUES ($date, $shift_number, $total_ht, $total_ttc, $total_tva, $payment_methods, $number_of_bills, $expected_cash_amount, $actual_cash_amount, $cash_difference, $closed_by, $closed_at, $notes) RETURNING id',
        [closing.date, closing.shiftNumber, closing.totalHt, closing.totalTtc, closing.totalTva, closing.paymentMethods.toString(), closing.numberOfBills, closing.expectedCashAmount, closing.actualCashAmount, closing.cashDifference, closing.closedBy, closing.closedAt, closing.notes]
      );
      return id;
    } catch (e) {
      lastError = 'Failed to insert cash register closing: $e';
      throw Exception(lastError);
    }
  }
  
  static Future<List<CashRegisterClosing>> getCashRegisterClosings({DateTime? startDate, DateTime? endDate}) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      final end = endDate ?? DateTime.now();
      final results = await select(
        'SELECT * FROM cash_register_closings WHERE closed_at >= $start AND closed_at <= $end ORDER BY closed_at DESC',
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
        'SELECT * FROM cash_register_closings WHERE closed_at >= $start AND closed_at < $end ORDER BY closed_at DESC LIMIT 1',
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
        'SELECT payment_method, SUM(total_amount) as total FROM bills WHERE created_at >= $start AND created_at < $end AND status = $status GROUP BY payment_method',
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
        'SELECT * FROM orders WHERE created_at >= $start AND created_at < $end ORDER BY created_at DESC',
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
      final results = await select('SELECT * FROM orders WHERE id = $id', [orderId]);
      if (results.isEmpty) return null;
      return Order.fromMap(results.first);
    } catch (e) {
      lastError = 'Failed to get order by id: $e';
      throw Exception(lastError);
    }
  }
}

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
import '../models/reservation.dart';

/// Service de base de données qui utilise PostgreSQL local
/// Remplace DatabaseService pour la compatibilité multi-plateforme
class ApiDatabaseService {
  static String? lastDatabaseError;
  static final ApiDatabaseService _instance = ApiDatabaseService._internal();
  factory ApiDatabaseService() => _instance;
  ApiDatabaseService._internal();

  // Staff operations
  Future<List<Staff>> getStaff() async {
    try {
      return await PostgreSQLService.getStaff();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get staff: $e');
    }
  }

  Future<int> insertStaff(Staff staff) async {
    try {
      return await PostgreSQLService.insertStaff(staff);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert staff: $e');
    }
  }

  Future<int> updateStaff(Staff staff) async {
    try {
      return await PostgreSQLService.updateStaff(staff);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update staff: $e');
    }
  }

  Future<int> deleteStaff(int id) async {
    try {
      await PostgreSQLService.deleteStaff(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete staff: $e');
    }
  }

  // Menu items operations
  Future<List<MenuItem>> getMenuItems() async {
    try {
      return await PostgreSQLService.getMenuItems();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get menu items: $e');
    }
  }

  Future<int> insertMenuItem(MenuItem item) async {
    try {
      return await PostgreSQLService.insertMenuItem(item);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert menu item: $e');
    }
  }

  Future<Map<String, int>> bulkImportMenuItems(List<MenuItem> menuItems) async {
    try {
      return await PostgreSQLService.bulkImportMenuItems(menuItems);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to bulk import menu items: $e');
    }
  }

  Future<int> updateMenuItem(MenuItem item) async {
    try {
      return await PostgreSQLService.updateMenuItem(item);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update menu item: $e');
    }
  }

  Future<int> deleteMenuItem(int id) async {
    try {
      await PostgreSQLService.deleteMenuItem(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete menu item: $e');
    }
  }

  // Preset menus operations
  Future<List<MenuItem>> getPresetMenus() async {
    try {
      return await PostgreSQLService.getPresetMenus();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get preset menus: $e');
    }
  }

  Future<List<MenuItem>> getRegularMenuItems() async {
    try {
      return await PostgreSQLService.getRegularMenuItems();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get regular menu items: $e');
    }
  }

  Future<int> insertPresetMenu(MenuItem menu) async {
    try {
      return await PostgreSQLService.insertPresetMenu(menu);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert preset menu: $e');
    }
  }

  Future<int> updatePresetMenu(MenuItem menu) async {
    try {
      return await PostgreSQLService.updatePresetMenu(menu);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update preset menu: $e');
    }
  }

  Future<int> deletePresetMenu(int id) async {
    try {
      await PostgreSQLService.deletePresetMenu(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete preset menu: $e');
    }
  }

  Future<List<MenuItem>> getMenuItemsByCategory(String category) async {
    try {
      return await PostgreSQLService.getMenuItemsByCategory(category);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get menu items by category: $e');
    }
  }

  Future<List<String>> getMenuCategories() async {
    try {
      return await PostgreSQLService.getMenuCategories();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get menu categories: $e');
    }
  }

  // Products operations
  Future<List<Product>> getProducts() async {
    try {
      return await PostgreSQLService.getProducts();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get products: $e');
    }
  }

  Future<int> insertProduct(Product product) async {
    try {
      return await PostgreSQLService.insertProduct(product);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert product: $e');
    }
  }

  Future<int> updateProduct(Product product) async {
    try {
      return await PostgreSQLService.updateProduct(product);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update product: $e');
    }
  }

  Future<int> deleteProduct(int id) async {
    try {
      await PostgreSQLService.deleteProduct(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete product: $e');
    }
  }

  // Tables operations
  Future<List<TableRestaurant>> getTables() async {
    try {
      return await PostgreSQLService.getTables();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get tables: $e');
    }
  }

  Future<int> insertTable(TableRestaurant table) async {
    try {
      return await PostgreSQLService.insertTable(table);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert table: $e');
    }
  }

  Future<int> updateTable(TableRestaurant table) async {
    try {
      return await PostgreSQLService.updateTable(table);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update table: $e');
    }
  }

  Future<int> deleteTable(int id) async {
    try {
      await PostgreSQLService.deleteTable(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete table: $e');
    }
  }

  // Orders operations
  Future<List<Order>> getOrders() async {
    try {
      return await PostgreSQLService.getOrders();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get orders: $e');
    }
  }

  Future<int> insertOrder(Order order) async {
    try {
      return await PostgreSQLService.insertOrder(order);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert order: $e');
    }
  }

  Future<int> updateOrder(Order order) async {
    try {
      return await PostgreSQLService.updateOrder(order);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update order: $e');
    }
  }

  Future<int> deleteOrder(int id) async {
    try {
      await PostgreSQLService.deleteOrder(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete order: $e');
    }
  }

  // Order items operations
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      return await PostgreSQLService.getOrderItems(orderId);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get order items: $e');
    }
  }

  Future<int> insertOrderItem(OrderItem item) async {
    try {
      return await PostgreSQLService.insertOrderItem(item);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert order item: $e');
    }
  }

  Future<int> updateOrderItem(OrderItem item) async {
    try {
      return await PostgreSQLService.updateOrderItem(item);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update order item: $e');
    }
  }

  Future<int> deleteOrderItem(int id) async {
    try {
      await PostgreSQLService.deleteOrderItem(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete order item: $e');
    }
  }

  // Bills operations
  Future<List<Bill>> getBills() async {
    try {
      return await PostgreSQLService.getBills();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get bills: $e');
    }
  }

  Future<List<Bill>> getBillsByDate(DateTime date) async {
    try {
      return await PostgreSQLService.getBillsByDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get bills by date: $e');
    }
  }

  Future<List<Bill>> getPendingBillsByDate(DateTime date) async {
    try {
      return await PostgreSQLService.getPendingBillsByDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get pending bills by date: $e');
    }
  }

  Future<List<Bill>> getBillsByPaymentMethod(String paymentMethod) async {
    try {
      return await PostgreSQLService.getBillsByPaymentMethod(paymentMethod);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get bills by payment method: $e');
    }
  }

  Future<Map<String, double>> getDailyTotals(DateTime date) async {
    try {
      return await PostgreSQLService.getDailyTotals(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get daily totals: $e');
    }
  }

  Future<int> insertBill(Bill bill) async {
    try {
      return await PostgreSQLService.insertBill(bill);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert bill: $e');
    }
  }

  Future<int> updateBill(Bill bill) async {
    try {
      return await PostgreSQLService.updateBill(bill);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update bill: $e');
    }
  }

  Future<int> deleteBill(int id) async {
    try {
      await PostgreSQLService.deleteBill(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete bill: $e');
    }
  }

  Future<void> archiveBillsByDate(DateTime date) async {
    try {
      await PostgreSQLService.archiveBillsByDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to archive bills by date: $e');
    }
  }

  // Printers operations
  Future<List<Printer>> getPrinters() async {
    try {
      return await PostgreSQLService.getPrinters();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get printers: $e');
    }
  }

  // Note: Printer methods removed as we now use a simplified printer model
  // Printers are now managed as predefined constants in the Printer class

  // Preset menu composition operations
  static const List<String> presetMenuGroups = [
    'Entrée',
    'Plat',
    'Dessert',
    'Boisson',
  ];

  Future<void> addItemToPresetMenu({
    required int presetMenuId,
    required int menuItemId,
    required String group,
  }) async {
    try {
      await PostgreSQLService.addItemToPresetMenu(
        presetMenuId: presetMenuId,
        menuItemId: menuItemId,
        group: group,
      );
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to add item to preset menu: $e');
    }
  }

  Future<void> removeItemFromPresetMenu({
    required int presetMenuId,
    required int menuItemId,
    required String group,
  }) async {
    try {
      await PostgreSQLService.removeItemFromPresetMenu(
        presetMenuId: presetMenuId,
        menuItemId: menuItemId,
        group: group,
      );
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to remove item from preset menu: $e');
    }
  }

  Future<Map<String, List<MenuItem>>> getPresetMenuComposition(int presetMenuId) async {
    try {
      return await PostgreSQLService.getPresetMenuComposition(presetMenuId);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get preset menu composition: $e');
    }
  }

  Future<void> clearPresetMenuComposition(int presetMenuId) async {
    try {
      await PostgreSQLService.clearPresetMenuComposition(presetMenuId);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to clear preset menu composition: $e');
    }
  }

  // Cash register opening operations
  Future<int> insertCashRegisterOpening(CashRegisterOpening opening) async {
    try {
      return await PostgreSQLService.insertCashRegisterOpening(opening);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert cash register opening: $e');
    }
  }

  Future<CashRegisterOpening?> getActiveCashRegisterOpening(DateTime date) async {
    try {
      return await PostgreSQLService.getActiveCashRegisterOpening(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get active cash register opening: $e');
    }
  }

  Future<bool> isCashRegisterOpenForDate(DateTime date) async {
    try {
      return await PostgreSQLService.isCashRegisterOpenForDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to check if cash register is open: $e');
    }
  }

  Future<List<CashRegisterOpening>> getCashRegisterOpeningsByDate(DateTime date) async {
    try {
      return await PostgreSQLService.getCashRegisterOpeningsByDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get cash register openings by date: $e');
    }
  }

  Future<int> getNextShiftNumber(DateTime date) async {
    try {
      return await PostgreSQLService.getNextShiftNumber(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get next shift number: $e');
    }
  }

  Future<void> closeCashRegisterOpening(int openingId) async {
    try {
      await PostgreSQLService.closeCashRegisterOpening(openingId);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to close cash register opening: $e');
    }
  }

  // Cash register closing operations
  Future<int> insertCashRegisterClosing(CashRegisterClosing closing) async {
    try {
      return await PostgreSQLService.insertCashRegisterClosing(closing);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert cash register closing: $e');
    }
  }

  Future<List<CashRegisterClosing>> getCashRegisterClosings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await PostgreSQLService.getCashRegisterClosings(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get cash register closings: $e');
    }
  }

  Future<CashRegisterClosing?> getCashRegisterClosingByDate(DateTime date) async {
    try {
      return await PostgreSQLService.getCashRegisterClosingByDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get cash register closing by date: $e');
    }
  }

  Future<Map<String, double>> getMonthlyTotals(int year, int month) async {
    try {
      return await PostgreSQLService.getMonthlyTotals(year, month);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get monthly totals: $e');
    }
  }

  Future<bool> isCashRegisterClosedForDate(DateTime date) async {
    try {
      return await PostgreSQLService.isCashRegisterClosedForDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to check if cash register is closed: $e');
    }
  }

  // Room management operations
  Future<List<Room>> getRooms() async {
    try {
      return await PostgreSQLService.getRooms();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get rooms: $e');
    }
  }

  Future<int> insertRoom(Room room) async {
    try {
      return await PostgreSQLService.insertRoom(room);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert room: $e');
    }
  }

  Future<int> updateRoom(Room room) async {
    try {
      return await PostgreSQLService.updateRoom(room);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update room: $e');
    }
  }

  Future<int> deleteRoom(int id) async {
    try {
      await PostgreSQLService.deleteRoom(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete room: $e');
    }
  }

  // Additional methods for compatibility
  Future<List<Order>> getOrdersByDate(DateTime date) async {
    try {
      return await PostgreSQLService.getOrdersByDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get orders by date: $e');
    }
  }

  Future<Order?> getOrderById(int orderId) async {
    try {
      return await PostgreSQLService.getOrderById(orderId);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get order by id: $e');
    }
  }

  // Database diagnostic function (simplified for PostgreSQL)
  static Future<Map<String, dynamic>> diagnoseDatabase() async {
    return {'status': 'PostgreSQL database managed locally'};
  }

  // Reset database (use with caution!)
  static Future<bool> resetDatabase() async {
    try {
      // TODO: Implement database reset for PostgreSQL
      return true;
    } catch (e) {
      return false;
    }
  }

  // Force reinitialize database (useful for troubleshooting)
  static Future<void> forceReinitialize() async {
    try {
      await PostgreSQLService.close();
      await PostgreSQLService.initialize();
    } catch (e) {
      print('Error reinitializing PostgreSQL: $e');
    }
  }

  // Additional methods for compatibility
  static String? getLastDatabaseError() => lastDatabaseError;

  static Future<String> getDatabasePath() async {
    return 'postgresql_local_database';
  }

  static Future<String> getExternalStoragePath() async {
    return 'postgresql_local_storage';
  }

  static Future<String> getEasyRestDirectoryPath() async {
    return 'postgresql_local_easyrest';
  }

  // Order Items operations
  Future<List<OrderItem>> getOrderItemsByOrderId(int orderId) async {
    try {
      return await PostgreSQLService.getOrderItemsByOrderId(orderId);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get order items: $e');
    }
  }

  // Create bill from order
  Future<void> createBillFromOrder(int orderId) async {
    try {
      // Get the order
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found with id: $orderId');
      }

      // Get order items to calculate totals
      final orderItems = await getOrderItemsByOrderId(orderId);
      if (orderItems.isEmpty) {
        throw Exception('No items found for order: $orderId');
      }

      // Calculate totals
      double totalHt = orderItems.fold(0.0, (sum, item) => sum + item.totalHt);
      double totalTva = orderItems.fold(0.0, (sum, item) => sum + item.totalTva);
      double totalTtc = orderItems.fold(0.0, (sum, item) => sum + item.totalTtc);

      // Create the bill
      final bill = Bill(
        orderId: orderId,
        tableName: 'Table ${order.tableId}',
        totalHt: totalHt,
        totalTva: totalTva,
        totalTtc: totalTtc,
        paymentMethod: null, // No payment method for pending bills
        createdAt: DateTime.now(),
        status: 'pending', // Set as pending
      );

      // Insert the bill
      await insertBill(bill);
      
      // Update order status to 'closed'
      final updatedOrder = order.copyWith(status: 'closed');
      await updateOrder(updatedOrder);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to create bill from order: $e');
    }
  }

  // Database property for compatibility
  dynamic get database => null; // PostgreSQL connection is managed internally

  // ==================== RESERVATION OPERATIONS ====================
  
  Future<List<Reservation>> getReservations() async {
    try {
      return await PostgreSQLService.getReservations();
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get reservations: $e');
    }
  }
  
  Future<List<Reservation>> getReservationsByDate(DateTime date) async {
    try {
      return await PostgreSQLService.getReservationsByDate(date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get reservations by date: $e');
    }
  }
  
  Future<Reservation?> getReservationById(int id) async {
    try {
      return await PostgreSQLService.getReservationById(id);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get reservation by id: $e');
    }
  }
  
  Future<int> insertReservation(Reservation reservation) async {
    try {
      return await PostgreSQLService.insertReservation(reservation);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to insert reservation: $e');
    }
  }
  
  Future<int> updateReservation(Reservation reservation) async {
    try {
      return await PostgreSQLService.updateReservation(reservation);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to update reservation: $e');
    }
  }
  
  Future<int> deleteReservation(int id) async {
    try {
      await PostgreSQLService.deleteReservation(id);
      return id;
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to delete reservation: $e');
    }
  }
  
  Future<List<Reservation>> getReservationsByTableId(int tableId, DateTime date) async {
    try {
      return await PostgreSQLService.getReservationsByTableId(tableId, date);
    } catch (e) {
      lastDatabaseError = e.toString();
      throw Exception('Failed to get reservations by table id: $e');
    }
  }

  // Close PostgreSQL connection
  Future<void> close() async {
    await PostgreSQLService.close();
  }
}
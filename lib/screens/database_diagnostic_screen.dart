import 'package:flutter/material.dart';
import '../services/api_database_service.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class DatabaseDiagnosticScreen extends StatefulWidget {
  const DatabaseDiagnosticScreen({super.key});

  @override
  State<DatabaseDiagnosticScreen> createState() => _DatabaseDiagnosticScreenState();
}

class _DatabaseDiagnosticScreenState extends State<DatabaseDiagnosticScreen> {
  Map<String, dynamic>? _diagnosis;
  bool _isLoading = true;
  String? _error;
  String? _diagnosticMessage;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Starting database diagnostic...');
      final diagnosis = await ApiDatabaseService.diagnoseDatabase();
      print('Diagnostic completed: $diagnosis');
      
      setState(() {
        _diagnosis = diagnosis;
        _isLoading = false;
      });
    } catch (e, stack) {
      print('Diagnostic error: $e');
      print('Stack trace: $stack');
      
      setState(() {
        _error = 'Erreur de diagnostic: $e\n\nStack trace:\n$stack';
        _isLoading = false;
      });
    }
  }

  Future<void> _runDebugScript() async {
    setState(() => _isLoading = true);
    
    try {
      // Force reinitialize database
      await ApiDatabaseService.forceReinitialize();
      
      // Run diagnostic again
      await _runDiagnostic();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug script exécuté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur debug: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Attention'),
        content: const Text(
          'Cette action va supprimer TOUTES les données de la base de données et la recréer. '
          'Cette action est irréversible. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final success = await ApiDatabaseService.resetDatabase();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Base de données réinitialisée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _runDiagnostic();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la réinitialisation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testOrderCreation() async {
    try {
      setState(() {
        _diagnosticMessage = 'Testing order creation...';
        _isLoading = true;
      });

      final dbService = ApiDatabaseService();
      
      // Test 1: Check if tables exist
      final tables = await dbService.database;
      final tableList = await tables.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tableList.map((t) => t['name'] as String).toList();
      
      if (!tableNames.contains('orders')) {
        throw Exception('Orders table does not exist');
      }
      if (!tableNames.contains('order_items')) {
        throw Exception('Order_items table does not exist');
      }
      if (!tableNames.contains('menu_items')) {
        throw Exception('Menu_items table does not exist');
      }

      // Test 2: Check orders table structure
      final orderColumns = await tables.rawQuery("PRAGMA table_info(orders)");
      final orderColumnNames = orderColumns.map((c) => c['name'] as String).toList();
      
      final requiredOrderColumns = ['id', 'tableId', 'status', 'totalHt', 'totalTtc', 'totalTva', 'createdAt'];
      for (final column in requiredOrderColumns) {
        if (!orderColumnNames.contains(column)) {
          throw Exception('Orders table missing column: $column');
        }
      }

      // Test 3: Check order_items table structure
      final orderItemColumns = await tables.rawQuery("PRAGMA table_info(order_items)");
      final orderItemColumnNames = orderItemColumns.map((c) => c['name'] as String).toList();
      
      final requiredOrderItemColumns = ['id', 'orderId', 'menuItemId', 'name', 'quantity', 'priceHt', 'priceTtc', 'tvaRate', 'totalHt', 'totalTtc', 'totalTva'];
      for (final column in requiredOrderItemColumns) {
        if (!orderItemColumnNames.contains(column)) {
          throw Exception('Order_items table missing column: $column');
        }
      }

      // Test 4: Check if we have menu items
      final menuItems = await dbService.getMenuItems();
      if (menuItems.isEmpty) {
        throw Exception('No menu items found in database');
      }

      // Test 5: Check if we have tables
      final tablesList = await dbService.getTables();
      if (tablesList.isEmpty) {
        throw Exception('No tables found in database');
      }

      // Test 6: Try to create a test order
      final testTable = tablesList.first;
      final testMenuItem = menuItems.first;
      
      final testOrder = Order.fromItems(
        tableId: testTable.id!,
        items: [],
        status: 'active',
      );
      
      final orderId = await dbService.insertOrder(testOrder);
      
      // Test 7: Try to add an item to the test order
      final testOrderItem = OrderItem.fromMenuItem(
        testMenuItem.id!,
        testMenuItem.name,
        testMenuItem.priceHt,
        testMenuItem.priceTtc,
        testMenuItem.tvaRate,
        1,
        orderId: orderId,
      );
      
      await dbService.insertOrderItem(testOrderItem);
      
      // Test 8: Clean up test data
      await dbService.deleteOrder(orderId);

      setState(() {
        _diagnosticMessage = '''
✅ Database structure is correct
✅ Orders table: ${orderColumnNames.join(', ')}
✅ Order_items table: ${orderItemColumnNames.join(', ')}
✅ Menu items: ${menuItems.length} items found
✅ Tables: ${tablesList.length} tables found
✅ Order creation test: PASSED
✅ Order item insertion test: PASSED

The database is working correctly. If you're still getting errors, please check:
1. That you have menu items in your database
2. That you have tables configured
3. The specific error message in the console
''';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _diagnosticMessage = '❌ Database test failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        elevation: 0,
        title: const Text(
          'Diagnostic Base de Données',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFbfa14a)),
            onPressed: _runDiagnostic,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Color(0xFFbfa14a)),
            onPressed: _runDebugScript,
            tooltip: 'Debug script',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : _error != null
              ? _buildErrorWidget()
              : _buildDiagnosticWidget(),
      floatingActionButton: _diagnosis != null && _diagnosis!['error'] == null
          ? FloatingActionButton(
              onPressed: _resetDatabase,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: const Icon(Icons.delete_forever),
            )
          : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erreur de diagnostic',
              style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetDatabase,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Réinitialiser la base de données'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticWidget() {
    if (_diagnosis == null) return const SizedBox.shrink();

    final tables = _diagnosis!['tables'] as List<String>? ?? [];
    final tableStructures = _diagnosis!['tableStructures'] as Map<String, dynamic>? ?? {};
    final dataCounts = _diagnosis!['dataCounts'] as Map<String, dynamic>? ?? {};
    final error = _diagnosis!['error'] as String?;
    final lastDatabaseError = _diagnosis!['lastDatabaseError'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Tables trouvées (${tables.length})',
            tables.map((table) => Text(
              '• $table',
              style: const TextStyle(color: Colors.white),
            )).toList(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Nombre d\'enregistrements',
            dataCounts.entries.map((entry) {
              final count = entry.value;
              final color = count >= 0 ? Colors.green : Colors.red;
              final text = count >= 0 ? count.toString() : 'Erreur';
              return Row(
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: $text',
                    style: TextStyle(color: color),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Structure des tables',
            tableStructures.entries.map((entry) {
              final tableName = entry.key;
              final columns = entry.value as List<dynamic>;
              return ExpansionTile(
                title: Text(
                  tableName,
                  style: const TextStyle(color: Color(0xFFbfa14a)),
                ),
                children: columns.map((col) {
                  final column = col as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      '${column['name']} (${column['type']})',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
          if (error != null) ...[
            const SizedBox(height: 24),
            _buildSection(
              'Erreurs détectées',
              [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Erreur principale:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (lastDatabaseError != null) ...[
            const SizedBox(height: 24),
            _buildSection(
              'Dernière erreur de base de données',
              [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade900,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Erreur de base de données:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lastDatabaseError,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _runDebugScript,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Debug Script'),
              ),
              ElevatedButton(
                onPressed: _resetDatabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réinitialiser DB'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFbfa14a),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
} 
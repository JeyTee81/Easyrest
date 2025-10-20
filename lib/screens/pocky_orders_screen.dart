import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/table_restaurant.dart';
import '../services/remote_data_service.dart';
import 'bill_screen.dart';

class PockyOrdersScreen extends StatefulWidget {
  final TableRestaurant? selectedTable;
  const PockyOrdersScreen({super.key, this.selectedTable});

  @override
  State<PockyOrdersScreen> createState() => _PockyOrdersScreenState();
}

class _PockyOrdersScreenState extends State<PockyOrdersScreen> {
  final RemoteDataService _dataService = RemoteDataService();
  List<MenuItem> _menuItems = [];
  List<TableRestaurant> _tables = [];
  TableRestaurant? _selectedTable;
  Order? _selectedOrder;
  List<OrderItem> _currentOrderItems = [];
  bool _isLoading = true;
  
  // Navigation state
  String _currentView = 'categories'; // 'categories', 'subcategories', 'products'
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  
  // Logs pour le débogage
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.selectedTable;
    _initializeAndLoadData();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    debugPrint(message);
  }

  Future<void> _initializeAndLoadData() async {
    _addLog('Initialisation du service de données...');
    await _dataService.initialize();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _addLog('=== DÉBUT DU CHARGEMENT DES DONNÉES ===');
      setState(() {
        _isLoading = true;
      });

      _addLog('Vérification de la connexion...');
      // Vérifier la connexion
      if (!_dataService.isConnected) {
        _addLog('❌ ERREUR: Non connecté à l\'application Tablette');
        throw Exception('Non connecté à l\'application Tablette');
      }
      _addLog('✅ Connexion établie');

      _addLog('📋 Chargement du menu...');
      // Charger les données depuis le serveur distant
      final menuItems = await _dataService.loadMenuItems();
      _addLog('✅ Menu chargé: ${menuItems.length} éléments');
      
      final regularItems = menuItems.where((item) => !item.isPreset).toList();
      final presetMenus = menuItems.where((item) => item.isPreset).toList();
      _addLog('📊 Articles réguliers: ${regularItems.length}, Menus: ${presetMenus.length}');

      _addLog('🪑 Chargement des tables...');
      final tables = await _dataService.loadTables();
      _addLog('✅ Tables chargées: ${tables.length} tables');

      setState(() {
        _menuItems = [...regularItems, ...presetMenus];
        _tables = tables;
        _isLoading = false;
      });
      
      _addLog('=== CHARGEMENT TERMINÉ - ${_tables.length} tables et ${_menuItems.length} articles ===');

      // If a table is already selected, load existing order
      if (_selectedTable != null) {
        _addLog('🪑 Table déjà sélectionnée: ${_selectedTable!.number}');
        // TODO: Implémenter le chargement des commandes existantes via le service distant
        // await _loadExistingOrder(activeOrders);
      }
    } catch (e) {
      _addLog('❌ ERREUR dans _loadData: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100),
      ),
    );
  }

  void _showLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2438),
        title: const Text(
          'Logs de Débogage',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _logs.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun log disponible',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
            child: const Text(
              'Effacer',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fermer',
              style: TextStyle(color: Color(0xFFbfa14a)),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _currentView = 'subcategories';
    });
  }

  void _selectSubcategory(String subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
      _currentView = 'products';
    });
  }

  void _goBack() {
    setState(() {
      if (_currentView == 'products') {
        _currentView = 'subcategories';
        _selectedSubcategory = '';
      } else if (_currentView == 'subcategories') {
        _currentView = 'categories';
        _selectedCategory = '';
      }
    });
  }

  void _goToCategories() {
    setState(() {
      _currentView = 'categories';
      _selectedCategory = '';
      _selectedSubcategory = '';
    });
  }

  Future<void> _addItemToOrder(MenuItem item) async {
    try {
      _addLog('Ajout de l\'article: ${item.name} (ID: ${item.id})');
      
      // Create new order if none exists
      if (_selectedOrder == null) {
        if (_selectedTable == null) {
          _showError('Aucune table sélectionnée');
          return;
        }
        _addLog('Création d\'une nouvelle commande pour la table: ${_selectedTable!.number}');
        final newOrder = Order.fromItems(
          tableId: _selectedTable!.id!,
          items: [],
          status: 'active',
        );
        setState(() {
          _selectedOrder = newOrder;
        });
      }

      // Check if item already exists in order
      final existingItemIndex = _currentOrderItems.indexWhere(
        (orderItem) => orderItem.menuItemId == item.id,
      );

      if (existingItemIndex != -1) {
        _addLog('Mise à jour de la quantité de l\'article existant');
        // Update quantity
        final existingItem = _currentOrderItems[existingItemIndex];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
          totalHt: (existingItem.quantity + 1) * item.priceHt,
          totalTtc: (existingItem.quantity + 1) * item.priceTtc,
          totalTva: (existingItem.quantity + 1) * item.tvaAmount,
        );
        
        setState(() {
          _currentOrderItems[existingItemIndex] = updatedItem;
        });
        _addLog('Quantité mise à jour');
      } else {
        _addLog('Ajout d\'un nouvel article à la commande');
        // Add new item
        final orderItem = OrderItem.fromMenuItem(
          item.id!,
          item.name,
          item.priceHt,
          item.priceTtc,
          item.tvaRate,
          1,
          orderId: _selectedOrder?.id,
        );

        setState(() {
          _currentOrderItems.add(orderItem);
        });
        _addLog('Nouvel article ajouté');
      }

      _showSuccess('${item.name} ajouté à la commande');
    } catch (e) {
      _addLog('❌ Erreur lors de l\'ajout: $e');
      _showError('Erreur lors de l\'ajout: $e');
    }
  }

  Future<void> _closeOrder() async {
    if (_selectedOrder == null) {
      _showError('Aucune commande active');
      return;
    }

    if (_currentOrderItems.isEmpty) {
      _showError('Aucun article dans la commande');
      return;
    }

    try {
      _addLog('Envoi de la commande au serveur...');
      // Envoyer la commande au serveur
      final result = await _dataService.sendOrder(_selectedOrder!, _currentOrderItems);
      
      setState(() {
        _selectedOrder = null;
        _currentOrderItems.clear();
      });
      
      _addLog('✅ Commande envoyée avec succès (ID: ${result.id})');
      _showSuccess('Commande envoyée avec succès (ID: ${result.id})');
      
    } catch (e) {
      _addLog('❌ Erreur lors de l\'envoi de la commande: $e');
      _showError('Erreur lors de l\'envoi de la commande: $e');
    }
  }

  // Get categories from menu items
  List<String> _getCategories() {
    final categories = _menuItems.map((item) => item.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Get subcategories for a category
  List<String> _getSubcategories(String category) {
    final subcategories = _menuItems
        .where((item) => item.category == category)
        .map((item) => item.type)
        .toSet()
        .toList();
    subcategories.sort();
    return subcategories;
  }

  // Get products for a category and subcategory
  List<MenuItem> _getProducts(String category, String subcategory) {
    return _menuItems.where((item) => 
      item.category == category && item.type == subcategory
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: Text(
          _selectedTable != null 
              ? 'Commande - Table ${_selectedTable!.number}'
              : 'Commandes',
          style: const TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _showLogs,
            tooltip: 'Voir les logs de débogage',
          ),
          if (_currentView != 'categories')
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: _goToCategories,
              tooltip: 'Retour aux catégories',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : _selectedTable == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.table_restaurant,
                        size: 64,
                        color: Color(0xFFbfa14a),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sélectionner une table',
                        style: TextStyle(
                          color: Colors.white70, 
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implémenter la sélection de table
                        },
                        icon: const Icon(Icons.table_restaurant),
                        label: const Text('Choisir une table'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFbfa14a),
                          foregroundColor: const Color(0xFF231f2b),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Navigation breadcrumb
                    if (_currentView != 'categories')
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: _goBack,
                              child: const Text('← Retour'),
                            ),
                            const Text(' > '),
                            Text(_selectedCategory),
                            if (_currentView == 'products') ...[
                              const Text(' > '),
                              Text(_selectedSubcategory),
                            ],
                          ],
                        ),
                      ),
                    
                    // Content area
                    Expanded(
                      child: _currentView == 'categories'
                          ? _buildCategoriesView()
                          : _currentView == 'subcategories'
                              ? _buildSubcategoriesView()
                              : _buildProductsView(),
                    ),
                    
                    // Order summary
                    if (_currentOrderItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2a2438),
                          border: Border(top: BorderSide(color: Color(0xFFbfa14a))),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Commande (${_currentOrderItems.length} articles)',
                                  style: const TextStyle(
                                    color: Color(0xFFbfa14a),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Total: ${_currentOrderItems.fold(0.0, (sum, item) => sum + item.totalTtc).toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _closeOrder,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Valider la commande'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildCategoriesView() {
    final categories = _getCategories();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          color: const Color(0xFF2a2438),
          child: InkWell(
            onTap: () => _selectCategory(category),
            child: Center(
              child: Text(
                category,
                style: const TextStyle(
                  color: Color(0xFFbfa14a),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubcategoriesView() {
    final subcategories = _getSubcategories(_selectedCategory);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final subcategory = subcategories[index];
        return Card(
          color: const Color(0xFF2a2438),
          child: InkWell(
            onTap: () => _selectSubcategory(subcategory),
            child: Center(
              child: Text(
                subcategory,
                style: const TextStyle(
                  color: Color(0xFFbfa14a),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsView() {
    final products = _getProducts(_selectedCategory, _selectedSubcategory);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          color: const Color(0xFF2a2438),
          child: ListTile(
            title: Text(
              product.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              product.description ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${product.priceTtc.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    color: Color(0xFFbfa14a),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!product.isAvailable)
                  const Text(
                    'Indisponible',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            onTap: product.isAvailable ? () => _addItemToOrder(product) : null,
          ),
        );
      },
    );
  }
}





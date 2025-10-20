import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/table_restaurant.dart';
import '../services/api_database_service.dart';
import '../services/production_service.dart';
import 'bill_screen.dart';

class OrdersScreen extends StatefulWidget {
  final TableRestaurant? selectedTable;
  const OrdersScreen({super.key, this.selectedTable});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<MenuItem> _menuItems = [];
  List<TableRestaurant> _tables = [];
  TableRestaurant? _selectedTable;
  Order? _selectedOrder;
  List<OrderItem> _currentOrderItems = [];
  bool _isLoading = true;
  
  // Navigation state
  String _currentView = 'categories'; // 'categories', 'subcategories', 'subsubcategories', 'products'
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  String _selectedSubsubcategory = '';

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.selectedTable;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final menuItems = await _dbService.getMenuItems();
      final regularItems = menuItems.where((item) => !item.isPreset).toList();
      final presetMenus = menuItems.where((item) => item.isPreset).toList();
      final tables = await _dbService.getTables();
      final activeOrders = await _dbService.getOrders();

      setState(() {
        _menuItems = [...regularItems, ...presetMenus];
        _tables = tables;
        _isLoading = false;
      });
      
      debugPrint('Loaded ${_tables.length} tables');

      // If a table is already selected, load existing order
      if (_selectedTable != null) {
        await _loadExistingOrder(activeOrders);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement: $e');
    }
  }

  Future<void> _promptTableSelection() async {
    final selected = await showDialog<TableRestaurant>(
      context: context,
      barrierDismissible: true, // Permet de fermer en cliquant à l'extérieur
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a3a),
        title: const Text(
          'Sélectionnez une table',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300, // Hauteur fixe pour éviter les problèmes de layout
          child: _tables.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune table disponible',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    return ListTile(
                      title: Text(
                        'Table ${table.number}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Capacité: ${table.capacity} - Statut: ${table.status}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () => Navigator.pop(context, table),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFFbfa14a)),
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedTable = selected;
      });
      final activeOrders = await _dbService.getOrders();
      await _loadExistingOrder(activeOrders);
    } else {
      Navigator.pop(context); // Exit if no table selected
    }
  }

  Future<void> _loadExistingOrder(List<Order> orders) async {
    try {
      final tableOrder = orders.where((order) => 
        order.tableId == _selectedTable!.id && 
        order.status == 'active'
      ).firstOrNull;

      if (tableOrder != null) {
        setState(() {
          _selectedOrder = tableOrder;
        });
        await _loadOrderItems();
      }
    } catch (e) {
      _showError('Erreur lors du chargement de la commande: $e');
    }
  }

  Future<void> _loadOrderItems() async {
    if (_selectedOrder == null) return;
    
    try {
      final orderItems = await _dbService.getOrderItems(_selectedOrder!.id!);
      setState(() {
        _currentOrderItems = orderItems;
      });
    } catch (e) {
      _showError('Erreur lors du chargement des articles: $e');
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
        duration: const Duration(seconds: 1), // Durée réduite à 1 seconde
        behavior: SnackBarBehavior.floating, // Flottant pour ne pas masquer les boutons
        margin: const EdgeInsets.only(bottom: 100), // Marge pour éviter les boutons
      ),
    );
  }

  /// Vérifie si une commande peut être créée pour cette table
  bool _canCreateOrderForTable(TableRestaurant table) {
    // Permettre la création de commande pour les tables "Libre" et "Réservée"
    return table.status == 'Libre' || table.status == 'Réservée';
  }

  /// Met à jour le statut d'une table
  Future<void> _updateTableStatus(TableRestaurant table, String newStatus) async {
    try {
      final updatedTable = TableRestaurant(
        id: table.id,
        number: table.number,
        capacity: table.capacity,
        roomId: table.roomId,
        status: newStatus,
      );
      
      await _dbService.updateTable(updatedTable);
      
      // Mettre à jour la table dans la liste locale
      setState(() {
        final index = _tables.indexWhere((t) => t.id == table.id);
        if (index != -1) {
          _tables[index] = updatedTable;
        }
        if (_selectedTable?.id == table.id) {
          _selectedTable = updatedTable;
        }
      });
      
      debugPrint('Table ${table.number} status updated to: $newStatus');
    } catch (e) {
      debugPrint('Error updating table status: $e');
      _showError('Erreur lors de la mise à jour du statut de la table: $e');
    }
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
      
      // Vérifier si cette sous-catégorie a des sous-sous-catégories
      if (_selectedCategory == 'Boissons') {
        final subsubcategories = _getSubsubcategories(_selectedCategory, subcategory);
        if (subsubcategories.isNotEmpty) {
          _currentView = 'subsubcategories';
        } else {
          _currentView = 'products';
        }
      } else {
        _currentView = 'products';
      }
    });
  }

  void _selectSubsubcategory(String subsubcategory) {
    setState(() {
      _selectedSubsubcategory = subsubcategory;
      _currentView = 'products';
    });
  }

  void _goBack() {
    setState(() {
      if (_currentView == 'products') {
        if (_selectedSubsubcategory.isNotEmpty) {
          _currentView = 'subsubcategories';
          _selectedSubsubcategory = '';
        } else {
          _currentView = 'subcategories';
          _selectedSubcategory = '';
        }
      } else if (_currentView == 'subsubcategories') {
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
      _selectedSubsubcategory = '';
    });
  }

  String _getBreadcrumbText() {
    switch (_currentView) {
      case 'subcategories':
        return _selectedCategory;
      case 'subsubcategories':
        return '$_selectedCategory > $_selectedSubcategory';
      case 'products':
        if (_selectedSubsubcategory.isNotEmpty) {
          return '$_selectedCategory > $_selectedSubcategory > $_selectedSubsubcategory';
        } else {
          return '$_selectedCategory > $_selectedSubcategory';
        }
      default:
        return _selectedCategory;
    }
  }

  Future<void> _addItemToOrder(MenuItem item) async {
    try {
      debugPrint('Adding item to order: ${item.name} (ID: ${item.id})');
      
      // Create new order if none exists
      if (_selectedOrder == null) {
        if (_selectedTable == null) {
          _showError('Aucune table sélectionnée');
          return;
        }
        
        // Vérifier le statut de la table avant de créer une commande
        if (!_canCreateOrderForTable(_selectedTable!)) {
          _showError('Impossible de créer une commande pour cette table. Statut: ${_selectedTable!.status}');
          return;
        }
        
        debugPrint('Creating new order for table: ${_selectedTable!.number}');
        final newOrder = Order.fromItems(
          tableId: _selectedTable!.id!,
          items: [],
          status: 'active',
        );
        final orderId = await _dbService.insertOrder(newOrder);
        debugPrint('New order created with ID: $orderId');
        
        // Mettre à jour le statut de la table à "Occupée"
        await _updateTableStatus(_selectedTable!, 'Occupée');
        
        setState(() {
          _selectedOrder = newOrder.copyWith(id: orderId);
        });
      }

      // Check if item already exists in order
      final existingItem = _currentOrderItems.firstWhere(
        (orderItem) => orderItem.menuItemId == item.id,
        orElse: () => OrderItem.fromMenuItem(
          item.id!,
          item.name,
          item.priceHt,
          item.priceTtc,
          item.tvaRate,
          0,
          orderId: null,
        ),
      );

      if (existingItem.id != null) {
        debugPrint('Updating existing item quantity');
        // Update quantity
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
          totalHt: (existingItem.quantity + 1) * item.priceHt,
          totalTtc: (existingItem.quantity + 1) * item.priceTtc,
          totalTva: (existingItem.quantity + 1) * item.tvaAmount,
        );
        
        await _dbService.updateOrderItem(updatedItem);
        debugPrint('Item quantity updated');
      } else {
        debugPrint('Adding new item to order');
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

        await _dbService.insertOrderItem(orderItem);
        debugPrint('New item added to order');
      }

      await _loadOrderItems();
      _showSuccess('${item.name} ajouté à la commande');
    } catch (e) {
      debugPrint('Error adding item to order: $e');
      _showError('Erreur lors de l\'ajout: $e');
    }
  }


  Future<void> _printOrder() async {
    if (_currentOrderItems.isEmpty) {
      _showError('Aucun article dans la commande');
      return;
    }

    if (_selectedOrder == null) {
      _showError('Aucune commande active');
      return;
    }

    try {
      // Utiliser le ProductionService pour générer les bons formatés
      final productionService = ProductionService();
      final productionOrders = await productionService.generateProductionOrders(
        _selectedOrder!,
        _currentOrderItems,
        _menuItems,
      );

      // Envoyer chaque bon à son imprimante correspondante
      for (final entry in productionOrders.entries) {
        final printerId = entry.key;
        final productionOrder = entry.value;
        
        debugPrint('=== BON POUR IMPRIMANTE: $printerId ===');
        debugPrint(productionOrder);
        debugPrint('=== FIN DU BON ===');
        
        // TODO: Ici, vous pourrez ajouter l'envoi réel vers l'imprimante
        // via le service d'impression réseau ou USB
      }

      _showSuccess('Bons envoyés aux imprimantes');
    } catch (e) {
      _showError('Erreur lors de l\'envoi des bons: $e');
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

    // Navigate to bill screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillScreen(order: _selectedOrder!),
      ),
    );

    if (result == true) {
      // Order was closed successfully
      setState(() {
        _selectedOrder = null;
        _currentOrderItems.clear();
      });
      _showSuccess('Commande fermée - Facture créée en attente à la caisse');
    }
  }

  Future<void> _removeItemFromOrder(OrderItem orderItem) async {
    try {
      if (orderItem.id != null) {
        // Remove from database
        await _dbService.deleteOrderItem(orderItem.id!);
      }
      
      // Remove from local list
      setState(() {
        _currentOrderItems.removeWhere((item) => item.id == orderItem.id);
      });
      
      _showSuccess('Article supprimé de la commande');
    } catch (e) {
      _showError('Erreur lors de la suppression: $e');
    }
  }

  Future<void> _increaseItemQuantity(OrderItem orderItem) async {
    try {
      final newQuantity = orderItem.quantity + 1;
      final updatedItem = orderItem.copyWith(quantity: newQuantity);
      
      if (orderItem.id != null) {
        // Update in database
        await _dbService.updateOrderItem(updatedItem);
      }
      
      // Update local list
      setState(() {
        final index = _currentOrderItems.indexWhere((item) => item.id == orderItem.id);
        if (index != -1) {
          _currentOrderItems[index] = updatedItem;
        }
      });
    } catch (e) {
      _showError('Erreur lors de la modification: $e');
    }
  }

  Future<void> _decreaseItemQuantity(OrderItem orderItem) async {
    try {
      if (orderItem.quantity <= 1) {
        // If quantity is 1, remove the item completely
        await _removeItemFromOrder(orderItem);
        return;
      }
      
      final newQuantity = orderItem.quantity - 1;
      final updatedItem = orderItem.copyWith(quantity: newQuantity);
      
      if (orderItem.id != null) {
        // Update in database
        await _dbService.updateOrderItem(updatedItem);
      }
      
      // Update local list
      setState(() {
        final index = _currentOrderItems.indexWhere((item) => item.id == orderItem.id);
        if (index != -1) {
          _currentOrderItems[index] = updatedItem;
        }
      });
    } catch (e) {
      _showError('Erreur lors de la modification: $e');
    }
  }

  // Get categories with icons
  List<Map<String, dynamic>> _getCategoriesWithIcons() {
    final allCategories = _menuItems.map((item) => item.category).toSet().toList();
    
    // Ordre souhaité des catégories
    final categoryOrder = [
      'Boissons',
      'Entrées', 
      'Plats',
      'Desserts',
      'Menus préétablis'
    ];
    
    // Trier les catégories selon l'ordre souhaité
    final categories = <String>[];
    for (final orderedCategory in categoryOrder) {
      if (allCategories.contains(orderedCategory)) {
        categories.add(orderedCategory);
      }
    }
    
    // Ajouter les catégories non listées à la fin
    for (final category in allCategories) {
      if (!categories.contains(category)) {
        categories.add(category);
      }
    }
    
    return categories.map((category) {
      IconData icon;
      switch (category.toLowerCase()) {
        case 'entrées':
          icon = Icons.restaurant_menu;
          break;
        case 'plats':
          icon = Icons.restaurant;
          break;
        case 'desserts':
          icon = Icons.cake;
          break;
        case 'boissons':
          icon = Icons.local_drink;
          break;
        case 'menus préétablis':
          icon = Icons.set_meal;
          break;
        default:
          icon = Icons.fastfood;
      }
      
      return {
        'name': category,
        'icon': icon,
        'count': _menuItems.where((item) => item.category == category).length,
      };
    }).toList();
  }

  // Get subcategories for a category (niveau 2)
  List<String> _getSubcategories(String category) {
    if (category == 'Boissons') {
      // Pour les boissons, retourner les catégories de niveau 2
      return [
        'Boissons chaudes',
        'Boissons froides',
        'Bières',
        'Vins',
        'Cocktails',
        'Cocktails sans alcool',
        'Alcools',
        'Apéritifs',
        'Digestifs'
      ];
    }
    
    // Pour les autres catégories, utiliser la logique normale
    final items = _menuItems.where((item) => item.category == category).toList();
    final subcategories = items.map((item) => item.subcategory ?? 'Produit').toSet().toList();
    subcategories.sort();
    return subcategories;
  }

  // Get sub-subcategories for boissons (niveau 3)
  List<String> _getSubsubcategories(String category, String subcategory) {
    if (category == 'Boissons') {
      switch (subcategory) {
        case 'Boissons froides':
          return ['Sodas', 'Jus', 'Sirops', 'Autres'];
        case 'Bières':
          return ['Bière pression', 'Bière bouteille'];
        case 'Vins':
          return ['Vin rouge', 'Vin blanc', 'Vin rosé', 'Champagne'];
        case 'Cocktails':
          return ['Cocktail classique', 'Cocktail création'];
        case 'Cocktails sans alcool':
          return ['Cocktail classique sans alcool', 'Cocktail création sans alcool'];
        case 'Alcools':
          return ['Whiskies', 'Rhums', 'Gins', 'Autres alcools'];
        default:
          return []; // Boissons chaudes, Apéritifs, Digestifs n'ont pas de sous-sous-catégories
      }
    }
    return [];
  }

  // Get products for a category and subcategory (avec support niveau 3)
  List<MenuItem> _getProducts(String category, String subcategory, [String? subsubcategory]) {
    if (category == 'Boissons' && subsubcategory != null) {
      // Pour les boissons avec sous-sous-catégorie
      return _menuItems.where((item) => 
        item.category == category && (item.subcategory ?? 'Produit') == subsubcategory
      ).toList();
    } else if (category == 'Boissons') {
      // Pour les boissons sans sous-sous-catégorie (Boissons chaudes, Apéritifs, Digestifs)
      return _menuItems.where((item) => 
        item.category == category && (item.subcategory ?? 'Produit') == subcategory
      ).toList();
    } else {
      // Pour les autres catégories
      return _menuItems.where((item) => 
        item.category == category && (item.subcategory ?? 'Produit') == subcategory
      ).toList();
    }
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
                        onPressed: _promptTableSelection,
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
                        decoration: const BoxDecoration(
                          color: Color(0xFF2a2438),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFbfa14a), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
                              onPressed: _goBack,
                            ),
                            Expanded(
                              child: Text(
                                _getBreadcrumbText(),
                                style: const TextStyle(
                                  color: Color(0xFFbfa14a),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Main content
                    Expanded(
                      child: _buildCurrentView(),
                    ),
                    
                    // Order summary and actions
                    if (_currentOrderItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2a2438),
                          border: Border(
                            top: BorderSide(color: Color(0xFFbfa14a), width: 1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Commande en cours (${_currentOrderItems.length} articles)',
                              style: const TextStyle(
                                color: Color(0xFFbfa14a),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Order items list
                            Container(
                              height: 200,
                              child: ListView.builder(
                                itemCount: _currentOrderItems.length,
                                itemBuilder: (context, index) {
                                  final orderItem = _currentOrderItems[index];
                                  return Card(
                                    color: const Color(0xFF3a3448),
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        orderItem.name,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        'Qté: ${orderItem.quantity} × ${orderItem.priceTtc.toStringAsFixed(2)}€ = ${orderItem.totalTtc.toStringAsFixed(2)}€',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, color: Colors.orange),
                                            onPressed: () => _decreaseItemQuantity(orderItem),
                                            tooltip: 'Diminuer la quantité',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, color: Colors.green),
                                            onPressed: () => _increaseItemQuantity(orderItem),
                                            tooltip: 'Augmenter la quantité',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _removeItemFromOrder(orderItem),
                                            tooltip: 'Supprimer l\'article',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _printOrder,
                                    icon: const Icon(Icons.print),
                                    label: const Text('Envoyer les bons'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFbfa14a),
                                      foregroundColor: const Color(0xFF231f2b),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _closeOrder,
                                    icon: const Icon(Icons.check),
                                    label: const Text('Fermer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
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

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'categories':
        return _buildCategoriesView();
      case 'subcategories':
        return _buildSubcategoriesView();
      case 'subsubcategories':
        return _buildSubsubcategoriesView();
      case 'products':
        return _buildProductsView();
      default:
        return _buildCategoriesView();
    }
  }

  Widget _buildCategoriesView() {
    final categories = _getCategoriesWithIcons();
    
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
        return _CategoryCard(
          name: category['name'],
          icon: category['icon'],
          count: category['count'],
          onTap: () => _selectCategory(category['name']),
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
        final count = _getProducts(_selectedCategory, subcategory).length;
        
        return _SubcategoryCard(
          name: subcategory,
          count: count,
          onTap: () => _selectSubcategory(subcategory),
        );
      },
    );
  }

  Widget _buildSubsubcategoriesView() {
    final subsubcategories = _getSubsubcategories(_selectedCategory, _selectedSubcategory);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: subsubcategories.length,
      itemBuilder: (context, index) {
        final subsubcategory = subsubcategories[index];
        final count = _getProducts(_selectedCategory, _selectedSubcategory, subsubcategory).length;
        
        return _SubcategoryCard(
          name: subsubcategory,
          count: count,
          onTap: () => _selectSubsubcategory(subsubcategory),
        );
      },
    );
  }

  Widget _buildProductsView() {
    final products = _selectedSubsubcategory.isNotEmpty 
        ? _getProducts(_selectedCategory, _selectedSubcategory, _selectedSubsubcategory)
        : _getProducts(_selectedCategory, _selectedSubcategory);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          item: product,
          onTap: () => _addItemToOrder(product),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2a2438),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: const Color(0xFFbfa14a),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$count articles',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const _SubcategoryCard({
    required this.name,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2a2438),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fastfood,
                size: 48,
                color: Color(0xFFbfa14a),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$count articles',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const _ProductCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFfff8e1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: Color(0xFF231f2b),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${item.priceTtc.toStringAsFixed(2)}€',
                style: const TextStyle(
                  color: Color(0xFFbfa14a),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Color(0xFF231f2b),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/order_item.dart';
import '../models/order.dart';
import '../services/api_database_service.dart';
import '../utils/tva_utils.dart';

class SimpleOrdersScreen extends StatefulWidget {
  final int? tableId;
  final String? tableName;

  const SimpleOrdersScreen({
    this.tableId,
    this.tableName,
    super.key,
  });

  @override
  State<SimpleOrdersScreen> createState() => _SimpleOrdersScreenState();
}

class _SimpleOrdersScreenState extends State<SimpleOrdersScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  
  // Données
  List<MenuItem> _allMenuItems = [];
  List<MenuItem> _presetMenus = [];
  bool _isLoading = true;
  
  // Navigation state - same as guided menu creation
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  String? _selectedSubSubCategory;
  
  // Commande en cours
  final List<OrderItem> _currentOrderItems = [];
  double _totalPrice = 0.0;

  // Category structure - same as guided menu creation
  static const Map<String, Map<String, List<String>>> _categoryTree = {
    'Entrées': {
      'Entrée chaude': [],
      'Entrée froide': [],
    },
    'Plats': {
      'Viande': [],
      'Poisson': [],
      'Végétarien': [],
    },
    'Desserts': {
      'Dessert': [],
    },
    'Boissons': {
      'Boissons chaudes': [],
      'Boissons froides': [],
      'Vin': [],
      'Bière': [],
      'Apéritifs': [],
      'Digestifs': [],
      'Cocktails avec alcool': ['Classiques', 'Créations'],
      'Cocktails sans alcool': [],
      'Alcools': ['Whisky', 'Rhum', 'Gin', 'Vodka'],
    },
    'Menus préétablis': {
      'Menu': [],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final allItems = await _dbService.getRegularMenuItems();
      final presetMenus = await _dbService.getPresetMenus();
      
      setState(() {
        _allMenuItems = allItems;
        _presetMenus = presetMenus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement: $e');
    }
  }

  void _selectMainCategory(String category) {
    setState(() {
      _selectedMainCategory = category;
      _selectedSubCategory = null;
      _selectedSubSubCategory = null;
    });
  }

  void _selectSubCategory(String subCategory) {
    setState(() {
      _selectedSubCategory = subCategory;
      _selectedSubSubCategory = null;
    });
  }

  void _selectSubSubCategory(String subSubCategory) {
    setState(() {
      _selectedSubSubCategory = subSubCategory;
    });
  }

  void _goBack() {
    if (_selectedSubSubCategory != null) {
      setState(() {
        _selectedSubSubCategory = null;
      });
    } else if (_selectedSubCategory != null) {
      setState(() {
        _selectedSubCategory = null;
      });
    } else if (_selectedMainCategory != null) {
      setState(() {
        _selectedMainCategory = null;
      });
    }
  }

  List<MenuItem> get _filteredItems {
    if (_selectedMainCategory == 'Menus préétablis') {
      return _presetMenus;
    }
    
    if (_selectedMainCategory == null) {
      return [];
    }
    
    if (_selectedSubCategory == null) {
      // Show all items from main category
      return _allMenuItems.where((item) => 
        item.category.startsWith(_selectedMainCategory!) ||
        item.category == _selectedMainCategory
      ).toList();
    }
    
    if (_selectedSubSubCategory == null) {
      // Show items from sub-category
      final categoryFilter = '$_selectedMainCategory - $_selectedSubCategory';
      return _allMenuItems.where((item) => 
        item.category == categoryFilter ||
        item.category.startsWith(categoryFilter)
      ).toList();
    }
    
    // Show items from sub-sub-category
    final categoryFilter = '$_selectedMainCategory - $_selectedSubCategory - $_selectedSubSubCategory';
    return _allMenuItems.where((item) => 
      item.category == categoryFilter ||
      item.category.startsWith(categoryFilter)
    ).toList();
  }

  void _addToOrder(MenuItem item) {
    setState(() {
      // Vérifier si l'élément est déjà dans la commande
      final existingIndex = _currentOrderItems.indexWhere((orderItem) => orderItem.menuItemId == item.id);
      
      if (existingIndex != -1) {
        // Incrémenter la quantité
        final existingItem = _currentOrderItems[existingIndex];
        final newQuantity = existingItem.quantity + 1;
        final newTotalHt = item.priceHt * newQuantity;
        final newTotalTtc = item.priceTtc * newQuantity;
        final newTotalTva = TvaUtils.calculateTvaAmount(item.priceHt, item.tvaRate) * newQuantity;
        
        _currentOrderItems[existingIndex] = existingItem.copyWith(
          quantity: newQuantity,
          totalHt: newTotalHt,
          totalTtc: newTotalTtc,
          totalTva: newTotalTva,
        );
      } else {
        // Ajouter un nouvel élément
        final orderItem = OrderItem.fromMenuItem(
          item.id!,
          item.name,
          item.priceHt,
          item.priceTtc,
          item.tvaRate,
          1,
          orderId: null, // Temporary item, no orderId yet
        );
        _currentOrderItems.add(orderItem);
      }
      
      _calculateTotal();
    });
    
    _showSuccess('${item.name} ajouté à la commande');
  }

  void _removeFromOrder(int index) {
    setState(() {
      _currentOrderItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromOrder(index);
      return;
    }
    
    setState(() {
      final item = _currentOrderItems[index];
      final newTotalHt = item.priceHt * newQuantity;
      final newTotalTtc = item.priceTtc * newQuantity;
      final newTotalTva = TvaUtils.calculateTvaAmount(item.priceHt, item.tvaRate) * newQuantity;
      
      _currentOrderItems[index] = item.copyWith(
        quantity: newQuantity,
        totalHt: newTotalHt,
        totalTtc: newTotalTtc,
        totalTva: newTotalTva,
      );
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalPrice = _currentOrderItems.fold(0.0, (sum, item) => sum + item.totalTtc);
  }

  void _clearOrder() {
    setState(() {
      _currentOrderItems.clear();
      _totalPrice = 0.0;
    });
  }

  Future<void> _submitOrder() async {
    if (_currentOrderItems.isEmpty) {
      _showError('La commande est vide');
      return;
    }

    if (widget.tableId == null) {
      _showError('Erreur: ID de table manquant');
      return;
    }

    try {
      // Créer la commande sans les éléments
      final order = Order.fromItems(
        id: null,
        tableId: widget.tableId!, // Use non-null assertion since we checked above
        items: [], // Empty items for now
        status: 'En cours',
        createdAt: DateTime.now(),
      );

      final orderId = await _dbService.insertOrder(order);

      // Ajouter les éléments de la commande
      for (var orderItem in _currentOrderItems) {
        // Set the order ID for each item
        final itemWithOrderId = OrderItem.fromMenuItem(
          orderItem.menuItemId,
          orderItem.name,
          orderItem.priceHt,
          orderItem.priceTtc,
          orderItem.tvaRate,
          orderItem.quantity,
          orderId: orderId,
        );
        await _dbService.insertOrderItem(itemWithOrderId);
      }

      // Générer les tickets pour le bar/cuisine
      await _generateTickets(orderId);

      _showSuccess('Commande envoyée avec succès');
      _clearOrder();
      
      // Retourner à l'écran précédent
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Erreur lors de l\'envoi de la commande: $e');
    }
  }

  Future<void> _generateTickets(int orderId) async {
    try {
      // Grouper les éléments par imprimante
      final Map<int?, List<OrderItem>> itemsByPrinter = {};
      
      for (var item in _currentOrderItems) {
        final menuItem = _allMenuItems.firstWhere((m) => m.id == item.menuItemId);
        final printerId = menuItem.printerId;
        
        if (!itemsByPrinter.containsKey(printerId)) {
          itemsByPrinter[printerId] = [];
        }
        itemsByPrinter[printerId]!.add(item);
      }

      // Générer un ticket pour chaque imprimante
      for (var entry in itemsByPrinter.entries) {
        final printerId = entry.key;
        final items = entry.value;
        
        if (items.isNotEmpty) {
          // Ici, vous pouvez implémenter la logique d'impression
          // Pour l'instant, on affiche juste un message
          print('Ticket pour imprimante $printerId:');
          for (var item in items) {
            print('- ${item.quantity}x ${item.name}');
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la génération des tickets: $e');
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

  Widget _buildMainCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Choisissez une catégorie',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFbfa14a),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _categoryTree.length,
            itemBuilder: (context, index) {
              final category = _categoryTree.keys.elementAt(index);
              final icon = _getCategoryIcon(category);
              
              return Card(
                color: const Color(0xFF2a2a3a),
                child: InkWell(
                  onTap: () => _selectMainCategory(category),
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
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategorySelector() {
    final subCategories = _categoryTree[_selectedMainCategory]!.keys.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
                onPressed: _goBack,
              ),
              Expanded(
                child: Text(
                  '$_selectedMainCategory : Choisissez un sous-type',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFbfa14a),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final subCategory = subCategories[index];
              final hasSubSubCategories = _categoryTree[_selectedMainCategory]![subCategory]!.isNotEmpty;
              
              return Card(
                color: const Color(0xFF2a2a3a),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    hasSubSubCategories ? Icons.folder : Icons.restaurant,
                    color: const Color(0xFFbfa14a),
                    size: 32,
                  ),
                  title: Text(
                    subCategory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: hasSubSubCategories 
                    ? Text(
                        '${_categoryTree[_selectedMainCategory]![subCategory]!.length} sous-catégories',
                        style: const TextStyle(color: Colors.white70),
                      )
                    : null,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFbfa14a),
                  ),
                  onTap: () => _selectSubCategory(subCategory),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubSubCategorySelector() {
    final subSubCategories = _categoryTree[_selectedMainCategory]![_selectedSubCategory]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
                onPressed: _goBack,
              ),
              Expanded(
                child: Text(
                  '$_selectedMainCategory > $_selectedSubCategory : Choisissez un sous-type',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFbfa14a),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subSubCategories.length,
            itemBuilder: (context, index) {
              final subSubCategory = subSubCategories[index];
              
              return Card(
                color: const Color(0xFF2a2a3a),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(
                    Icons.restaurant,
                    color: Color(0xFFbfa14a),
                    size: 32,
                  ),
                  title: Text(
                    subSubCategory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFbfa14a),
                  ),
                  onTap: () => _selectSubSubCategory(subSubCategory),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF2a2a3a),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
                onPressed: _goBack,
              ),
              Expanded(
                child: Text(
                  _getCurrentCategoryPath(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFbfa14a),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Products grid
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedMainCategory == 'Menus préétablis' 
                          ? Icons.restaurant_menu 
                          : Icons.restaurant,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun produit dans cette catégorie',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return Card(
                      color: const Color(0xFF2a2a3a),
                      child: InkWell(
                        onTap: () => _addToOrder(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${item.priceTtc.toStringAsFixed(2)} € TTC',
                                style: const TextStyle(
                                  color: Color(0xFFbfa14a),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getCurrentCategoryPath() {
    if (_selectedSubSubCategory != null) {
      return '$_selectedMainCategory > $_selectedSubCategory > $_selectedSubSubCategory';
    } else if (_selectedSubCategory != null) {
      return '$_selectedMainCategory > $_selectedSubCategory';
    } else {
      return _selectedMainCategory!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Entrées':
        return Icons.restaurant;
      case 'Plats':
        return Icons.dinner_dining;
      case 'Desserts':
        return Icons.cake;
      case 'Boissons':
        return Icons.local_drink;
      case 'Menus préétablis':
        return Icons.restaurant_menu;
      default:
        return Icons.restaurant_menu;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_selectedMainCategory == null) {
      content = _buildMainCategorySelector();
    } else if (_selectedSubCategory == null) {
      content = _buildSubCategorySelector();
    } else if (_categoryTree[_selectedMainCategory]![_selectedSubCategory]!.isNotEmpty && _selectedSubSubCategory == null) {
      content = _buildSubSubCategorySelector();
    } else {
      content = _buildProductGrid();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: Text(
          'Commande - ${widget.tableName ?? 'Table'}',
          style: const TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_currentOrderItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFFbfa14a)),
              onPressed: _clearOrder,
              tooltip: 'Vider la commande',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFbfa14a),
              ),
            )
          : Column(
              children: [
                // Current order summary
                if (_currentOrderItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF2a2a3a),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Commande en cours (${_currentOrderItems.length} articles)',
                              style: const TextStyle(
                                color: Color(0xFFbfa14a),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total: ${_totalPrice.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                color: Color(0xFFbfa14a),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _currentOrderItems.length,
                            itemBuilder: (context, index) {
                              final item = _currentOrderItems[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFbfa14a),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.quantity}x ${item.name}',
                                      style: const TextStyle(
                                        color: Color(0xFF231f2b),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      onPressed: () => _removeFromOrder(index),
                                      color: const Color(0xFF231f2b),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFbfa14a),
                              foregroundColor: const Color(0xFF231f2b),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Envoyer la commande',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Main content area
                Expanded(child: content),
              ],
            ),
    );
  }
} 
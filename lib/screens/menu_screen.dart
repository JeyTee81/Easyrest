import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/printer.dart';
import '../services/api_database_service.dart';
import 'guided_menu_creation_screen.dart';
import 'preset_menus_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<MenuItem> _menuItems = [];
  List<Printer> _printers = [];
  bool _isLoading = true;
  bool _dbError = false;
  String? _dbErrorMsg;
  
  // Navigation state
  String _currentView = 'categories'; // 'categories', 'subcategories', 'subsubcategories', 'products'
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  String _selectedSubsubcategory = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final menuItems = await _dbService.getMenuItems();
      final printers = await _dbService.getPrinters();
      setState(() {
        _menuItems = menuItems;
        _printers = printers;
        _isLoading = false;
        _dbError = false;
        _dbErrorMsg = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _dbError = true;
        _dbErrorMsg = ApiDatabaseService.getLastDatabaseError() ?? e.toString();
      });
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
      _selectedSubsubcategory = '';
      
      // Vérifier s'il y a des sous-sous-catégories
      final subsubcategories = _getSubsubcategories(_selectedCategory, subcategory);
      if (subsubcategories.isNotEmpty) {
        _currentView = 'subsubcategories';
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
        // Retourner au niveau précédent
        final subsubcategories = _getSubsubcategories(_selectedCategory, _selectedSubcategory);
        if (subsubcategories.isNotEmpty) {
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

  // Get current page title
  String _getCurrentTitle() {
    switch (_currentView) {
      case 'categories':
        return 'Menu';
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
        return 'Menu';
    }
  }

  // Get categories with icons and counts
  List<Map<String, dynamic>> _getCategoriesWithIcons() {
    final categories = _menuItems.map((item) => item.category).toSet().toList();
    categories.sort();
    
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
        item.category == category && 
        item.subcategory == subcategory &&
        item.type == subsubcategory
      ).toList();
    } else {
      // Pour les autres cas
      return _menuItems.where((item) => 
        item.category == category && 
        (item.subcategory == subcategory || item.type == subcategory)
      ).toList();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _navigateToGuidedCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GuidedMenuCreationScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // Refresh the menu items
        _showSuccess('Produit ajouté avec succès');
      }
    });
  }

  void _navigateToPresetMenus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PresetMenusScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // Refresh the menu items
      }
    });
  }

  Future<void> _editMenuItem(MenuItem item) async {
    // For editing, we'll use a simplified dialog since the guided creation is for new items
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.priceTtc.toString());
    final descriptionController = TextEditingController(text: item.description);
    String selectedCategory = item.category;
    String selectedType = item.type;
    String selectedTvaRate = item.tvaRate;
    Printer? selectedPrinter;
    
    if (item.printer.isNotEmpty) {
      try {
        selectedPrinter = _printers.firstWhere((p) => p.name == item.printer);
      } catch (e) {
        selectedPrinter = null;
      }
    } else if (_printers.isNotEmpty) {
      selectedPrinter = _printers.first;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'élément'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Prix TTC'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  filled: true,
                  fillColor: Color(0xFFfff8e1),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFFfff8e1),
                style: const TextStyle(color: Color(0xFF231f2b)),
                items: ['Plats', 'Boissons', 'Desserts', 'Entrées'].map((cat) {
                  return DropdownMenuItem(
                    value: cat, 
                    child: Text(
                      cat,
                      style: const TextStyle(color: Color(0xFF231f2b)),
                    )
                  );
                }).toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  filled: true,
                  fillColor: Color(0xFFfff8e1),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFFfff8e1),
                style: const TextStyle(color: Color(0xFF231f2b)),
                items: ['Principal', 'Accompagnement', 'Dessert', 'Boisson'].map((type) {
                  return DropdownMenuItem(
                    value: type, 
                    child: Text(
                      type,
                      style: const TextStyle(color: Color(0xFF231f2b)),
                    )
                  );
                }).toList(),
                onChanged: (value) => selectedType = value!,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedTvaRate,
                decoration: const InputDecoration(
                  labelText: 'Taux de TVA',
                  filled: true,
                  fillColor: Color(0xFFfff8e1),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFFfff8e1),
                style: const TextStyle(color: Color(0xFF231f2b)),
                items: ['5.5%', '10%', '20%'].map((rate) {
                  return DropdownMenuItem(
                    value: rate, 
                    child: Text(
                      rate,
                      style: const TextStyle(color: Color(0xFF231f2b)),
                    )
                  );
                }).toList(),
                onChanged: (value) => selectedTvaRate = value!,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Printer?>(
                value: selectedPrinter,
                decoration: const InputDecoration(
                  labelText: 'Imprimante (optionnel)',
                  filled: true,
                  fillColor: Color(0xFFfff8e1),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFFfff8e1),
                style: const TextStyle(color: Color(0xFF231f2b)),
                items: [
                  const DropdownMenuItem<Printer?>(
                    value: null,
                    child: Text('Aucune'),
                  ),
                  ..._printers.map((printer) => DropdownMenuItem<Printer?>(
                    value: printer,
                    child: Text(printer.name),
                  )),
                ],
                onChanged: (value) => selectedPrinter = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              if (price == null || price < 0) {
                _showError('Prix invalide');
                return;
              }

              final updatedItem = item.copyWith(
                name: nameController.text.trim(),
                priceTtc: price,
                description: descriptionController.text.trim(),
                category: selectedCategory,
                type: selectedType,
                tvaRate: selectedTvaRate,
                printer: selectedPrinter?.name ?? 'cuisine',
              );

              try {
                await _dbService.updateMenuItem(updatedItem);
                Navigator.pop(context, true);
                _loadData();
                _showSuccess('Élément modifié avec succès');
              } catch (e) {
                _showError('Erreur lors de la modification: $e');
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${item.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbService.deleteMenuItem(item.id!);
        _loadData();
        _showSuccess('Élément supprimé avec succès');
      } catch (e) {
        _showError('Erreur lors de la suppression: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        elevation: 0,
        title: Text(
          _getCurrentTitle(),
          style: const TextStyle(color: Color(0xFFbfa14a)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_currentView != 'categories')
            IconButton(
              icon: const Icon(Icons.home, color: Color(0xFFbfa14a)),
              onPressed: _goToCategories,
              tooltip: 'Retour aux catégories',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : _dbError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Erreur de base de données',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _dbErrorMsg ?? 'Erreur inconnue',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
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
                                _currentView == 'subcategories' 
                                    ? _selectedCategory
                                    : '$_selectedCategory > $_selectedSubcategory',
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
                  ],
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'preset_menus',
            onPressed: _navigateToPresetMenus,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.restaurant_menu),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_item',
            onPressed: _navigateToGuidedCreation,
            backgroundColor: const Color(0xFFbfa14a),
            child: const Icon(Icons.add),
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
    
    if (categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Color(0xFFbfa14a),
            ),
            SizedBox(height: 16),
            Text(
              'Aucune catégorie dans le menu',
              style: TextStyle(
                color: Color(0xFFbfa14a),
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ajoutez votre premier élément',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    
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
    
    if (subcategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fastfood,
              size: 64,
              color: Color(0xFFbfa14a),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun type dans $_selectedCategory',
              style: const TextStyle(
                color: Color(0xFFbfa14a),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des éléments à cette catégorie',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    
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
    
    if (subsubcategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.category,
              size: 64,
              color: Color(0xFFbfa14a),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune sous-catégorie dans $_selectedSubcategory',
              style: const TextStyle(
                color: Color(0xFFbfa14a),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des éléments à cette catégorie',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    
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
    final products = _getProducts(_selectedCategory, _selectedSubcategory, _selectedSubsubcategory.isNotEmpty ? _selectedSubsubcategory : null);
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant,
              size: 64,
              color: Color(0xFFbfa14a),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit dans $_selectedSubcategory',
              style: const TextStyle(
                color: Color(0xFFbfa14a),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des produits à ce type',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          color: const Color(0xFF2a2438),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.description.isNotEmpty)
                  Text(
                    product.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFbfa14a),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: Color(0xFF231f2b),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.tvaRate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product.priceTtc.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    color: Color(0xFFbfa14a),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editMenuItem(product);
                        break;
                      case 'delete':
                        _deleteMenuItem(product);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Modifier'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                '$count éléments',
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
                '$count éléments',
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
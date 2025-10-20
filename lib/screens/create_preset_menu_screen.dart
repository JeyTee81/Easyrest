import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/api_database_service.dart';

class CreatePresetMenuScreen extends StatefulWidget {
  final MenuItem? menuToEdit;

  const CreatePresetMenuScreen({this.menuToEdit, super.key});

  @override
  State<CreatePresetMenuScreen> createState() => _CreatePresetMenuScreenState();
}

class _CreatePresetMenuScreenState extends State<CreatePresetMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final Map<String, List<MenuItem>> _selectedItems = {
    'Entrée': [],
    'Plat': [],
    'Dessert': [],
    'Boisson': [],
  };

  List<MenuItem> _allMenuItems = [];
  bool _isLoading = true;
  final Map<String, MenuItem?> _selectedDropdownValues = {
    'Entrée': null,
    'Plat': null,
    'Dessert': null,
    'Boisson': null,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.menuToEdit != null) {
      _nameController.text = widget.menuToEdit!.name;
      _descriptionController.text = widget.menuToEdit!.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final allItems = await ApiDatabaseService().getRegularMenuItems();
      setState(() {
        _allMenuItems = allItems;
        _isLoading = false;
      });

      if (widget.menuToEdit != null) {
        await _loadMenuComposition();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement: $e');
    }
  }

  Future<void> _loadMenuComposition() async {
    try {
      final composition = await ApiDatabaseService().getPresetMenuComposition(widget.menuToEdit!.id!);
      setState(() {
        for (var entry in composition.entries) {
          _selectedItems[entry.key] = entry.value;
        }
      });
    } catch (e) {
      _showError('Erreur lors du chargement de la composition: $e');
    }
  }

  void _addItemToCategory(MenuItem item, String category) {
    setState(() {
      _selectedItems[category]!.add(item);
    });
  }

  void _showItemSelectionDialog(String category, List<MenuItem> availableItems) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a3a),
          title: Text(
            'Sélectionner un élément pour $category',
            style: const TextStyle(color: Color(0xFFbfa14a)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableItems.length,
              itemBuilder: (context, index) {
                final item = availableItems[index];
                return ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${item.priceTtc.toStringAsFixed(2)}€',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    _addItemToCategory(item, category);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFFbfa14a))),
            ),
          ],
        );
      },
    );
  }

  void _removeItemFromCategory(MenuItem item, String category) {
    setState(() {
      _selectedItems[category]!.removeWhere((i) => i.id == item.id);
    });
  }

  double _calculateTotalPrice() {
    double total = 0;
    for (var items in _selectedItems.values) {
      for (var item in items) {
        total += item.priceTtc;
      }
    }
    return total;
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
      ),
    );
  }

  Future<void> _saveMenu() async {
    if (_formKey.currentState!.validate()) {
      try {
        final totalItems = _selectedItems.values
            .expand((list) => list)
            .length;
        
        if (totalItems == 0) {
          _showError('Veuillez sélectionner au moins un élément');
          return;
        }

        final totalPrice = _calculateTotalPrice();

        if (widget.menuToEdit != null) {
          if (widget.menuToEdit?.id == null) {
            _showError('Impossible de modifier ce menu (ID manquant)');
            return;
          }
          // Modification d'un menu existant
          final updatedMenu = widget.menuToEdit!.copyWith(
            name: _nameController.text.trim(),
            priceTtc: totalPrice,
            description: _descriptionController.text.trim(),
          );
          
          await ApiDatabaseService().updatePresetMenu(updatedMenu);
          
          // Supprimer tous les éléments existants
          await ApiDatabaseService().clearPresetMenuComposition(widget.menuToEdit!.id!);
          
          // Ajouter les nouveaux éléments sélectionnés
          for (var entry in _selectedItems.entries) {
            for (var item in entry.value) {
              await ApiDatabaseService().addItemToPresetMenu(
                presetMenuId: widget.menuToEdit!.id!,
                menuItemId: item.id!,
                group: entry.key,
              );
            }
          }
          
          _showSuccess('Menu préétabli modifié avec succès');
        } else {
          // Création d'un nouveau menu
          final menu = MenuItem.presetMenu(
            name: _nameController.text.trim(),
            priceTtc: totalPrice,
            description: _descriptionController.text.trim(),
          );
          
          final menuId = await ApiDatabaseService().insertPresetMenu(menu);
          
          // Ajouter les éléments sélectionnés au menu
          for (var entry in _selectedItems.entries) {
            for (var item in entry.value) {
              await ApiDatabaseService().addItemToPresetMenu(
                presetMenuId: menuId,
                menuItemId: item.id!,
                group: entry.key,
              );
            }
          }
          
          _showSuccess('Menu préétabli créé avec succès');
        }
        
        Navigator.pop(context, true);
      } catch (e) {
        _showError('Erreur lors de la sauvegarde: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotalPrice();
    final isEditing = widget.menuToEdit != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: Text(
          isEditing ? 'Modifier le menu préétabli' : 'Créer un menu préétabli',
          style: const TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFbfa14a)),
            onPressed: _saveMenu,
            tooltip: 'Sauvegarder',
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
                // Informations du menu
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom du menu',
                            labelStyle: TextStyle(color: Color(0xFFbfa14a)),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFbfa14a)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFbfa14a), width: 2),
                            ),
                            filled: true,
                            fillColor: Color(0xFF2a2a3a),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le nom est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (optionnel)',
                            labelStyle: TextStyle(color: Color(0xFFbfa14a)),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFbfa14a)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFbfa14a), width: 2),
                            ),
                            filled: true,
                            fillColor: Color(0xFF2a2a3a),
                          ),
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFbfa14a).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFbfa14a)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Color(0xFFbfa14a)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Prix total calculé automatiquement: ${totalPrice.toStringAsFixed(2)}€ TTC',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFbfa14a),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Sélection des éléments
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: ApiDatabaseService.presetMenuGroups.map((category) {
                      final selectedItemIds = _selectedItems.values
                          .expand((list) => list)
                          .map((item) => item.id)
                          .toSet();
                      
                      final availableItems = _allMenuItems
                          .where((item) => !selectedItemIds.contains(item.id))
                          .toList();
                      
                      // Remove duplicates by ID
                      final uniqueItems = <int, MenuItem>{};
                      for (final item in availableItems) {
                        if (item.id != null) {
                          uniqueItems[item.id!] = item;
                        }
                      }
                      final finalAvailableItems = uniqueItems.values.toList();
                      
                      return Card(
                        color: const Color(0xFF2a2a3a),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(category),
                                    color: const Color(0xFFbfa14a),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFbfa14a),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (finalAvailableItems.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => _showItemSelectionDialog(category, finalAvailableItems),
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text('Ajouter un élément', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFbfa14a),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              if ((_selectedItems[category] ?? []).isNotEmpty) ...[
                                const Text(
                                  'Éléments sélectionnés:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: (_selectedItems[category] ?? []).where((item) => item != null).map((item) => Chip(
                                    label: Text(
                                      '${item.name} (${item.priceTtc.toStringAsFixed(2)}€)',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: const Color(0xFFbfa14a),
                                    deleteIcon: const Icon(Icons.close, color: Colors.white),
                                    onDeleted: () => _removeItemFromCategory(item, category),
                                  )).toList(),
                                ),
                              ] else ...[
                                const Text(
                                  'Aucun élément sélectionné',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveMenu,
        backgroundColor: const Color(0xFFbfa14a),
        foregroundColor: const Color(0xFF231f2b),
        icon: const Icon(Icons.save),
        label: Text(isEditing ? 'Modifier' : 'Créer'),
      ),
    );
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
      default:
        return Icons.restaurant_menu;
    }
  }
} 
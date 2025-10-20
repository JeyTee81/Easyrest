import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/printer.dart';
import '../services/api_database_service.dart';

class PrinterConfigScreen extends StatefulWidget {
  const PrinterConfigScreen({super.key});

  @override
  State<PrinterConfigScreen> createState() => _PrinterConfigScreenState();
}

class _PrinterConfigScreenState extends State<PrinterConfigScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final menuItems = await _dbService.getMenuItems();
      setState(() {
        _menuItems = menuItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des produits: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProductPrinter(MenuItem menuItem, String newPrinter) async {
    try {
      final updatedMenuItem = menuItem.copyWith(printer: newPrinter);
      await _dbService.updateMenuItem(updatedMenuItem);
      
      setState(() {
        final index = _menuItems.indexWhere((item) => item.id == menuItem.id);
        if (index != -1) {
          _menuItems[index] = updatedMenuItem;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imprimante mise à jour pour ${menuItem.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        title: const Text(
          'Configuration des Imprimantes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFbfa14a),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFbfa14a)),
              ),
            )
          : _error != null
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
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMenuItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFbfa14a),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // En-tête avec informations
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.print,
                            size: 48,
                            color: Color(0xFFbfa14a),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Configuration des Imprimantes par Produit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF231f2b),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Configurez l\'imprimante de destination pour chaque produit. Les bons de production seront automatiquement envoyés aux bonnes imprimantes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Liste des imprimantes disponibles
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFFfff8e1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Imprimantes disponibles:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF231f2b),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: Printer.defaultPrinters.map((printer) {
                              return Chip(
                                label: Text(
                                  '${printer.name} (${printer.location})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: const Color(0xFFbfa14a).withOpacity(0.2),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF231f2b),
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Liste des produits
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _menuItems.length,
                        itemBuilder: (context, index) {
                          final menuItem = _menuItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFbfa14a).withOpacity(0.2),
                                child: Icon(
                                  _getCategoryIcon(menuItem.category),
                                  color: const Color(0xFFbfa14a),
                                ),
                              ),
                              title: Text(
                                menuItem.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Catégorie: ${menuItem.category}'),
                                  Text('Prix: ${menuItem.priceTtc.toStringAsFixed(2)}€'),
                                ],
                              ),
                              trailing: DropdownButton<String>(
                                value: menuItem.printer,
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue != menuItem.printer) {
                                    _updateProductPrinter(menuItem, newValue);
                                  }
                                },
                                items: Printer.defaultPrinters.map((printer) {
                                  return DropdownMenuItem<String>(
                                    value: printer.name,
                                    child: Text(
                                      printer.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFbfa14a),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'boissons':
        return Icons.local_drink;
      case 'entrées':
        return Icons.restaurant;
      case 'desserts':
        return Icons.cake;
      case 'plats':
      case 'plats principaux':
        return Icons.dinner_dining;
      case 'menus':
      case 'menus préétablis':
        return Icons.menu_book;
      default:
        return Icons.fastfood;
    }
  }
}









import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_database_service.dart';
// Pour DatabaseErrorScreen

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _dbError = false;
  String? _dbErrorMsg;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _dbService.getProducts();
      setState(() {
        _products = products;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showAddEditDialog([Product? product]) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    final minQuantityController = TextEditingController(text: product?.minQuantity.toString() ?? '');
    final unitController = TextEditingController(text: product?.unit ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du produit'),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantité actuelle'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: minQuantityController,
                decoration: const InputDecoration(labelText: 'Quantité minimale'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unité (kg, l, pièces)'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                final minQuantity = int.tryParse(minQuantityController.text) ?? 0;
                
                if (nameController.text.isEmpty) {
                  _showError('Le nom est requis');
                  return;
                }

                final newProduct = Product.withPriceTtc(
                  id: product?.id,
                  name: nameController.text,
                  quantity: quantity,
                  minQuantity: minQuantity,
                  unit: unitController.text,
                  description: descriptionController.text,
                  priceTtc: 0.0, // Default price for stock items
                  tvaRate: '10%', // Default TVA rate
                );

                if (isEditing) {
                  await _dbService.updateProduct(newProduct);
                } else {
                  await _dbService.insertProduct(newProduct);
                }

                Navigator.pop(context);
                _loadData();
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            child: Text(isEditing ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(Product product) {
    final quantityController = TextEditingController(text: product.quantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier la quantité de ${product.name}'),
        content: TextField(
          controller: quantityController,
          decoration: const InputDecoration(labelText: 'Nouvelle quantité'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newQuantity = int.tryParse(quantityController.text) ?? 0;
                final updatedProduct = Product.withPriceTtc(
                  id: product.id,
                  name: product.name,
                  quantity: newQuantity,
                  minQuantity: product.minQuantity,
                  unit: product.unit,
                  description: product.description,
                  priceTtc: 0.0, // Default price for stock items
                  tvaRate: '10%', // Default TVA rate
                );
                await _dbService.updateProduct(updatedProduct);
                Navigator.pop(context);
                _loadData();
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dbError) {
      return Scaffold(
        backgroundColor: const Color(0xFF231f2b),
        appBar: AppBar(
          backgroundColor: const Color(0xFF231f2b),
          title: const Text('Erreur base de données', style: TextStyle(color: Color(0xFFbfa14a))),
          iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Impossible d\'accéder à la base de données.', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Détail technique :', style: TextStyle(color: Color(0xFFbfa14a), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SelectableText(_dbErrorMsg ?? 'Erreur inconnue', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 24),
                const Text('Conseils :', style: TextStyle(color: Color(0xFFbfa14a), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('- Vérifiez que la tablette a assez d\'espace de stockage.', style: TextStyle(color: Colors.white)),
                const Text('- Vérifiez les permissions de stockage de l\'application.', style: TextStyle(color: Colors.white)),
                const Text('- Essayez de désinstaller/réinstaller l\'application.', style: TextStyle(color: Colors.white)),
                const Text('- Redémarrez la tablette.', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 24),
                const Text('Envoyez ce message à votre support technique pour diagnostic.', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        elevation: 0,
        title: const Text(
          'Gestion du Stock',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory, size: 64, color: Color(0xFFbfa14a)),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun produit en stock',
                        style: TextStyle(color: Color(0xFFbfa14a), fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddEditDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFbfa14a),
                          foregroundColor: const Color(0xFF231f2b),
                        ),
                        child: const Text('Ajouter un produit'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final isLowStock = product.quantity <= product.minQuantity;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isLowStock ? Colors.red.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLowStock ? Colors.red : const Color(0xFFbfa14a),
                          child: Icon(
                            isLowStock ? Icons.warning : Icons.inventory,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${product.quantity} ${product.unit}'),
                            if (product.description.isNotEmpty) Text(product.description),
                            if (isLowStock)
                              const Text(
                                'Stock faible !',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showQuantityDialog(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteProduct(product),
                            ),
                          ],
                        ),
                        onTap: () => _showAddEditDialog(product),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditDialog,
        backgroundColor: const Color(0xFFbfa14a),
        foregroundColor: const Color(0xFF231f2b),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbService.deleteProduct(product.id!);
                Navigator.pop(context);
                _loadData();
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
} 
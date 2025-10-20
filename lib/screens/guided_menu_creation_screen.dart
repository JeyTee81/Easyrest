import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/api_database_service.dart';
import '../utils/tva_utils.dart';

class GuidedMenuCreationScreen extends StatefulWidget {
  final MenuItem? menuItemToEdit;

  const GuidedMenuCreationScreen({this.menuItemToEdit, super.key});

  @override
  State<GuidedMenuCreationScreen> createState() => _GuidedMenuCreationScreenState();
}

class _GuidedMenuCreationScreenState extends State<GuidedMenuCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  // Navigation state
  String? _mainCategory;
  String? _subCategory;
  String? _subSubCategory;
  
  bool _isLoading = false;
  String? _errorMessage;

  // Category definitions
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
      'Dessert': [], // No sub-categories
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
  };

  @override
  void initState() {
    super.initState();
    if (widget.menuItemToEdit != null) {
      _nameController.text = widget.menuItemToEdit!.name;
      _descriptionController.text = widget.menuItemToEdit!.description;
      _priceController.text = widget.menuItemToEdit!.priceTtc.toString();
      
      // Try to determine category from existing item
      _mainCategory = widget.menuItemToEdit!.category;
      // You might want to add logic to determine sub-categories from existing data
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _resetToMain() {
    setState(() {
      _mainCategory = null;
      _subCategory = null;
      _subSubCategory = null;
    });
  }

  void _resetToSub() {
    setState(() {
      _subCategory = null;
      _subSubCategory = null;
    });
  }

  void _resetToSubSub() {
    setState(() {
      _subSubCategory = null;
    });
  }

  String _getCategoryLabel() {
    if (_mainCategory == null) return '';
    if (_subCategory == null) return _mainCategory!;
    if (_subSubCategory == null) return '$_mainCategory > $_subCategory';
    return '$_mainCategory > $_subCategory > $_subSubCategory';
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mainCategory == null) {
      setState(() { _errorMessage = 'Veuillez choisir une catégorie.'; });
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final price = double.parse(_priceController.text.replaceAll(',', '.'));
      final category = _getCategoryLabel();
      final menuItem = MenuItem.withPriceTtc(
        id: widget.menuItemToEdit?.id,
        name: _nameController.text.trim(),
        priceTtc: price,
        tvaRate: TvaUtils.getDefaultTvaRate(),
        description: _descriptionController.text.trim(),
        category: category,
        type: _mainCategory!,
        isAvailable: true,
      );
      final dbService = ApiDatabaseService();
      if (widget.menuItemToEdit != null) {
        await dbService.updateMenuItem(menuItem);
      } else {
        await dbService.insertMenuItem(menuItem);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.menuItemToEdit != null 
                ? 'Élément modifié avec succès' 
                : 'Élément créé avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() { _errorMessage = 'Erreur lors de la sauvegarde: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildMainCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Choisissez une catégorie principale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFbfa14a))),
        ),
        Expanded(
          child: ListView(
            children: _categoryTree.keys.map((cat) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2a2a3a),
                  foregroundColor: const Color(0xFFbfa14a),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onPressed: () => setState(() => _mainCategory = cat),
                child: Text(cat, style: const TextStyle(fontSize: 20)),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategorySelector() {
    final subCats = _categoryTree[_mainCategory]!.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)), onPressed: _resetToMain),
              Text('$_mainCategory : Choisissez un sous-type', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFbfa14a))),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: subCats.map((sub) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2a2a3a),
                  foregroundColor: const Color(0xFFbfa14a),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onPressed: () => setState(() => _subCategory = sub),
                child: Text(sub, style: const TextStyle(fontSize: 20)),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubSubCategorySelector() {
    final subSubCats = _categoryTree[_mainCategory]![_subCategory]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)), onPressed: _resetToSub),
              Text('$_mainCategory > $_subCategory : Choisissez un sous-type', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFbfa14a))),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: subSubCats.map((subsub) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2a2a3a),
                  foregroundColor: const Color(0xFFbfa14a),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onPressed: () => setState(() => _subSubCategory = subsub),
                child: Text(subsub, style: const TextStyle(fontSize: 20)),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catégorie : ${_getCategoryLabel()}', style: const TextStyle(color: Color(0xFFbfa14a), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du produit *',
                labelStyle: TextStyle(color: Color(0xFFbfa14a)),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFbfa14a))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFbfa14a), width: 2)),
                filled: true,
                fillColor: Color(0xFF2a2a3a),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (value) => value == null || value.trim().isEmpty ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prix TTC (€) *',
                labelStyle: TextStyle(color: Color(0xFFbfa14a)),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFbfa14a))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFbfa14a), width: 2)),
                filled: true,
                fillColor: Color(0xFF2a2a3a),
                suffixText: '€',
                suffixStyle: TextStyle(color: Color(0xFFbfa14a)),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Le prix est requis';
                final price = double.tryParse(value.replaceAll(',', '.'));
                if (price == null || price <= 0) return 'Prix invalide';
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
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFbfa14a))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFbfa14a), width: 2)),
                filled: true,
                fillColor: Color(0xFF2a2a3a),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProduct,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFbfa14a),
                    foregroundColor: const Color(0xFF231f2b),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _isLoading ? null : _resetToMain,
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_mainCategory == null) {
      content = _buildMainCategorySelector();
    } else if (_subCategory == null) {
      content = _buildSubCategorySelector();
    } else if (_categoryTree[_mainCategory]![_subCategory]!.isNotEmpty && _subSubCategory == null) {
      content = _buildSubSubCategorySelector();
    } else {
      content = _buildProductForm();
    }
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text('Ajouter un produit', style: TextStyle(color: Color(0xFFbfa14a))),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () {
            if (_subSubCategory != null) {
              _resetToSubSub();
            } else if (_subCategory != null) {
              _resetToSub();
            } else if (_mainCategory != null) {
              _resetToMain();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : content,
    );
  }
} 
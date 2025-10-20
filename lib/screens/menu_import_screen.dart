import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/api_database_service.dart';
import '../utils/menu_import_utils.dart';
import '../models/menu_item.dart';

class MenuImportScreen extends StatefulWidget {
  const MenuImportScreen({super.key});

  @override
  State<MenuImportScreen> createState() => _MenuImportScreenState();
}

class _MenuImportScreenState extends State<MenuImportScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  final TextEditingController _csvController = TextEditingController();
  
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isError = false;
  List<String> _validationErrors = [];
  List<MenuItem> _previewItems = [];

  @override
  void initState() {
    super.initState();
    _loadCsvTemplate();
  }

  void _loadCsvTemplate() {
    _csvController.text = MenuImportUtils.generateCsvTemplate();
  }

  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        setState(() {
          _csvController.text = content;
          _statusMessage = 'Fichier CSV chargé avec succès';
          _isError = false;
        });
        _validateAndPreview();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur lors du chargement du fichier: $e';
        _isError = true;
      });
    }
  }

  void _validateAndPreview() {
    try {
      final csvData = MenuImportUtils.parseCsvContent(_csvController.text);
      final errors = MenuImportUtils.validateCsvData(csvData);
      final items = MenuImportUtils.csvToMenuItems(csvData);

      setState(() {
        _validationErrors = errors;
        _previewItems = items;
        
        if (errors.isEmpty) {
          _statusMessage = '${items.length} items validés et prêts à importer';
          _isError = false;
        } else {
          _statusMessage = '${errors.length} erreurs de validation détectées';
          _isError = true;
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur lors de la validation: $e';
        _isError = true;
        _validationErrors = [e.toString()];
      });
    }
  }

  Future<void> _importMenuItems() async {
    if (_previewItems.isEmpty) {
      setState(() {
        _statusMessage = 'Aucun item à importer';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Import en cours...';
      _isError = false;
    });

    try {
      final result = await _dbService.bulkImportMenuItems(_previewItems);
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import réussi! ${result['regularItems']} items réguliers et ${result['presetMenus']} menus préétablis importés.';
        _isError = false;
      });

      // Clear the form after successful import
      _csvController.clear();
      _previewItems.clear();
      _validationErrors.clear();
      
      // Show success dialog
      _showSuccessDialog(result);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erreur lors de l\'import: $e';
        _isError = true;
      });
    }
  }

  void _showSuccessDialog(Map<String, int> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Réussi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ${result['regularItems']} items réguliers importés'),
            Text('✅ ${result['presetMenus']} menus préétablis importés'),
            const SizedBox(height: 16),
            const Text('Vous pouvez maintenant utiliser ces items dans votre menu.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instructions d\'Import'),
        content: SingleChildScrollView(
          child: Text(MenuImportUtils.getImportInstructions()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import de Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructions,
            tooltip: 'Instructions',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isError ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isError ? Colors.red.shade800 : Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickCsvFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Choisir fichier CSV'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _validateAndPreview,
                    icon: const Icon(Icons.preview),
                    label: const Text('Valider & Prévisualiser'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CSV Editor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Contenu CSV:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadCsvTemplate,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Template'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _csvController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Collez votre contenu CSV ici...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Validation errors
            if (_validationErrors.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Erreurs de validation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_validationErrors.take(5).map((error) => Text('• $error'))),
                    if (_validationErrors.length > 5)
                      Text('... et ${_validationErrors.length - 5} autres erreurs'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Preview
            if (_previewItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prévisualisation (${_previewItems.length} items):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: _previewItems.length,
                        itemBuilder: (context, index) {
                          final item = _previewItems[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              item.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              '${item.category} - ${item.priceTtc.toStringAsFixed(2)}€ TTC',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: item.isPresetMenu
                                ? const Chip(
                                    label: Text('Menu'),
                                    backgroundColor: Colors.green,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Import button
            if (_previewItems.isNotEmpty && _validationErrors.isEmpty)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importMenuItems,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isLoading ? 'Import en cours...' : 'Importer ${_previewItems.length} items'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }
} 
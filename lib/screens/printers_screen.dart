import 'package:flutter/material.dart';
import '../models/printer.dart';

class PrintersScreen extends StatefulWidget {
  const PrintersScreen({super.key});

  @override
  State<PrintersScreen> createState() => _PrintersScreenState();
}

class _PrintersScreenState extends State<PrintersScreen> {
  List<Printer> _printers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  void _loadPrinters() {
    setState(() {
      _isLoading = true;
    });
    
    // Charger les imprimantes prédéfinies
    _printers = List.from(Printer.defaultPrinters);
    
    setState(() {
      _isLoading = false;
    });
  }

  void _showAddEditDialog([Printer? printer]) {
    final isEditing = printer != null;
    final nameController = TextEditingController(text: printer?.name ?? '');
    final locationController = TextEditingController(text: printer?.location ?? '');
    final descriptionController = TextEditingController(text: printer?.description ?? '');
    bool isActive = printer?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier l\'imprimante' : 'Ajouter une imprimante'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'imprimante',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Active'),
                  const SizedBox(width: 8),
                  Switch(
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom de l\'imprimante est requis')),
                );
                return;
              }

              final newPrinter = Printer(
                id: isEditing ? printer!.id : null,
                name: nameController.text.trim(),
                ipAddress: '192.168.1.100', // Valeur par défaut
                port: 9100, // Valeur par défaut
                location: locationController.text.trim(),
                description: descriptionController.text.trim(),
                isActive: isActive,
              );

              if (isEditing) {
                _updatePrinter(newPrinter);
              } else {
                _addPrinter(newPrinter);
              }

              Navigator.of(context).pop();
            },
            child: Text(isEditing ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ),
    );
  }


  void _addPrinter(Printer printer) {
    setState(() {
      _printers.add(printer);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imprimante "${printer.name}" ajoutée')),
    );
  }

  void _updatePrinter(Printer printer) {
    setState(() {
      final index = _printers.indexWhere((p) => p.id == printer.id);
      if (index != -1) {
        _printers[index] = printer;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imprimante "${printer.name}" modifiée')),
    );
  }

  void _deletePrinter(Printer printer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'imprimante'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'imprimante "${printer.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _printers.removeWhere((p) => p.id == printer.id);
              });
              
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imprimante "${printer.name}" supprimée')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _togglePrinterStatus(Printer printer) {
    setState(() {
      final index = _printers.indexWhere((p) => p.id == printer.id);
      if (index != -1) {
        _printers[index] = printer.copyWith(isActive: !printer.isActive);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imprimante "${printer.name}" ${printer.isActive ? 'désactivée' : 'activée'}'
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration des Imprimantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
            tooltip: 'Ajouter une imprimante',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _printers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print_disabled, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune imprimante configurée',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Appuyez sur + pour ajouter une imprimante',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _printers.length,
                  itemBuilder: (context, index) {
                    final printer = _printers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.print,
                          color: printer.isActive ? Colors.blue : Colors.grey,
                        ),
                        title: Text(
                          printer.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: printer.isActive ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              printer.location ?? 'Non définie',
                              style: TextStyle(
                                color: printer.isActive ? null : Colors.grey,
                              ),
                            ),
                            if (printer.description != null && printer.description!.isNotEmpty)
                              Text(
                                printer.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: printer.isActive ? Colors.grey[600] : Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                printer.isActive ? Icons.pause : Icons.play_arrow,
                                color: printer.isActive ? Colors.orange : Colors.green,
                              ),
                              onPressed: () => _togglePrinterStatus(printer),
                              tooltip: printer.isActive ? 'Désactiver' : 'Activer',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(printer),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePrinter(printer),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


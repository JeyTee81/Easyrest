import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/api_database_service.dart';
import 'dart:async';
import 'create_preset_menu_screen.dart';

class PresetMenusScreen extends StatefulWidget {
  const PresetMenusScreen({super.key});

  @override
  State<PresetMenusScreen> createState() => _PresetMenusScreenState();
}

class _PresetMenusScreenState extends State<PresetMenusScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<MenuItem> _presetMenus = [];
  bool _isLoading = true;

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
      
      final menus = await _dbService.getPresetMenus();
      setState(() {
        _presetMenus = menus;
        _isLoading = false;
      });
    } catch (e) {
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
      ),
    );
  }

  void _showCreateMenuDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePresetMenuScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  Future<void> _editPresetMenu(MenuItem menu) async {
    if (menu.id == null) {
      _showError('Impossible de modifier ce menu (ID manquant)');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePresetMenuScreen(menuToEdit: menu),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  Future<void> _deletePresetMenu(MenuItem menu) async {
    if (menu.id == null) {
      _showError('Impossible de supprimer ce menu (ID manquant)');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a3a),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${menu.name}" ?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbService.deletePresetMenu(menu.id!);
        _showSuccess('Menu préétabli supprimé avec succès');
        _loadData();
      } catch (e) {
        _showError('Erreur lors de la suppression: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PresetMenusScreen build: isLoading=$_isLoading, presetMenus=${_presetMenus.length}');
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text(
          'Menus préétablis',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          try {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFbfa14a),
                ),
              );
            } else if (_presetMenus.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Color(0xFFbfa14a),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun menu préétabli',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFbfa14a),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Créez votre premier menu préétabli',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showCreateMenuDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFbfa14a),
                        foregroundColor: const Color(0xFF231f2b),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un menu préétabli'),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _presetMenus.length,
                itemBuilder: (context, index) {
                  final menu = _presetMenus[index];
                  return Card(
                    color: const Color(0xFF2a2a3a),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const Icon(
                            Icons.star,
                            color: Color(0xFFbfa14a),
                            size: 32,
                          ),
                          title: Text(
                            menu.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFbfa14a),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (menu.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  menu.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFbfa14a),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${menu.priceTtc.toStringAsFixed(2)}€ TTC',
                                      style: const TextStyle(
                                        color: Color(0xFF231f2b),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'TVA ${menu.tvaRate}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Color(0xFFbfa14a)),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _editPresetMenu(menu);
                                  break;
                                case 'delete':
                                  _deletePresetMenu(menu);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Color(0xFFbfa14a)),
                                    SizedBox(width: 8),
                                    Text('Modifier le menu'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Supprimer le menu', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF231f2b),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _PresetMenuCompositionEditor(
                            presetMenu: menu,
                            dbService: _dbService,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          } catch (e, stack) {
            debugPrint('Error in PresetMenusScreen build: $e\n$stack');
            return Center(child: Text('Erreur d\'affichage: $e', style: const TextStyle(color: Colors.red)));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMenuDialog,
        backgroundColor: const Color(0xFFbfa14a),
        foregroundColor: const Color(0xFF231f2b),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PresetMenuCompositionEditor extends StatefulWidget {
  final MenuItem presetMenu;
  final ApiDatabaseService dbService;
  const _PresetMenuCompositionEditor({required this.presetMenu, required this.dbService});

  @override
  State<_PresetMenuCompositionEditor> createState() => _PresetMenuCompositionEditorState();
}

class _PresetMenuCompositionEditorState extends State<_PresetMenuCompositionEditor> {
  late Future<List<MenuItem>> _allMenuItemsFuture;
  late Future<Map<String, List<MenuItem>>> _compositionFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _allMenuItemsFuture = widget.dbService.getRegularMenuItems();
      _compositionFuture = widget.dbService.getPresetMenuComposition(widget.presetMenu.id!);
    });
  }

  Future<void> _addItemToGroup(MenuItem item, String group) async {
    await widget.dbService.addItemToPresetMenu(
      presetMenuId: widget.presetMenu.id!,
      menuItemId: item.id!,
      group: group,
    );
    _refresh();
  }

  Future<void> _removeItemFromGroup(MenuItem item, String group) async {
    await widget.dbService.removeItemFromPresetMenu(
      presetMenuId: widget.presetMenu.id!,
      menuItemId: item.id!,
      group: group,
    );
    _refresh();
  }

  void _showItemSelectionDialog(String group, List<MenuItem> availableItems) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a3a),
          title: Text(
            'Sélectionner un élément pour $group',
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
                    _addItemToGroup(item, group);
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuItem>>(
      future: _allMenuItemsFuture,
      builder: (context, snapshotAll) {
        if (!snapshotAll.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final allMenuItems = snapshotAll.data!;
        return FutureBuilder<Map<String, List<MenuItem>>>(
          future: _compositionFuture,
          builder: (context, snapshotComp) {
            if (!snapshotComp.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final composition = snapshotComp.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Composition du menu', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...ApiDatabaseService.presetMenuGroups.map((group) {
                  final groupItems = composition[group] ?? [];
                  final availableItems = allMenuItems.where((item) => !groupItems.any((gi) => gi.id == item.id)).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (availableItems.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _showItemSelectionDialog(group, availableItems),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Ajouter un élément', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFbfa14a),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          children: groupItems.map((item) => Chip(
                            label: Text(item.name),
                            onDeleted: () => _removeItemFromGroup(item, group),
                          )).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
} 
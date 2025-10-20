import 'package:flutter/material.dart';
import '../models/table_restaurant.dart';
import '../models/room.dart';
import '../services/api_database_service.dart';
import 'orders_screen.dart';
// Pour DatabaseErrorScreen
import 'rooms_screen.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<TableRestaurant> _tables = [];
  List<Room> _rooms = [];
  bool _isLoading = true;
  bool _dbError = false;
  String? _dbErrorMsg;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRooms();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final tables = await _dbService.getTables();
      setState(() {
        _tables = tables;
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

  Future<void> _loadRooms() async {
    try {
      final rooms = await _dbService.getRooms();
      setState(() {
        _rooms = rooms;
      });
    } catch (e) {
      _showError('Erreur lors du chargement des salles: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showAddEditDialog([TableRestaurant? table]) {
    final isEditing = table != null;
    final numberController = TextEditingController(text: table?.number.toString() ?? '');
    final capacityController = TextEditingController(text: table?.capacity.toString() ?? '');
    int selectedRoomId = table?.roomId ?? (_rooms.isNotEmpty ? _rooms.first.id! : 0);
    String selectedStatus = table?.status ?? 'Libre';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier la table' : 'Ajouter une table'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Numéro de table'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Capacité (nombre de places)'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<int>(
                value: selectedRoomId,
                decoration: const InputDecoration(labelText: 'Salle'),
                items: _rooms.map((room) => DropdownMenuItem(
                  value: room.id,
                  child: Text(room.name),
                )).toList(),
                onChanged: (value) {
                  if (value != null) selectedRoomId = value;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Statut',
                  filled: true,
                  fillColor: Color(0xFFfff8e1),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFFfff8e1),
                style: const TextStyle(color: Color(0xFF231f2b)),
                items: ['Libre', 'Occupée', 'Réservée', 'En service', 'Nettoyage'].map((status) {
                  return DropdownMenuItem(
                    value: status, 
                    child: Text(
                      status,
                      style: const TextStyle(color: Color(0xFF231f2b)),
                    )
                  );
                }).toList(),
                onChanged: (value) => selectedStatus = value!,
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
                final number = int.tryParse(numberController.text) ?? 0;
                final capacity = int.tryParse(capacityController.text) ?? 0;
                if (number == 0) {
                  _showError('Le numéro de table est requis');
                  return;
                }
                if (selectedRoomId == 0) {
                  _showError('Veuillez sélectionner une salle');
                  return;
                }
                final newTable = TableRestaurant(
                  id: table?.id,
                  number: number,
                  capacity: capacity,
                  roomId: selectedRoomId,
                  status: selectedStatus,
                );
                if (isEditing) {
                  await _dbService.updateTable(newTable);
                } else {
                  await _dbService.insertTable(newTable);
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

  void _showStatusDialog(TableRestaurant table) {
    String selectedStatus = table.status;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le statut de la table ${table.number}'),
        content: DropdownButtonFormField<String>(
          value: selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Nouveau statut',
            filled: true,
            fillColor: Color(0xFFfff8e1),
            border: OutlineInputBorder(),
          ),
          dropdownColor: const Color(0xFFfff8e1),
          style: const TextStyle(color: Color(0xFF231f2b)),
          items: ['Libre', 'Occupée', 'Réservée', 'En service', 'Nettoyage'].map((status) {
            return DropdownMenuItem(
              value: status, 
              child: Text(
                status,
                style: const TextStyle(color: Color(0xFF231f2b)),
              )
            );
          }).toList(),
          onChanged: (value) => selectedStatus = value!,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedTable = TableRestaurant(
                  id: table.id,
                  number: table.number,
                  capacity: table.capacity,
                  roomId: table.roomId,
                  status: selectedStatus,
                );
                await _dbService.updateTable(updatedTable);
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Libre':
        return Colors.green;
      case 'Occupée':
        return Colors.red;
      case 'Réservée':
        return Colors.orange;
      case 'En service':
        return Colors.blue;
      case 'Nettoyage':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
          'Gestion des Tables',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.meeting_room, color: Color(0xFFbfa14a)),
            tooltip: 'Gérer les salles',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoomsScreen()),
              );
              await _loadRooms();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : _tables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_bar, size: 64, color: Color(0xFFbfa14a)),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune table configurée',
                        style: TextStyle(color: Color(0xFFbfa14a), fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddEditDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFbfa14a),
                          foregroundColor: const Color(0xFF231f2b),
                        ),
                        child: const Text('Ajouter une table'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Room management button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RoomsScreen()),
                          );
                          await _loadRooms();
                        },
                        icon: const Icon(Icons.meeting_room),
                        label: const Text('Gérer les salles'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFbfa14a),
                          foregroundColor: const Color(0xFF231f2b),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    // Tables list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _tables.length,
                        itemBuilder: (context, index) {
                          final table = _tables[index];
                          final room = _rooms.firstWhere((r) => r.id == table.roomId, orElse: () => const Room(id: 0, name: 'Inconnu', isActive: false));
                          return Card(
                            color: const Color(0xFF2a2438),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(table.status),
                                child: Text(table.number.toString(), style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text('Table ${table.number} (${room.name})', style: const TextStyle(color: Colors.white)),
                              subtitle: Text('Capacité: ${table.capacity} - Statut: ${table.status}', style: const TextStyle(color: Colors.white70)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showAddEditDialog(table),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _dbService.deleteTable(table.id!);
                                      _loadData();
                                    },
                                    tooltip: 'Supprimer',
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrdersScreen(selectedTable: table),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditDialog,
        backgroundColor: const Color(0xFFbfa14a),
        child: const Icon(Icons.add),
      ),
    );
  }
} 
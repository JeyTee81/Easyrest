import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/api_database_service.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<Room> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final rooms = await _dbService.getRooms();
      setState(() {
        _rooms = rooms;
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showAddEditDialog([Room? room]) {
    final isEditing = room != null;
    final nameController = TextEditingController(text: room?.name ?? '');
    final descriptionController = TextEditingController(text: room?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier la salle' : 'Ajouter une salle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la salle',
                  hintText: 'Ex: Terrasse, Salle 1, Bar...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Description de la salle...',
                ),
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
                if (nameController.text.trim().isEmpty) {
                  _showError('Le nom de la salle est requis');
                  return;
                }

                final newRoom = Room(
                  id: room?.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  isActive: true,
                );

                if (isEditing) {
                  await _dbService.updateRoom(newRoom);
                  _showSuccess('Salle modifiée avec succès');
                } else {
                  await _dbService.insertRoom(newRoom);
                  _showSuccess('Salle ajoutée avec succès');
                }

                Navigator.pop(context);
                _loadRooms();
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

  Future<void> _deleteRoom(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la salle "${room.name}" ?\n\nCette action ne peut pas être annulée.'),
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
        await _dbService.deleteRoom(room.id!);
        _showSuccess('Salle supprimée avec succès');
        _loadRooms();
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
        title: const Text(
          'Gestion des Salles',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : _rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.room,
                        size: 64,
                        color: Color(0xFFbfa14a),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune salle configurée',
                        style: TextStyle(
                          color: Color(0xFFbfa14a),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajoutez vos salles pour organiser vos tables',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddEditDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFbfa14a),
                          foregroundColor: const Color(0xFF231f2b),
                        ),
                        child: const Text('Ajouter une salle'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return Card(
                      color: const Color(0xFF2a2438),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFbfa14a),
                          child: Icon(
                            Icons.room,
                            color: Color(0xFF231f2b),
                          ),
                        ),
                        title: Text(
                          room.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: room.description.isNotEmpty
                            ? Text(
                                room.description,
                                style: const TextStyle(color: Colors.white70),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(room),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRoom(room),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditDialog,
        backgroundColor: const Color(0xFFbfa14a),
        child: const Icon(Icons.add),
      ),
    );
  }
} 
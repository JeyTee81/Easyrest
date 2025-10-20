import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../services/api_database_service.dart';
// Pour DatabaseErrorScreen

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<Staff> _staff = [];
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
      final staff = await _dbService.getStaff();
      setState(() {
        _staff = staff;
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

  void _showAddEditDialog([Staff? staff]) {
    final isEditing = staff != null;
    final nameController = TextEditingController(text: staff?.name ?? '');
    final pinController = TextEditingController(text: staff?.pin ?? '');
    String selectedRole = staff?.role ?? 'staff';
    bool isActive = staff?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Modifier l\'employé' : 'Ajouter un employé'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                TextField(
                  controller: pinController,
                  decoration: const InputDecoration(labelText: 'Code PIN'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    filled: true,
                    fillColor: Color(0xFFfff8e1),
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: const Color(0xFFfff8e1),
                  style: const TextStyle(color: Color(0xFF231f2b)),
                  items: const [
                    DropdownMenuItem(
                      value: 'staff', 
                      child: Text(
                        'Employé',
                        style: TextStyle(color: Color(0xFF231f2b)),
                      )
                    ),
                    DropdownMenuItem(
                      value: 'manager', 
                      child: Text(
                        'Manager',
                        style: TextStyle(color: Color(0xFF231f2b)),
                      )
                    ),
                  ],
                  onChanged: (value) => selectedRole = value!,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Compte actif'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
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
                  if (nameController.text.isEmpty || pinController.text.isEmpty) {
                    _showError('Le nom et le code PIN sont requis');
                    return;
                  }

                  if (pinController.text.length < 4) {
                    _showError('Le code PIN doit contenir au moins 4 chiffres');
                    return;
                  }

                  final newStaff = Staff(
                    id: staff?.id,
                    name: nameController.text,
                    pin: pinController.text,
                    role: selectedRole,
                    isActive: isActive,
                  );

                  if (isEditing) {
                    await _dbService.updateStaff(newStaff);
                  } else {
                    await _dbService.insertStaff(newStaff);
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
          'Gestion de l\'Équipe',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : _staff.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 64, color: Color(0xFFbfa14a)),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun employé enregistré',
                        style: TextStyle(color: Color(0xFFbfa14a), fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddEditDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFbfa14a),
                          foregroundColor: const Color(0xFF231f2b),
                        ),
                        child: const Text('Ajouter un employé'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staff.length,
                  itemBuilder: (context, index) {
                    final member = _staff[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: member.role == 'manager' 
                              ? const Color(0xFFbfa14a) 
                              : Colors.blue,
                          child: Icon(
                            member.role == 'manager' ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code PIN: ${member.pin}'),
                            Text('Rôle: ${member.role == 'manager' ? 'Manager' : 'Employé'}'),
                            Row(
                              children: [
                                Icon(
                                  member.isActive ? Icons.check_circle : Icons.cancel,
                                  color: member.isActive ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  member.isActive ? 'Actif' : 'Inactif',
                                  style: TextStyle(
                                    color: member.isActive ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(member),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteStaff(member),
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
        foregroundColor: const Color(0xFF231f2b),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteStaff(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${staff.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbService.deleteStaff(staff.id!);
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

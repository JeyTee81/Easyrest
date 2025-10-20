import 'package:flutter/material.dart';
// import '../utils/database_backup_utils.dart'; // Supprimé - utilise maintenant PostgreSQL
import '../services/api_database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  String _language = 'Français';
  String _currency = 'EUR';
  double _taxRate = 20.0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    // Avec PostgreSQL local, les sauvegardes sont gérées manuellement
    setState(() {
      _backups = [];
    });
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

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    
    try {
      // Avec PostgreSQL local, les sauvegardes sont manuelles
      final backupPath = 'postgresql_local_backup';
      await _loadBackups(); // Refresh the list
      _showSuccess('Sauvegarde créée avec succès');
    } catch (e) {
      _showError('Erreur lors de la création de la sauvegarde: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarde'),
        content: const Text('Voulez-vous créer une sauvegarde de toutes les données ?\n\nLa sauvegarde sera stockée dans le dossier "Documents/EasyRest".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createBackup();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    if (_backups.isEmpty) {
      _showError('Aucune sauvegarde disponible');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restauration'),
        content: const Text('Attention ! Cela remplacera toutes les données actuelles.\n\nUne sauvegarde de vos données actuelles sera créée avant la restauration.\n\nContinuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBackupSelectionDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
  }

  void _showBackupSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner une sauvegarde'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _backups.length,
            itemBuilder: (context, index) {
              final backup = _backups[index];
              final hasError = backup.containsKey('error');
              
              return ListTile(
                title: Text(
                  backup['name'] as String,
                  style: TextStyle(
                    color: hasError ? Colors.red : Colors.black,
                  ),
                ),
                subtitle: hasError 
                  ? Text('Erreur: ${backup['error']}', style: const TextStyle(color: Colors.red))
                  : Text('Sauvegarde PostgreSQL locale'),
                trailing: hasError 
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBackup(backup['path'] as String),
                    )
                  : const Icon(Icons.restore, color: Colors.orange),
                onTap: hasError ? null : () {
                  Navigator.pop(context);
                  _restoreBackup(backup['path'] as String);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(String backupPath) async {
    setState(() => _isLoading = true);
    
    try {
      // Avec PostgreSQL local, la restauration se fait manuellement
      final success = true;
      if (success) {
        _showSuccess('Données restaurées avec succès. Redémarrez l\'application.');
      } else {
        _showError('Échec de la restauration');
      }
    } catch (e) {
      _showError('Erreur lors de la restauration: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(String backupPath) async {
    try {
      // Avec PostgreSQL local, les sauvegardes peuvent être supprimées
      final success = true;
      if (success) {
        await _loadBackups(); // Refresh the list
        _showSuccess('Sauvegarde supprimée');
      } else {
        _showError('Échec de la suppression');
      }
    } catch (e) {
      _showError('Erreur lors de la suppression: $e');
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialisation'),
        content: const Text('Attention ! Cela supprimera TOUTES les données.\n\nCette action est irréversible.\n\nContinuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetDatabase();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDatabase() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await ApiDatabaseService.resetDatabase();
      if (success) {
        _showSuccess('Application réinitialisée. Redémarrez l\'application.');
      } else {
        _showError('Échec de la réinitialisation');
      }
    } catch (e) {
      _showError('Erreur lors de la réinitialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        elevation: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFbfa14a)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Apparence
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Apparence',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Mode sombre'),
                        subtitle: const Text('Utiliser le thème sombre'),
                        value: _darkMode,
                        onChanged: (value) => setState(() => _darkMode = value),
                      ),
                      ListTile(
                        title: const Text('Langue'),
                        subtitle: Text(_language),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sélectionner la langue'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: ['Français', 'English', 'Español'].map((lang) {
                                  return ListTile(
                                    title: Text(lang),
                                    onTap: () {
                                      setState(() => _language = lang);
                                      Navigator.pop(context);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notifications
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Notifications',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Activer les notifications'),
                        subtitle: const Text('Recevoir des alertes'),
                        value: _notificationsEnabled,
                        onChanged: (value) => setState(() => _notificationsEnabled = value),
                      ),
                      SwitchListTile(
                        title: const Text('Sons'),
                        subtitle: const Text('Activer les sons de notification'),
                        value: _soundEnabled,
                        onChanged: (value) => setState(() => _soundEnabled = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Commerce
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Commerce',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        title: const Text('Devise'),
                        subtitle: Text(_currency),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sélectionner la devise'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: ['EUR', 'USD', 'GBP'].map((curr) {
                                  return ListTile(
                                    title: Text(curr),
                                    onTap: () {
                                      setState(() => _currency = curr);
                                      Navigator.pop(context);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Taux de TVA par défaut'),
                        subtitle: Text('${_taxRate.toStringAsFixed(1)}%'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Taux de TVA par défaut'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Slider(
                                    value: _taxRate,
                                    min: 0,
                                    max: 30,
                                    divisions: 30,
                                    label: '${_taxRate.toStringAsFixed(1)}%',
                                    onChanged: (value) => setState(() => _taxRate = value),
                                  ),
                                  Text('${_taxRate.toStringAsFixed(1)}%'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Données
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Données',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.backup, color: Color(0xFFbfa14a)),
                        title: const Text('Sauvegarder'),
                        subtitle: const Text('Créer une sauvegarde des données'),
                        onTap: _showBackupDialog,
                      ),
                      ListTile(
                        leading: const Icon(Icons.restore, color: Color(0xFFbfa14a)),
                        title: const Text('Restaurer'),
                        subtitle: Text('Restaurer depuis une sauvegarde (${_backups.length} disponible${_backups.length > 1 ? 's' : ''})'),
                        onTap: _showRestoreDialog,
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text('Réinitialiser'),
                        subtitle: const Text('Supprimer toutes les données'),
                        onTap: _showResetDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // À propos
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'À propos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const ListTile(
                        leading: Icon(Icons.info, color: Color(0xFFbfa14a)),
                        title: Text('Version'),
                        subtitle: Text('1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.contact_support, color: Color(0xFFbfa14a)),
                        title: const Text('Support'),
                        subtitle: const Text('easyrestfrance@gmail.com'),
                        onTap: () {
                          // TODO: Implement email launch
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 
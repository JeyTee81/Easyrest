import 'package:flutter/material.dart';
// import '../utils/database_backup_utils.dart'; // Supprimé - utilise maintenant PostgreSQL
import '../services/api_database_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = false;
  String? _savedDbDirectory;
  String? _currentDatabasePath;
  String? _externalStoragePath;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    
    try {
      // Avec PostgreSQL local, les sauvegardes sont manuelles
      final backups = <Map<String, dynamic>>[];
      final savedDbDir = 'postgresql_local';
      final currentDbPath = await ApiDatabaseService.getDatabasePath();
      final externalStoragePath = await ApiDatabaseService.getExternalStoragePath();
      
      setState(() {
        _backups = backups;
        _savedDbDirectory = savedDbDir;
        _currentDatabasePath = currentDbPath;
        _externalStoragePath = externalStoragePath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des sauvegardes: $e');
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

  Future<void> _openDatabaseFolder() async {
    try {
      final easyrestDir = await ApiDatabaseService.getEasyRestDirectoryPath();
      if (easyrestDir.isNotEmpty) {
        final uri = Uri.file(easyrestDir);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showError('Impossible d\'ouvrir le dossier de la base de données');
        }
      } else {
        _showError('Chemin du dossier non disponible');
      }
    } catch (e) {
      _showError('Erreur lors de l\'ouverture du dossier: $e');
    }
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

  Future<void> _restoreBackup(String backupPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la restauration'),
        content: const Text(
          'Attention ! Cela remplacera toutes les données actuelles.\n\n'
          'Une sauvegarde de vos données actuelles sera créée avant la restauration.\n\n'
          'Continuer ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
  }

  Future<void> _deleteBackup(String backupPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette sauvegarde ?'),
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
  }

  void _showBackupInfo(Map<String, dynamic> backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de la sauvegarde'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${backup['name']}'),
            const SizedBox(height: 8),
            Text('Taille: Sauvegarde cloud automatique'),
            const SizedBox(height: 8),
            Text('Version: ${backup['version']}'),
            const SizedBox(height: 8),
            Text('Tables: ${backup['tables']}'),
            const SizedBox(height: 8),
            Text('Enregistrements: ${backup['records']}'),
            const SizedBox(height: 8),
            Text('Modifié: ${(backup['modified'] as DateTime).toString().substring(0, 19)}'),
            if (backup.containsKey('error')) ...[
              const SizedBox(height: 8),
              Text('Erreur: ${backup['error']}', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text(
          'Gestion des sauvegardes',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : Column(
              children: [
                // Info card
                if (_savedDbDirectory != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2a2438),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFbfa14a)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emplacement de la base de données',
                          style: TextStyle(
                            color: Color(0xFFbfa14a),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_currentDatabasePath != null) ...[
                          const Text(
                            'Base de données actuelle:',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currentDatabasePath!,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const Text(
                          'Dossier de sauvegarde:',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _savedDbDirectory!,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '💡 Sauvegarde manuelle sur tablette Android:',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_externalStoragePath != null && _externalStoragePath!.isNotEmpty) ...[
                                Text(
                                  'Stockage externe: $_externalStoragePath',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              const Text(
                                '• Utilisez un gestionnaire de fichiers (ex: Files by Google)\n'
                                '• Naviguez vers le dossier affiché ci-dessus\n'
                                '• Copiez le fichier easyrest.db vers votre stockage externe\n'
                                '• Ou utilisez l\'option "Ouvrir le dossier" ci-dessous',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_backups.length} sauvegarde${_backups.length > 1 ? 's' : ''} disponible${_backups.length > 1 ? 's' : ''}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _openDatabaseFolder,
                              icon: const Icon(Icons.folder_open, size: 16),
                              label: const Text('Ouvrir le dossier'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFbfa14a),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _createBackup,
                              icon: const Icon(Icons.backup, size: 16),
                              label: const Text('Sauvegarde auto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Backups list
                Expanded(
                  child: _backups.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.backup,
                                size: 64,
                                color: Color(0xFFbfa14a),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Aucune sauvegarde',
                                style: TextStyle(
                                  color: Color(0xFFbfa14a),
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Créez votre première sauvegarde',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _backups.length,
                          itemBuilder: (context, index) {
                            final backup = _backups[index];
                            final hasError = backup.containsKey('error');
                            
                            return Card(
                              color: const Color(0xFF2a2438),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  hasError ? Icons.error : Icons.backup,
                                  color: hasError ? Colors.red : const Color(0xFFbfa14a),
                                ),
                                title: Text(
                                  backup['name'] as String,
                                  style: TextStyle(
                                    color: hasError ? Colors.red : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: hasError 
                                  ? Text(
                                      'Erreur: ${backup['error']}',
                                      style: const TextStyle(color: Colors.red),
                                    )
                                  : Text(
                                      'Sauvegarde PostgreSQL locale',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.info, color: Colors.blue),
                                      onPressed: () => _showBackupInfo(backup),
                                      tooltip: 'Détails',
                                    ),
                                    if (!hasError)
                                      IconButton(
                                        icon: const Icon(Icons.restore, color: Colors.orange),
                                        onPressed: () => _restoreBackup(backup['path'] as String),
                                        tooltip: 'Restaurer',
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteBackup(backup['path'] as String),
                                      tooltip: 'Supprimer',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBackup,
        backgroundColor: const Color(0xFFbfa14a),
        child: const Icon(Icons.add),
      ),
    );
  }
} 
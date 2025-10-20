import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../config/reports_config.dart';

class ReportsConfigScreen extends StatefulWidget {
  const ReportsConfigScreen({Key? key}) : super(key: key);

  @override
  State<ReportsConfigScreen> createState() => _ReportsConfigScreenState();
}

class _ReportsConfigScreenState extends State<ReportsConfigScreen> {
  String? _currentPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    setState(() => _isLoading = true);
    try {
      final path = await ReportsConfig.getReportsPath();
      setState(() {
        _currentPath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement: $e');
    }
  }

  Future<void> _selectDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        // Validate the selected path
        final isValid = await ReportsConfig.isPathValid(selectedDirectory);
        if (isValid) {
          await ReportsConfig.setReportsPath(selectedDirectory);
          setState(() {
            _currentPath = selectedDirectory;
          });
          _showSuccess('Dossier des rapports configuré avec succès');
        } else {
          _showError('Le dossier sélectionné n\'est pas accessible en écriture');
        }
      }
    } catch (e) {
      _showError('Erreur lors de la sélection du dossier: $e');
    }
  }

  Future<void> _resetToDefault() async {
    try {
      final defaultPath = await ReportsConfig.getDefaultReportsPath();
      final isValid = await ReportsConfig.isPathValid(defaultPath);
      
      if (isValid) {
        await ReportsConfig.setReportsPath(defaultPath);
        setState(() {
          _currentPath = defaultPath;
        });
        _showSuccess('Dossier des rapports réinitialisé par défaut');
      } else {
        _showError('Impossible d\'utiliser le dossier par défaut');
      }
    } catch (e) {
      _showError('Erreur lors de la réinitialisation: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text(
          'Configuration des rapports',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dossier des rapports CSV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              color: const Color(0xFF2a2438),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dossier actuel:',
                      style: TextStyle(
                        color: Color(0xFFbfa14a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Text(
                        _currentPath ?? 'Non configuré',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectDirectory,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Choisir un dossier'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFbfa14a),
                              foregroundColor: const Color(0xFF231f2b),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _resetToDefault,
                            icon: const Icon(Icons.restore),
                            label: const Text('Par défaut'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Card(
              color: Color(0xFF2a2438),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Format des fichiers:',
                      style: TextStyle(
                        color: Color(0xFFbfa14a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Les rapports de caisse sont sauvegardés au format:',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'caisse_jjmmaaaa.csv',
                      style: TextStyle(
                        color: Color(0xFFbfa14a),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'où jjmmaaaa = jour mois année (ex: 20092025)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}










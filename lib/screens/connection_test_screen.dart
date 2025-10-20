import 'package:flutter/material.dart';
import '../services/remote_data_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final RemoteDataService _dataService = RemoteDataService();
  String _status = 'Initialisation...';
  bool _isLoading = false;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    debugPrint(message);
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _testConnection() async {
    _clearLogs();
    setState(() {
      _isLoading = true;
      _status = 'Test de connexion...';
    });

    try {
      _addLog('=== DÉBUT DU TEST DE CONNEXION ===');
      _addLog('Initialisation du service...');
      await _dataService.initialize();
      
      _addLog('Vérification de la connexion...');
      if (!_dataService.isConnected) {
        _addLog('❌ ERREUR: Non connecté au serveur');
        setState(() {
          _status = 'Non connecté au serveur';
          _isLoading = false;
        });
        return;
      }
      
      _addLog('✅ Connexion établie');
      _addLog('📋 Test du chargement du menu...');
      final menuItems = await _dataService.loadMenuItems();
      _addLog('✅ Menu chargé: ${menuItems.length} éléments');
      
      _addLog('🪑 Test du chargement des tables...');
      final tables = await _dataService.loadTables();
      _addLog('✅ Tables chargées: ${tables.length} tables');
      
      _addLog('=== TEST TERMINÉ AVEC SUCCÈS ===');
      setState(() {
        _status = 'Connexion OK - ${menuItems.length} articles, ${tables.length} tables';
        _isLoading = false;
      });
      
    } catch (e) {
      _addLog('❌ ERREUR: $e');
      _addLog('=== TEST ÉCHOUÉ ===');
      setState(() {
        _status = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        title: const Text('Test de Connexion'),
        backgroundColor: const Color(0xFFbfa14a),
        foregroundColor: const Color(0xFF231f2b),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut
            Card(
              color: const Color(0xFF2a2438),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFbfa14a)),
                        ),
                      )
                    else
                      Icon(
                        _status.contains('ERREUR') ? Icons.error : Icons.check_circle,
                        color: _status.contains('ERREUR') ? Colors.red : Colors.green,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informations de connexion
            Card(
              color: const Color(0xFF2a2438),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations de connexion:',
                      style: TextStyle(
                        color: Color(0xFFbfa14a),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'IP: ${_dataService.getConnectionInfo()['serverIp'] ?? 'Non connecté'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Nom: ${_dataService.getConnectionInfo()['deviceName'] ?? 'Non défini'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Connecté: ${_dataService.getConnectionInfo()['isConnected'] ? 'Oui' : 'Non'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Logs
            Expanded(
              child: Card(
                color: const Color(0xFF2a2438),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Logs de débogage:',
                            style: TextStyle(
                              color: Color(0xFFbfa14a),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: _clearLogs,
                            child: const Text(
                              'Effacer',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFbfa14a),
                      foregroundColor: const Color(0xFF231f2b),
                    ),
                    child: const Text('Relancer le test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/setup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reconfigurer'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Bouton pour aller aux commandes
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _dataService.isConnected ? () {
                  Navigator.pushNamed(context, '/orders');
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Aller aux commandes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

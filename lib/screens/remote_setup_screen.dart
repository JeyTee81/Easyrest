import 'package:flutter/material.dart';
import '../services/remote_client_service.dart';

class RemoteSetupScreen extends StatefulWidget {
  const RemoteSetupScreen({super.key});

  @override
  State<RemoteSetupScreen> createState() => _RemoteSetupScreenState();
}

class _RemoteSetupScreenState extends State<RemoteSetupScreen> {
  final _ipController = TextEditingController();
  final _nameController = TextEditingController();
  final _clientService = RemoteClientService();
  
  bool _isConnecting = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
    _setupClientCallbacks();
  }

  void _loadExistingSettings() {
    if (_clientService.serverIp != null) {
      _ipController.text = _clientService.serverIp!;
    }
    if (_clientService.deviceName != null) {
      _nameController.text = _clientService.deviceName!;
    }
  }

  void _setupClientCallbacks() {
    _clientService.onStatusChanged = (message) {
      setState(() {
        _statusMessage = message;
        _errorMessage = null;
      });
    };

    _clientService.onError = (error) {
      setState(() {
        _errorMessage = error;
        _isConnecting = false;
      });
    };

    _clientService.onSuccess = (message) {
      setState(() {
        _statusMessage = message;
        _isConnecting = false;
      });
      
      // Si la connexion est réussie, naviguer vers l'écran principal
      if (_clientService.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    };
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final name = _nameController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir l\'adresse IP';
      });
      return;
    }

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir un nom pour le contrôleur';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _statusMessage = 'Connexion en cours...';
    });

    final success = await _clientService.connectToServer(ip, name);
    
    if (!success) {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Image(
                image: AssetImage('assets/logo.png'),
                height: 120,
              ),
              const SizedBox(height: 32),
              
              // Titre
              const Text(
                'Configuration du Contrôleur',
                style: TextStyle(
                  color: Color(0xFFbfa14a),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous à l\'application EasyRest Tablette',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Formulaire
              Card(
                color: const Color(0xFF2a2438),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Champ IP
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse IP de la tablette',
                          hintText: '192.168.1.100',
                          prefixIcon: Icon(Icons.computer, color: Color(0xFFbfa14a)),
                          filled: true,
                          fillColor: Color(0xFFfff8e1),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        enabled: !_isConnecting,
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ nom
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du contrôleur',
                          hintText: 'Téléphone 1',
                          prefixIcon: Icon(Icons.phone_android, color: Color(0xFFbfa14a)),
                          filled: true,
                          fillColor: Color(0xFFfff8e1),
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_isConnecting,
                      ),
                      const SizedBox(height: 24),
                      
                      // Messages de statut
                      if (_statusMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusMessage!,
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Bouton de connexion
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isConnecting ? null : _connect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFbfa14a),
                            foregroundColor: const Color(0xFF231f2b),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isConnecting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF231f2b)),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Connexion...'),
                                  ],
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Card(
                color: const Color(0xFF2a2438),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instructions :',
                        style: TextStyle(
                          color: Color(0xFFbfa14a),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Assurez-vous que l\'application EasyRest Tablette est ouverte',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const Text(
                        '2. Vérifiez que les deux appareils sont sur le même réseau WiFi',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const Text(
                        '3. Saisissez l\'adresse IP affichée dans l\'application Tablette',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const Text(
                        '4. Donnez un nom unique à ce contrôleur',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

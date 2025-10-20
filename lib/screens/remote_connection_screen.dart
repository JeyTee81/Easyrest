import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/remote_server_service.dart';
import '../models/remote_device.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class RemoteConnectionScreen extends StatefulWidget {
  const RemoteConnectionScreen({super.key});

  @override
  State<RemoteConnectionScreen> createState() => _RemoteConnectionScreenState();
}

class _RemoteConnectionScreenState extends State<RemoteConnectionScreen> {
  final RemoteServerService _remoteServerService = RemoteServerService();
  bool _isServerRunning = false;
  List<RemoteDevice> _connectedDevices = [];
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeService() {
    // Configurer les callbacks du service
    _remoteServerService.onStatusChanged = (message) {
      setState(() {
        _statusMessage = message;
      });
    };

    _remoteServerService.onError = (error) {
      _showError(error);
    };

    _remoteServerService.onSuccess = (message) {
      _showSuccess(message);
    };

    _remoteServerService.onDevicesChanged = (devices) {
      setState(() {
        _connectedDevices = devices;
      });
    };

    // Mettre à jour l'état initial
    setState(() {
      _isServerRunning = _remoteServerService.isServerRunning;
      _connectedDevices = _remoteServerService.connectedDevices;
    });
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

  Future<void> _startServer() async {
    await _remoteServerService.startServer();
    setState(() {
      _isServerRunning = _remoteServerService.isServerRunning;
    });
  }

  Future<void> _stopServer() async {
    await _remoteServerService.stopServer();
    setState(() {
      _isServerRunning = _remoteServerService.isServerRunning;
    });
  }

  void _disconnectDevice(RemoteDevice device) {
    _remoteServerService.disconnectDevice(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text(
          'Contrôleurs distants',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
      ),
      body: Column(
        children: [
          // Server status and controls
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2438),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _isServerRunning ? Icons.wifi : Icons.wifi_off,
                      color: _isServerRunning ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isServerRunning ? 'Serveur actif' : 'Serveur inactif',
                      style: TextStyle(
                        color: _isServerRunning ? Colors.green : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_remoteServerService.ipAddress != null) ...[
                  Text(
                    'Adresse: ${_remoteServerService.serverUrl}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // QR Code for easy connection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: 'easyrest://${_remoteServerService.serverUrl}',
                      version: QrVersions.auto,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scannez ce QR code pour connecter un contrôleur distant',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                // Paramètre de démarrage automatique
                FutureBuilder<bool>(
                  future: _remoteServerService.isAutoStartEnabled(),
                  builder: (context, snapshot) {
                    final isAutoStartEnabled = snapshot.data ?? true;
                    return SwitchListTile(
                      title: const Text(
                        'Démarrage automatique',
                        style: TextStyle(color: Colors.white70),
                      ),
                      subtitle: const Text(
                        'Démarrer le serveur au lancement de l\'application',
                        style: TextStyle(color: Colors.white54),
                      ),
                      value: isAutoStartEnabled,
                      activeColor: const Color(0xFFbfa14a),
                      onChanged: (value) async {
                        await _remoteServerService.setAutoStartEnabled(value);
                        setState(() {});
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isServerRunning ? null : _startServer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFbfa14a),
                          foregroundColor: const Color(0xFF231f2b),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Démarrer le serveur'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isServerRunning ? _stopServer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Arrêter le serveur'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Connected devices
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFfff8e1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFbfa14a),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.devices,
                          color: Color(0xFF231f2b),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Appareils connectés (${_connectedDevices.length})',
                          style: const TextStyle(
                            color: Color(0xFF231f2b),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _connectedDevices.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.devices_other,
                                  size: 64,
                                  color: Color(0xFF231f2b),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Aucun appareil connecté',
                                  style: TextStyle(
                                    color: Color(0xFF231f2b),
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Démarrez le serveur et connectez des contrôleurs distants',
                                  style: TextStyle(
                                    color: Color(0xFF231f2b),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _connectedDevices.length,
                            itemBuilder: (context, index) {
                              final device = _connectedDevices[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: device.isConnected
                                        ? Colors.green
                                        : Colors.red,
                                    child: const Icon(
                                      Icons.phone_android,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    device.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(device.ip),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: device.isConnected
                                              ? Colors.green
                                              : Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          device.isConnected ? 'Connecté' : 'Déconnecté',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => _disconnectDevice(device),
                                        color: Colors.red,
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
            ),
          ),
        ],
      ),
    );
  }
}

// RemoteDevice est maintenant défini dans ../models/remote_device.dart 
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';
import '../models/table_restaurant.dart';
import '../models/order.dart';
import '../models/order_item.dart';

/// Service client pour communiquer avec easyrest_tablette
class RemoteClientService {
  static final RemoteClientService _instance = RemoteClientService._internal();
  factory RemoteClientService() => _instance;
  RemoteClientService._internal();

  Socket? _socket;
  String? _serverIp;
  int _serverPort = 8080;
  String? _deviceName;
  bool _isConnected = false;
  bool _isAuthenticated = false;

  // Callbacks
  Function(String)? onStatusChanged;
  Function(String)? onError;
  Function(String)? onSuccess;
  Function(List<MenuItem>)? onMenuReceived;
  Function(List<TableRestaurant>)? onTablesReceived;
  Function(Order)? onOrderResponse;

  // Getters
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;
  String? get serverIp => _serverIp;
  String? get deviceName => _deviceName;

  /// Initialise le service client
  Future<void> initialize() async {
    await _loadConnectionSettings();
  }

  /// Charge les paramètres de connexion depuis SharedPreferences
  Future<void> _loadConnectionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString('remote_server_ip');
    _deviceName = prefs.getString('remote_device_name');
  }

  /// Sauvegarde les paramètres de connexion
  Future<void> _saveConnectionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_serverIp != null) {
      await prefs.setString('remote_server_ip', _serverIp!);
    }
    if (_deviceName != null) {
      await prefs.setString('remote_device_name', _deviceName!);
    }
  }

  /// Se connecte au serveur easyrest_tablette
  Future<bool> connectToServer(String serverIp, String deviceName) async {
    try {
      _serverIp = serverIp;
      _deviceName = deviceName;
      
      onStatusChanged?.call('Connexion à $serverIp:$_serverPort...');
      
      _socket = await Socket.connect(serverIp, _serverPort, timeout: const Duration(seconds: 10));
      _isConnected = true;
      
      // Écouter les messages du serveur
      _socket!.listen(
        _handleServerMessage,
        onError: _handleConnectionError,
        onDone: _handleConnectionClosed,
      );

      // S'authentifier
      await _authenticate();
      
      // Sauvegarder les paramètres
      await _saveConnectionSettings();
      
      onSuccess?.call('Connecté à $serverIp');
      return true;
    } catch (e) {
      _isConnected = false;
      onError?.call('Erreur de connexion: $e');
      return false;
    }
  }

  /// S'authentifie auprès du serveur
  Future<void> _authenticate() async {
    if (_socket == null || _deviceName == null) return;
    
    final authMessage = {
      'type': 'auth',
      'deviceName': _deviceName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(authMessage);
  }

  /// Gère les messages reçus du serveur
  void _handleServerMessage(List<int> data) {
    try {
      final message = utf8.decode(data);
      debugPrint('Message reçu: ${message.length} caractères');
      debugPrint('Message brut: ${message.substring(0, message.length > 200 ? 200 : message.length)}...');
      
      // Diviser les messages par retour à la ligne
      final lines = message.split('\n').where((line) => line.trim().isNotEmpty).toList();
      debugPrint('Nombre de lignes trouvées: ${lines.length}');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        debugPrint('Traitement de la ligne ${i + 1}: ${line.length} caractères');
        debugPrint('Début de la ligne: ${line.substring(0, line.length > 100 ? 100 : line.length)}...');
        
        try {
          final json = jsonDecode(line.trim());
          debugPrint('Traitement du message: ${json['type']}');
          
          switch (json['type']) {
            case 'auth_response':
              _handleAuthResponse(json);
              break;
            case 'menu_data':
              _handleMenuData(json);
              break;
            case 'tables_data':
              _handleTablesData(json);
              break;
            case 'order_response':
              _handleOrderResponse(json);
              break;
            case 'pong':
              // Réponse au ping
              break;
            case 'error':
              onError?.call(json['message'] ?? 'Erreur du serveur');
              break;
          }
        } catch (e) {
          debugPrint('Erreur lors du parsing de la ligne ${i + 1}: $line');
          debugPrint('Erreur: $e');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement du message: $e');
      onError?.call('Erreur lors du traitement du message: $e');
    }
  }

  /// Gère la réponse d'authentification
  void _handleAuthResponse(Map<String, dynamic> data) {
    if (data['status'] == 'success') {
      _isAuthenticated = true;
      onSuccess?.call('Authentification réussie');
    } else {
      _isAuthenticated = false;
      onError?.call('Échec de l\'authentification: ${data['message']}');
    }
  }

  /// Gère les données de menu reçues
  void _handleMenuData(Map<String, dynamic> data) {
    try {
      debugPrint('_handleMenuData: Réception des données de menu');
      if (data['error'] != null) {
        debugPrint('_handleMenuData: ERREUR du serveur - ${data['error']}');
        onError?.call(data['error']);
        return;
      }
      
      final List<dynamic> itemsData = data['items'] ?? [];
      debugPrint('_handleMenuData: ${itemsData.length} éléments reçus');
      final menuItems = itemsData.map((item) => MenuItem.fromMap(item)).toList();
      debugPrint('_handleMenuData: ${menuItems.length} MenuItem créés');
      onMenuReceived?.call(menuItems);
    } catch (e) {
      debugPrint('_handleMenuData: ERREUR lors du parsing - $e');
      onError?.call('Erreur lors du parsing du menu: $e');
    }
  }

  /// Gère les données de tables reçues
  void _handleTablesData(Map<String, dynamic> data) {
    try {
      if (data['error'] != null) {
        onError?.call(data['error']);
        return;
      }
      
      final List<dynamic> tablesData = data['tables'] ?? [];
      final tables = tablesData.map((table) => TableRestaurant.fromMap(table)).toList();
      onTablesReceived?.call(tables);
    } catch (e) {
      onError?.call('Erreur lors du parsing des tables: $e');
    }
  }

  /// Gère la réponse de commande
  void _handleOrderResponse(Map<String, dynamic> data) {
    try {
      if (data['error'] != null) {
        onError?.call(data['error']);
        return;
      }
      
      final orderData = data['order'];
      if (orderData != null) {
        final order = Order.fromMap(orderData);
        onOrderResponse?.call(order);
      }
    } catch (e) {
      onError?.call('Erreur lors du parsing de la commande: $e');
    }
  }

  /// Gère les erreurs de connexion
  void _handleConnectionError(error) {
    _isConnected = false;
    _isAuthenticated = false;
    onError?.call('Erreur de connexion: $error');
  }

  /// Gère la fermeture de connexion
  void _handleConnectionClosed() {
    _isConnected = false;
    _isAuthenticated = false;
    onStatusChanged?.call('Connexion fermée');
  }

  /// Envoie un message au serveur
  void _sendMessage(Map<String, dynamic> message) {
    if (_socket == null) {
      onError?.call('Pas de connexion au serveur');
      return;
    }
    
    try {
      final jsonString = jsonEncode(message);
      final data = utf8.encode('$jsonString\n'); // Ajouter un retour à la ligne comme séparateur
      _socket!.add(data);
      debugPrint('Envoi du message: ${message['type']}');
    } catch (e) {
      onError?.call('Erreur lors de l\'envoi du message: $e');
    }
  }

  /// Demande le menu au serveur
  void requestMenu() {
    debugPrint('requestMenu: Début');
    if (!_isAuthenticated) {
      debugPrint('requestMenu: ERREUR - Non authentifié');
      onError?.call('Non authentifié');
      return;
    }
    
    debugPrint('requestMenu: Envoi de la demande de menu');
    _sendMessage({
      'type': 'request_menu',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Demande les tables au serveur
  void requestTables() {
    if (!_isAuthenticated) {
      onError?.call('Non authentifié');
      return;
    }
    
    _sendMessage({
      'type': 'request_tables',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Envoie une commande au serveur
  void sendOrder(Order order, List<OrderItem> orderItems) {
    if (!_isAuthenticated) {
      onError?.call('Non authentifié');
      return;
    }
    
    _sendMessage({
      'type': 'order',
      'order': order.toMap(),
      'orderItems': orderItems.map((item) => item.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Envoie un ping au serveur
  void ping() {
    _sendMessage({
      'type': 'ping',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Déconnecte du serveur
  Future<void> disconnect() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }
    _isConnected = false;
    _isAuthenticated = false;
    onStatusChanged?.call('Déconnecté');
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    await disconnect();
  }
}

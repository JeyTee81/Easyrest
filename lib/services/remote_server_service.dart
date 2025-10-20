import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_database_service.dart';
import 'production_service.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/table_restaurant.dart';
import '../models/remote_device.dart';

class RemoteServerService {
  static final RemoteServerService _instance = RemoteServerService._internal();
  factory RemoteServerService() => _instance;
  RemoteServerService._internal();

  final NetworkInfo _networkInfo = NetworkInfo();
  final ApiDatabaseService _dbService = ApiDatabaseService();
  
  String? _ipAddress;
  final int _port = 8080;
  bool _isServerRunning = false;
  final List<RemoteDevice> _connectedDevices = [];
  ServerSocket? _serverSocket;
  
  // Callbacks pour les notifications
  Function(String)? onStatusChanged;
  Function(String)? onError;
  Function(String)? onSuccess;
  Function(List<RemoteDevice>)? onDevicesChanged;

  // Getters
  bool get isServerRunning => _isServerRunning;
  String? get ipAddress => _ipAddress;
  List<RemoteDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  String? get serverUrl => _ipAddress != null ? '$_ipAddress:$_port' : null;

  /// Initialise le service et récupère l'adresse IP
  Future<void> initialize() async {
    try {
      _ipAddress = await _networkInfo.getWifiIP();
      debugPrint('Adresse IP récupérée: $_ipAddress');
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'adresse IP: $e');
      onError?.call('Erreur lors de la récupération de l\'adresse IP: $e');
    }
  }

  /// Vérifie si le démarrage automatique est activé
  Future<bool> isAutoStartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remote_server_auto_start') ?? true; // Par défaut activé
  }

  /// Active ou désactive le démarrage automatique
  Future<void> setAutoStartEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remote_server_auto_start', enabled);
  }

  /// Démarre le serveur distant
  Future<void> startServer() async {
    if (_isServerRunning) {
      onError?.call('Le serveur est déjà en cours d\'exécution');
      return;
    }

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      _isServerRunning = true;
      onStatusChanged?.call('Serveur démarré sur $_ipAddress:$_port');
      onSuccess?.call('Serveur démarré sur $_ipAddress:$_port');

      _serverSocket!.listen((Socket client) {
        _handleClientConnection(client);
      });

      debugPrint('Serveur distant démarré sur $_ipAddress:$_port');
    } catch (e) {
      _isServerRunning = false;
      onError?.call('Erreur lors du démarrage du serveur: $e');
      debugPrint('Erreur lors du démarrage du serveur: $e');
    }
  }

  /// Arrête le serveur distant
  Future<void> stopServer() async {
    if (!_isServerRunning) {
      onError?.call('Le serveur n\'est pas en cours d\'exécution');
      return;
    }

    try {
      if (_serverSocket != null) {
        await _serverSocket!.close();
        _serverSocket = null;
      }
      _isServerRunning = false;
      _connectedDevices.clear();
      onStatusChanged?.call('Serveur arrêté');
      onSuccess?.call('Serveur arrêté');
      onDevicesChanged?.call(_connectedDevices);

      debugPrint('Serveur distant arrêté');
    } catch (e) {
      onError?.call('Erreur lors de l\'arrêt du serveur: $e');
      debugPrint('Erreur lors de l\'arrêt du serveur: $e');
    }
  }

  /// Démarre automatiquement le serveur si activé
  Future<void> autoStartIfEnabled() async {
    final isAutoStartEnabled = await this.isAutoStartEnabled();
    if (isAutoStartEnabled && !_isServerRunning) {
      await initialize();
      await startServer();
    }
  }

  /// Gère les connexions clients
  void _handleClientConnection(Socket client) {
    final device = RemoteDevice(
      id: client.hashCode.toString(),
      name: 'Appareil ${_connectedDevices.length + 1}',
      ip: client.remoteAddress.address,
      socket: client,
      isConnected: true,
    );

    _connectedDevices.add(device);
    onDevicesChanged?.call(_connectedDevices);

    client.listen(
      (data) {
        _handleClientMessage(device, data);
      },
      onError: (error) {
        _handleClientDisconnection(device);
      },
      onDone: () {
        _handleClientDisconnection(device);
      },
    );

    debugPrint('Nouveau client connecté: ${device.name} (${device.ip})');
  }

  /// Gère les messages des clients
  void _handleClientMessage(RemoteDevice device, List<int> data) {
    try {
      final message = utf8.decode(data);
      final json = jsonDecode(message);
      
      switch (json['type']) {
        case 'auth':
          _handleAuth(device, json);
          break;
        case 'request_menu':
          _handleMenuRequest(device);
          break;
        case 'request_tables':
          _handleTablesRequest(device);
          break;
        case 'order':
          _handleOrder(device, json);
          break;
        case 'ping':
          _sendResponse(device, {'type': 'pong'});
          break;
      }
    } catch (e) {
      onError?.call('Erreur lors du traitement du message: $e');
      debugPrint('Erreur lors du traitement du message: $e');
    }
  }

  /// Gère l'authentification des clients
  void _handleAuth(RemoteDevice device, Map<String, dynamic> data) {
    final deviceName = data['deviceName'] ?? 'Appareil inconnu';
    device.name = deviceName;
    onDevicesChanged?.call(_connectedDevices);
    
    _sendResponse(device, {
      'type': 'auth_response',
      'status': 'success',
      'message': 'Authentification réussie',
    });

    debugPrint('Client authentifié: $deviceName');
  }

  /// Gère les demandes de menu
  Future<void> _handleMenuRequest(RemoteDevice device) async {
    try {
      final menuItems = await _dbService.getMenuItems();
      final menuData = menuItems.map((item) => {
        'id': item.id,
        'name': item.name,
        'priceHt': item.priceHt,
        'priceTtc': item.priceTtc,
        'tvaRate': item.tvaRate,
        'description': item.description,
        'category': item.category,
        'subcategory': item.subcategory,
        'type': item.type,
        'printer': item.printer,
        'isAvailable': item.isAvailable,
        'isPresetMenu': item.isPresetMenu,
      }).toList();

      _sendResponse(device, {
        'type': 'menu_data',
        'items': menuData,
      });
    } catch (e) {
      _sendResponse(device, {
        'type': 'menu_data',
        'error': 'Erreur lors du chargement du menu: $e',
        'items': [],
      });
    }
  }

  /// Gère les demandes de tables
  Future<void> _handleTablesRequest(RemoteDevice device) async {
    try {
      final tables = await _dbService.getTables();
      final tableData = tables.map((table) => {
        'id': table.id,
        'number': table.number,
        'capacity': table.capacity,
        'status': table.status,
        'roomId': table.roomId,
      }).toList();

      _sendResponse(device, {
        'type': 'tables_data',
        'tables': tableData,
      });
    } catch (e) {
      _sendResponse(device, {
        'type': 'tables_data',
        'error': 'Erreur lors du chargement des tables: $e',
        'tables': [],
      });
    }
  }

  /// Gère les commandes
  Future<void> _handleOrder(RemoteDevice device, Map<String, dynamic> data) async {
    try {
      final tableName = data['table'];
      final items = data['items'] as List;
      final timestamp = data['timestamp'];
      final autoValidate = data['autoValidate'] ?? false;

      // Trouver la table
      final tables = await _dbService.getTables();
      final table = tables.firstWhere(
        (t) => 'Table ${t.number}' == tableName,
        orElse: () => throw Exception('Table non trouvée: $tableName'),
      );

      // Créer les articles de commande
      final orderItems = <OrderItem>[];
      double totalHt = 0;
      double totalTtc = 0;
      double totalTva = 0;

      for (final itemData in items) {
        final orderItem = OrderItem.fromMenuItem(
          itemData['id'],
          itemData['name'],
          itemData['priceHt'],
          itemData['priceTtc'],
          itemData['tvaRate'],
          itemData['quantity'],
        );

        orderItems.add(orderItem);
        totalHt += orderItem.totalHt;
        totalTtc += orderItem.totalTtc;
        totalTva += orderItem.totalTva;
      }

      // Créer la commande
      if (table.id == null) {
        throw Exception('ID de table manquant pour: $tableName');
      }
      
      // Pour les commandes Pocky, toujours créer une commande active (pas de facture immédiate)
      final order = Order.fromItems(
        tableId: table.id!,
        items: orderItems,
        status: 'active', // Toujours 'active' pour les commandes Pocky
        createdAt: DateTime.parse(timestamp),
      );

      final orderId = await _dbService.insertOrder(order);

      // Ajouter les articles à la base de données
      for (final orderItem in orderItems) {
        final itemWithOrderId = orderItem.copyWith(orderId: orderId);
        await _dbService.insertOrderItem(itemWithOrderId);
      }

      // Mettre à jour le statut de la table à "Occupée"
      try {
        final updatedTable = TableRestaurant(
          id: table.id,
          number: table.number,
          capacity: table.capacity,
          roomId: table.roomId,
          status: 'Occupée',
        );
        await _dbService.updateTable(updatedTable);
        debugPrint('Table ${table.number} mise à jour: Libre -> Occupée');
      } catch (e) {
        debugPrint('Erreur lors de la mise à jour du statut de la table: $e');
      }

      // Générer les bons de production
      try {
        final productionService = ProductionService();
        final menuItems = await _dbService.getMenuItems();
        final productionOrders = await productionService.generateProductionOrders(
          order.copyWith(id: orderId),
          orderItems,
          menuItems,
        );

        // Afficher les bons de production (dans une vraie app, ceci serait envoyé aux imprimantes)
        for (final entry in productionOrders.entries) {
          final printerId = entry.key;
          final productionOrder = entry.value;
          
          debugPrint('=== BON DE PRODUCTION POCKY - ${printerId.toUpperCase()} ===');
          debugPrint(productionOrder);
          debugPrint('=== FIN DU BON ===');
        }
      } catch (e) {
        debugPrint('Erreur lors de la génération des bons de production: $e');
      }

      // Note: Pas de création de facture automatique pour les commandes Pocky
      // La facture sera créée plus tard via la caisse

      _sendResponse(device, {
        'type': 'order_response',
        'status': 'success',
        'message': 'Commande reçue et enregistrée',
        'orderId': orderId,
      });

      onSuccess?.call('Commande reçue de ${device.name} pour la table $tableName');
      debugPrint('Commande reçue de ${device.name} pour la table $tableName');
    } catch (e) {
      _sendResponse(device, {
        'type': 'order_response',
        'status': 'error',
        'message': 'Erreur lors du traitement de la commande: $e',
      });
      onError?.call('Erreur lors du traitement de la commande: $e');
      debugPrint('Erreur lors du traitement de la commande: $e');
    }
  }

  /// Gère la déconnexion des clients
  void _handleClientDisconnection(RemoteDevice device) {
    _connectedDevices.removeWhere((d) => d.id == device.id);
    onDevicesChanged?.call(_connectedDevices);
    debugPrint('Client déconnecté: ${device.name}');
  }

  /// Envoie une réponse au client
  void _sendResponse(RemoteDevice device, Map<String, dynamic> response) {
    try {
      final jsonString = jsonEncode(response);
      final data = utf8.encode('$jsonString\n'); // Ajouter un retour à la ligne comme séparateur
      device.socket.add(data);
      debugPrint('Envoi de la réponse: ${response['type']}');
    } catch (e) {
      onError?.call('Erreur lors de l\'envoi de la réponse: $e');
      debugPrint('Erreur lors de l\'envoi de la réponse: $e');
    }
  }

  /// Déconnecte un appareil spécifique
  void disconnectDevice(RemoteDevice device) {
    try {
      device.socket.close();
      _connectedDevices.remove(device);
      onDevicesChanged?.call(_connectedDevices);
      onSuccess?.call('Appareil déconnecté');
      debugPrint('Appareil déconnecté: ${device.name}');
    } catch (e) {
      onError?.call('Erreur lors de la déconnexion: $e');
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    await stopServer();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'remote_client_service.dart';
import '../models/menu_item.dart';
import '../models/table_restaurant.dart';
import '../models/order.dart';
import '../models/order_item.dart';

/// Service de données qui utilise la communication avec easyrest_tablette
class RemoteDataService {
  static final RemoteDataService _instance = RemoteDataService._internal();
  factory RemoteDataService() => _instance;
  RemoteDataService._internal();

  final RemoteClientService _clientService = RemoteClientService();
  
  // Cache des données
  List<MenuItem> _menuItems = [];
  List<TableRestaurant> _tables = [];
  
  // Stream controllers pour les données
  final StreamController<List<MenuItem>> _menuController = StreamController<List<MenuItem>>.broadcast();
  final StreamController<List<TableRestaurant>> _tablesController = StreamController<List<TableRestaurant>>.broadcast();
  final StreamController<Order?> _orderController = StreamController<Order?>.broadcast();

  // Getters
  List<MenuItem> get menuItems => List.unmodifiable(_menuItems);
  List<TableRestaurant> get tables => List.unmodifiable(_tables);
  Stream<List<MenuItem>> get menuStream => _menuController.stream;
  Stream<List<TableRestaurant>> get tablesStream => _tablesController.stream;
  Stream<Order?> get orderStream => _orderController.stream;

  /// Initialise le service
  Future<void> initialize() async {
    await _clientService.initialize();
    _setupClientCallbacks();
  }

  /// Configure les callbacks du client
  void _setupClientCallbacks() {
    _clientService.onMenuReceived = (menuItems) {
      _menuItems = menuItems;
      _menuController.add(_menuItems);
      debugPrint('Menu reçu: ${menuItems.length} éléments');
    };

    _clientService.onTablesReceived = (tables) {
      _tables = tables;
      _tablesController.add(_tables);
      debugPrint('Tables reçues: ${tables.length} tables');
    };

    _clientService.onOrderResponse = (order) {
      _orderController.add(order);
      debugPrint('Commande reçue: ${order.id}');
    };

    _clientService.onError = (error) {
      debugPrint('Erreur RemoteDataService: $error');
    };
  }

  /// Vérifie si le service est connecté
  bool get isConnected => _clientService.isConnected && _clientService.isAuthenticated;

  /// Se connecte au serveur
  Future<bool> connectToServer(String serverIp, String deviceName) async {
    return await _clientService.connectToServer(serverIp, deviceName);
  }

  /// Déconnecte du serveur
  Future<void> disconnect() async {
    await _clientService.disconnect();
  }

  /// Charge le menu depuis le serveur
  Future<List<MenuItem>> loadMenuItems() async {
    debugPrint('=== loadMenuItems: Début ===');
    if (!isConnected) {
      debugPrint('ERREUR: Non connecté au serveur');
      throw Exception('Non connecté au serveur');
    }

    debugPrint('Envoi de la demande de menu...');
    _clientService.requestMenu();
    
    debugPrint('Attente de la réponse du menu...');
    // Attendre la réponse avec un timeout
    final result = await _waitForMenuResponse();
    debugPrint('=== loadMenuItems: Fin - ${result.length} éléments ===');
    return result;
  }

  /// Attend la réponse du menu avec timeout
  Future<List<MenuItem>> _waitForMenuResponse() async {
    debugPrint('_waitForMenuResponse: Début de l\'attente...');
    final completer = Completer<List<MenuItem>>();
    late StreamSubscription subscription;
    
    subscription = _menuController.stream.listen((menuItems) {
      debugPrint('_waitForMenuResponse: Menu reçu - ${menuItems.length} éléments');
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete(menuItems);
      }
    });

    // Timeout après 10 secondes
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        debugPrint('_waitForMenuResponse: TIMEOUT après 10 secondes');
        subscription.cancel();
        completer.completeError(Exception('Timeout lors du chargement du menu'));
      }
    });

    return completer.future;
  }

  /// Charge les tables depuis le serveur
  Future<List<TableRestaurant>> loadTables() async {
    if (!isConnected) {
      throw Exception('Non connecté au serveur');
    }

    _clientService.requestTables();
    
    // Attendre la réponse avec un timeout
    return await _waitForTablesResponse();
  }

  /// Attend la réponse des tables avec timeout
  Future<List<TableRestaurant>> _waitForTablesResponse() async {
    final completer = Completer<List<TableRestaurant>>();
    late StreamSubscription subscription;
    
    subscription = _tablesController.stream.listen((tables) {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete(tables);
      }
    });

    // Timeout après 10 secondes
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(Exception('Timeout lors du chargement des tables'));
      }
    });

    return completer.future;
  }

  /// Envoie une commande au serveur
  Future<Order> sendOrder(Order order, List<OrderItem> orderItems) async {
    if (!isConnected) {
      throw Exception('Non connecté au serveur');
    }

    _clientService.sendOrder(order, orderItems);
    
    // Attendre la réponse avec un timeout
    return await _waitForOrderResponse();
  }

  /// Attend la réponse de commande avec timeout
  Future<Order> _waitForOrderResponse() async {
    final completer = Completer<Order>();
    late StreamSubscription subscription;
    
    subscription = _orderController.stream.listen((order) {
      if (order != null && !completer.isCompleted) {
        subscription.cancel();
        completer.complete(order);
      }
    });

    // Timeout après 15 secondes
    Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(Exception('Timeout lors de l\'envoi de la commande'));
      }
    });

    return completer.future;
  }

  /// Ping le serveur pour vérifier la connexion
  void ping() {
    _clientService.ping();
  }

  /// Obtient les informations de connexion
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': isConnected,
      'serverIp': _clientService.serverIp,
      'deviceName': _clientService.deviceName,
    };
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    await _clientService.dispose();
    await _menuController.close();
    await _tablesController.close();
    await _orderController.close();
  }
}

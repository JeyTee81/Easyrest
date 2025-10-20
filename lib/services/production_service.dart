import '../models/order.dart';
import '../models/order_item.dart';
import '../models/menu_item.dart';
import '../models/printer.dart';
import '../models/company.dart';
import '../services/company_service.dart';

class ProductionService {
  static const int _maxLineLength = 32; // Largeur maximale pour imprimante thermique
  static const String _separator = '--------------------------------';
  
  final CompanyService _companyService = CompanyService();

  /// Générer les bons de production pour une commande
  Future<Map<String, String>> generateProductionOrders(Order order, List<OrderItem> orderItems, List<MenuItem> menuItems) async {
    final company = await _companyService.getCompany();
    final productionOrders = <String, String>{};

    // Grouper les articles par imprimante
    final itemsByPrinter = <String, List<Map<String, dynamic>>>{};
    
    for (final orderItem in orderItems) {
      // Trouver le MenuItem correspondant
      final menuItem = menuItems.firstWhere(
        (item) => item.id == orderItem.productId,
        orElse: () => MenuItem(
          id: orderItem.productId,
          name: orderItem.productName,
          priceHt: orderItem.unitPrice,
          priceTtc: orderItem.unitPrice,
          tvaRate: '20%',
          description: '',
          category: 'Inconnu',
          type: 'Produit',
          printer: 'cuisine',
          isAvailable: true,
        ),
      );

      final printerId = menuItem.printer;
      
      if (!itemsByPrinter.containsKey(printerId)) {
        itemsByPrinter[printerId] = [];
      }
      
      itemsByPrinter[printerId]!.add({
        'orderItem': orderItem,
        'menuItem': menuItem,
      });
    }

    // Générer un bon pour chaque imprimante
    for (final entry in itemsByPrinter.entries) {
      final printerId = entry.key;
      final items = entry.value;
      
      final printer = Printer.getByName(printerId);
      final printerName = printer?.name ?? printerId;
      
      final productionOrder = _generateProductionOrder(
        order: order,
        items: items,
        printerName: printerName,
        printerLocation: printer?.location ?? 'Non définie',
        company: company,
      );
      
      productionOrders[printerId] = productionOrder;
    }

    return productionOrders;
  }

  /// Générer un bon de production pour une imprimante spécifique
  String _generateProductionOrder({
    required Order order,
    required List<Map<String, dynamic>> items,
    required String printerName,
    required String printerLocation,
    Company? company,
  }) {
    final buffer = StringBuffer();

    // En-tête de l'entreprise
    if (company != null) {
      _addCompanyHeader(buffer, company);
    }

    // En-tête du bon de production
    _addProductionHeader(buffer, order, printerName, printerLocation);

    // Séparateur
    buffer.writeln(_separator);

    // Détail des articles
    _addProductionItems(buffer, items);

    // Séparateur
    buffer.writeln(_separator);

    // Pied de page
    _addProductionFooter(buffer, printerName);

    return buffer.toString();
  }

  /// Ajouter l'en-tête de l'entreprise
  void _addCompanyHeader(StringBuffer buffer, Company company) {
    buffer.writeln(_centerText(company.name.toUpperCase()));
    buffer.writeln();
    buffer.writeln(_centerText('BON DE PRODUCTION'));
    buffer.writeln();
  }

  /// Ajouter l'en-tête du bon de production
  void _addProductionHeader(StringBuffer buffer, Order order, String printerName, String printerLocation) {
    // Numéro de commande
    buffer.writeln('COMMANDE N° ${order.id}');
    buffer.writeln();
    
    // Date et heure
    final now = DateTime.now();
    buffer.writeln('Date: ${_formatDate(now)}');
    buffer.writeln('Heure: ${_formatTime(now)}');
    
    // Table
    buffer.writeln('Table: ${order.tableName}');
    
    // Serveur (si disponible)
    if (order.staffName != null && order.staffName!.isNotEmpty) {
      buffer.writeln('Serveur: ${order.staffName}');
    }
    
    buffer.writeln();
    buffer.writeln('DESTINATION: $printerName');
    buffer.writeln('LIEU: $printerLocation');
    buffer.writeln();
  }

  /// Ajouter le détail des articles
  void _addProductionItems(StringBuffer buffer, List<Map<String, dynamic>> items) {
    buffer.writeln('ARTICLES À PRÉPARER:');
    buffer.writeln();

    for (final itemData in items) {
      final orderItem = itemData['orderItem'] as OrderItem;
      final menuItem = itemData['menuItem'] as MenuItem;
      
      // Nom du produit
      buffer.writeln('${orderItem.quantity}x ${orderItem.productName}');
      
      // Description si disponible
      if (menuItem.description.isNotEmpty) {
        _addWrappedText(buffer, '  ${menuItem.description}');
      }
      
      // Instructions spéciales (à ajouter plus tard)
      if (orderItem.specialInstructions != null && orderItem.specialInstructions!.isNotEmpty) {
        buffer.writeln('  NOTE: ${orderItem.specialInstructions}');
      }
      
      buffer.writeln();
    }
  }

  /// Ajouter le pied de page
  void _addProductionFooter(StringBuffer buffer, String printerName) {
    buffer.writeln(_separator);
    buffer.writeln();
    buffer.writeln(_centerText('BON POUR $printerName'));
    buffer.writeln();
    buffer.writeln(_centerText('EasyRest - Système de caisse'));
    
    // Espaces pour couper le bon
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
  }

  /// Centrer un texte
  String _centerText(String text) {
    if (text.length >= _maxLineLength) {
      return text;
    }
    
    final padding = (_maxLineLength - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Ajouter du texte avec retour à la ligne automatique
  void _addWrappedText(StringBuffer buffer, String text) {
    if (text.length <= _maxLineLength) {
      buffer.writeln(text);
      return;
    }
    
    final words = text.split(' ');
    String currentLine = '';
    
    for (final word in words) {
      if ((currentLine + word).length <= _maxLineLength) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        if (currentLine.isNotEmpty) {
          buffer.writeln(currentLine);
        }
        currentLine = word;
      }
    }
    
    if (currentLine.isNotEmpty) {
      buffer.writeln(currentLine);
    }
  }

  /// Formater une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formater une heure
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Générer un bon de production complet (tous les articles sur une seule imprimante)
  Future<String> generateCompleteProductionOrder(Order order, List<OrderItem> orderItems, List<MenuItem> menuItems) async {
    final company = await _companyService.getCompany();
    final buffer = StringBuffer();

    // En-tête de l'entreprise
    if (company != null) {
      _addCompanyHeader(buffer, company);
    }

    // En-tête du bon de production complet
    _addCompleteProductionHeader(buffer, order);

    // Séparateur
    buffer.writeln(_separator);

    // Grouper les articles par catégorie
    final itemsByCategory = <String, List<Map<String, dynamic>>>{};
    
    for (final orderItem in orderItems) {
      final menuItem = menuItems.firstWhere(
        (item) => item.id == orderItem.productId,
        orElse: () => MenuItem(
          id: orderItem.productId,
          name: orderItem.productName,
          priceHt: orderItem.unitPrice,
          priceTtc: orderItem.unitPrice,
          tvaRate: '20%',
          description: '',
          category: 'Inconnu',
          type: 'Produit',
          printer: 'cuisine',
          isAvailable: true,
        ),
      );

      final category = menuItem.category;
      
      if (!itemsByCategory.containsKey(category)) {
        itemsByCategory[category] = [];
      }
      
      itemsByCategory[category]!.add({
        'orderItem': orderItem,
        'menuItem': menuItem,
      });
    }

    // Afficher les articles par catégorie
    for (final entry in itemsByCategory.entries) {
      final category = entry.key;
      final items = entry.value;
      
      buffer.writeln('$category:'.toUpperCase());
      buffer.writeln();
      
      for (final itemData in items) {
        final orderItem = itemData['orderItem'] as OrderItem;
        final menuItem = itemData['menuItem'] as MenuItem;
        
        buffer.writeln('${orderItem.quantity}x ${orderItem.productName}');
        
        if (menuItem.description.isNotEmpty) {
          _addWrappedText(buffer, '  ${menuItem.description}');
        }
        
        if (orderItem.specialInstructions != null && orderItem.specialInstructions!.isNotEmpty) {
          buffer.writeln('  NOTE: ${orderItem.specialInstructions}');
        }
        
        buffer.writeln();
      }
      
      buffer.writeln(_separator);
      buffer.writeln();
    }

    // Pied de page
    _addProductionFooter(buffer, 'CUISINE COMPLÈTE');

    return buffer.toString();
  }

  /// Ajouter l'en-tête du bon de production complet
  void _addCompleteProductionHeader(StringBuffer buffer, Order order) {
    buffer.writeln('COMMANDE COMPLÈTE N° ${order.id}');
    buffer.writeln();
    
    final now = DateTime.now();
    buffer.writeln('Date: ${_formatDate(now)}');
    buffer.writeln('Heure: ${_formatTime(now)}');
    buffer.writeln('Table: ${order.tableName}');
    
    if (order.staffName != null && order.staffName!.isNotEmpty) {
      buffer.writeln('Serveur: ${order.staffName}');
    }
    
    buffer.writeln();
    buffer.writeln('DESTINATION: CUISINE PRINCIPALE');
    buffer.writeln();
  }
}









import '../models/company.dart';
import '../models/bill.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/company_service.dart';

class ReceiptPrinterService {
  static const int _maxLineLength = 32; // Largeur maximale pour imprimante thermique
  static const String _separator = '--------------------------------';
  
  final CompanyService _companyService = CompanyService();

  /// Générer le contenu du ticket de caisse
  Future<String> generateReceiptContent(Bill bill, Order order, List<OrderItem> orderItems) async {
    final company = await _companyService.getCompany();
    final buffer = StringBuffer();

    // En-tête de l'entreprise
    if (company != null) {
      _addCompanyHeader(buffer, company);
    }

    // Informations de la facture
    _addBillInfo(buffer, bill, order);

    // Séparateur
    buffer.writeln(_separator);

    // Détail des articles
    _addOrderItems(buffer, orderItems);

    // Séparateur
    buffer.writeln(_separator);

    // Totaux et TVA
    _addTotalsAndVat(buffer, bill);

    // Pied de page
    _addFooter(buffer, company);

    return buffer.toString();
  }

  /// Ajouter l'en-tête de l'entreprise
  void _addCompanyHeader(StringBuffer buffer, Company company) {
    // Nom de l'entreprise (centré)
    buffer.writeln(_centerText(company.name.toUpperCase()));
    buffer.writeln();

    // Adresse
    _addWrappedText(buffer, company.address);
    buffer.writeln();

    // Téléphone
    if (company.phone.isNotEmpty) {
      buffer.writeln('Tél: ${company.phone}');
    }

    // Email (si disponible)
    if (company.email != null && company.email!.isNotEmpty) {
      buffer.writeln('Email: ${company.email}');
    }

    // Site web (si disponible)
    if (company.website != null && company.website!.isNotEmpty) {
      buffer.writeln('Web: ${company.website}');
    }

    buffer.writeln();
    buffer.writeln(_separator);
    buffer.writeln();
  }

  /// Ajouter les informations de la facture
  void _addBillInfo(StringBuffer buffer, Bill bill, Order order) {
    // Numéro de facture
    buffer.writeln('FACTURE N° ${bill.id}');
    
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
  }

  /// Ajouter le détail des articles
  void _addOrderItems(StringBuffer buffer, List<OrderItem> orderItems) {
    buffer.writeln('DÉTAIL DES ARTICLES');
    buffer.writeln();

    for (final item in orderItems) {
      // Nom du produit
      buffer.writeln(item.productName);
      
      // Quantité et prix unitaire
      final quantity = item.quantity.toString();
      final unitPrice = item.unitPrice.toStringAsFixed(2);
      final totalPrice = item.totalPrice.toStringAsFixed(2);
      
      // Ligne formatée: "2 x 15.50€ = 31.00€"
      final line = '$quantity x ${unitPrice}€ = ${totalPrice}€';
      buffer.writeln(_alignRight(line));
      
      // TVA si applicable
      final tvaRateDouble = _parseTvaRate(item.tvaRate);
      if (tvaRateDouble > 0) {
        buffer.writeln('  TVA ${(tvaRateDouble * 100).toInt()}%');
      }
      
      buffer.writeln();
    }
  }

  /// Ajouter les totaux et la ventilation TVA
  void _addTotalsAndVat(StringBuffer buffer, Bill bill) {
    buffer.writeln('TOTAUX');
    buffer.writeln();

    // Total HT
    buffer.writeln(_alignRight('Total HT: ${bill.totalHt.toStringAsFixed(2)}€'));
    
    // TVA
    buffer.writeln(_alignRight('TVA: ${bill.totalTva.toStringAsFixed(2)}€'));
    
    // Total TTC
    buffer.writeln(_alignRight('TOTAL TTC: ${bill.totalTtc.toStringAsFixed(2)}€'));
    
    // Moyen de paiement
    if (bill.paymentMethod != null && bill.paymentMethod!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Paiement: ${bill.paymentMethod}');
    }
    
    buffer.writeln();
  }

  /// Ajouter le pied de page
  void _addFooter(StringBuffer buffer, Company? company) {
    buffer.writeln(_separator);
    buffer.writeln();
    
    // Informations légales
    if (company != null) {
      if (company.vatNumber.isNotEmpty) {
        buffer.writeln('TVA: ${company.vatNumber}');
      }
      
      if (company.siret.isNotEmpty) {
        buffer.writeln('SIRET: ${company.siret}');
      }
    }
    
    buffer.writeln();
    buffer.writeln(_centerText('Merci de votre visite !'));
    buffer.writeln();
    buffer.writeln(_centerText('EasyRest - Système de caisse'));
    
    // Espaces pour couper le ticket
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

  /// Aligner un texte à droite
  String _alignRight(String text) {
    if (text.length >= _maxLineLength) {
      return text;
    }
    
    final padding = _maxLineLength - text.length;
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

  /// Générer le contenu pour l'impression de facture (format plus détaillé)
  Future<String> generateInvoiceContent(Bill bill, Order order, List<OrderItem> orderItems) async {
    final company = await _companyService.getCompany();
    final buffer = StringBuffer();

    // En-tête de l'entreprise (plus détaillé pour facture)
    if (company != null) {
      _addDetailedCompanyHeader(buffer, company);
    }

    // Informations de la facture
    _addDetailedBillInfo(buffer, bill, order);

    // Séparateur
    buffer.writeln(_separator);

    // Détail des articles avec TVA
    _addDetailedOrderItems(buffer, orderItems);

    // Séparateur
    buffer.writeln(_separator);

    // Totaux détaillés et ventilation TVA
    _addDetailedTotalsAndVat(buffer, bill, orderItems);

    // Pied de page
    _addDetailedFooter(buffer, company);

    return buffer.toString();
  }

  /// En-tête détaillé pour facture
  void _addDetailedCompanyHeader(StringBuffer buffer, Company company) {
    buffer.writeln(_centerText(company.name.toUpperCase()));
    buffer.writeln();
    
    _addWrappedText(buffer, company.address);
    buffer.writeln();
    
    if (company.phone.isNotEmpty) {
      buffer.writeln('Tél: ${company.phone}');
    }
    
    if (company.email != null && company.email!.isNotEmpty) {
      buffer.writeln('Email: ${company.email}');
    }
    
    if (company.website != null && company.website!.isNotEmpty) {
      buffer.writeln('Web: ${company.website}');
    }
    
    buffer.writeln();
    buffer.writeln(_separator);
    buffer.writeln();
  }

  /// Informations détaillées de la facture
  void _addDetailedBillInfo(StringBuffer buffer, Bill bill, Order order) {
    buffer.writeln('FACTURE N° ${bill.id}');
    buffer.writeln();
    
    final now = DateTime.now();
    buffer.writeln('Date: ${_formatDate(now)}');
    buffer.writeln('Heure: ${_formatTime(now)}');
    buffer.writeln('Table: ${order.tableName}');
    
    if (order.staffName != null && order.staffName!.isNotEmpty) {
      buffer.writeln('Serveur: ${order.staffName}');
    }
    
    buffer.writeln();
  }

  /// Articles détaillés avec TVA
  void _addDetailedOrderItems(StringBuffer buffer, List<OrderItem> orderItems) {
    buffer.writeln('DÉTAIL DES ARTICLES');
    buffer.writeln();
    
    for (final item in orderItems) {
      buffer.writeln(item.productName);
      
      final quantity = item.quantity.toString();
      final unitPrice = item.unitPrice.toStringAsFixed(2);
      final totalPrice = item.totalPrice.toStringAsFixed(2);
      
      buffer.writeln('  ${quantity} x ${unitPrice}€ = ${totalPrice}€');
      
      final tvaRateDouble = _parseTvaRate(item.tvaRate);
      if (tvaRateDouble > 0) {
        final tvaAmount = (item.totalPrice * tvaRateDouble).toStringAsFixed(2);
        buffer.writeln('  TVA ${(tvaRateDouble * 100).toInt()}%: ${tvaAmount}€');
      }
      
      buffer.writeln();
    }
  }

  /// Totaux détaillés avec ventilation TVA
  void _addDetailedTotalsAndVat(StringBuffer buffer, Bill bill, List<OrderItem> orderItems) {
    buffer.writeln('RÉCAPITULATIF');
    buffer.writeln();
    
    // Calculer la ventilation TVA par taux
    final vatBreakdown = <double, double>{};
    double totalHt = 0.0;
    
    for (final item in orderItems) {
      totalHt += item.totalPrice;
      final tvaRateDouble = _parseTvaRate(item.tvaRate);
      if (tvaRateDouble > 0) {
        vatBreakdown[tvaRateDouble] = (vatBreakdown[tvaRateDouble] ?? 0.0) + (item.totalPrice * tvaRateDouble);
      }
    }
    
    // Afficher la ventilation TVA
    if (vatBreakdown.isNotEmpty) {
      buffer.writeln('VENTILATION TVA:');
      for (final entry in vatBreakdown.entries) {
        final rate = (entry.key * 100).toInt();
        final amount = entry.value.toStringAsFixed(2);
        buffer.writeln('  TVA ${rate}%: ${amount}€');
      }
      buffer.writeln();
    }
    
    // Totaux
    buffer.writeln(_alignRight('Total HT: ${bill.totalHt.toStringAsFixed(2)}€'));
    buffer.writeln(_alignRight('Total TVA: ${bill.totalTva.toStringAsFixed(2)}€'));
    buffer.writeln(_alignRight('TOTAL TTC: ${bill.totalTtc.toStringAsFixed(2)}€'));
    
    if (bill.paymentMethod != null && bill.paymentMethod!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Paiement: ${bill.paymentMethod}');
    }
    
    buffer.writeln();
  }

  /// Pied de page détaillé
  void _addDetailedFooter(StringBuffer buffer, Company? company) {
    buffer.writeln(_separator);
    buffer.writeln();
    
    if (company != null) {
      if (company.vatNumber.isNotEmpty) {
        buffer.writeln('TVA: ${company.vatNumber}');
      }
      
      if (company.siret.isNotEmpty) {
        buffer.writeln('SIRET: ${company.siret}');
      }
    }
    
    buffer.writeln();
    buffer.writeln(_centerText('Merci de votre visite !'));
    buffer.writeln();
    buffer.writeln(_centerText('EasyRest - Système de caisse'));
    
    // Espaces pour couper
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
  }

  /// Parser le taux de TVA depuis un String vers un double
  double _parseTvaRate(String tvaRate) {
    // Enlever le % et convertir en double
    final cleanRate = tvaRate.replaceAll('%', '').trim();
    final rate = double.tryParse(cleanRate) ?? 0.0;
    return rate / 100.0; // Convertir de pourcentage vers décimal
  }
}

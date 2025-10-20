import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/cash_register_opening.dart';
import '../models/cash_register_closing.dart';
import '../models/table_restaurant.dart';
import '../services/api_database_service.dart';
import '../services/receipt_printer_service.dart';
import '../services/production_service.dart';
import '../utils/excel_utils.dart';
import 'cash_register_statistics_screen.dart';
import 'cash_register_opening_screen.dart';
import 'reports_config_screen.dart';
import 'printer_config_screen.dart';
import 'bill_screen.dart';

class CashRegisterScreen extends StatefulWidget {
  final String managerName;
  final bool isManager;
  
  const CashRegisterScreen({
    required this.managerName,
    this.isManager = false,
    super.key,
  });

  @override
  State<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends State<CashRegisterScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  
  DateTime _selectedDate = DateTime.now();
  Map<String, double> _dailyTotals = {};
  List<Bill> _dailyBills = [];
  List<Bill> _pendingBills = [];
  CashRegisterOpening? _currentOpening;
  CashRegisterClosing? _currentClosing;
  bool _isLoading = true;
  bool _isCashRegisterOpen = false;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await Future.wait([
        _loadDailyTotals(),
        _loadCurrentOpening(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement: $e');
    }
  }

  Future<void> _loadDailyTotals() async {
    final totals = await _dbService.getDailyTotals(_selectedDate);
    final bills = await _dbService.getBillsByDate(_selectedDate);
    final pendingBills = await _dbService.getPendingBillsByDate(_selectedDate);

    // Combine all bills and sort by date (newest first)
    final allBills = [...bills, ...pendingBills];
    allBills.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Debug information
    print('Loading daily totals: ${bills.length} bills, ${pendingBills.length} pending');
    print('Total combined bills: ${allBills.length}');
    print('_dailyTotals keys: ${_dailyTotals.keys.toList()}');
    print('_dailyTotals values: $_dailyTotals');
    print('Espèces value: ${_dailyTotals['Espèces']}');
    print('Espèces value (lowercase): ${_dailyTotals['espèces']}');

    setState(() {
      _dailyTotals = totals;
      _dailyBills = allBills; // Now contains all bills sorted by date
      _pendingBills = pendingBills;
    });
  }

  Future<void> _loadCurrentOpening() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final opening = await _dbService.getActiveCashRegisterOpening(_selectedDate);
      final isOpen = await _dbService.isCashRegisterOpenForDate(_selectedDate);
      final closing = await _dbService.getCashRegisterClosingByDate(_selectedDate);

      setState(() {
        _currentOpening = opening;
        _isCashRegisterOpen = isOpen;
        _currentClosing = closing;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cash register status: $e');
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyData();
    }
  }

  Future<void> _openCashRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashRegisterOpeningScreen(
          managerName: widget.managerName,
        ),
      ),
    );

    if (result == true) {
      _loadDailyData();
    }
  }

  Future<void> _changeShift() async {
    // First close the current opening
    if (_currentOpening != null) {
      await _dbService.closeCashRegisterOpening(_currentOpening!.id!);
    }

    // Then open a new shift
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashRegisterOpeningScreen(
          managerName: widget.managerName,
        ),
      ),
    );

    if (result == true) {
      _loadDailyData();
    }
  }

  Future<void> _closeCashRegister() async {
    print('Attempting to close cash register...');
    print('_isCashRegisterOpen: $_isCashRegisterOpen');
    
    if (!_isCashRegisterOpen) {
      _showError('La caisse n\'est pas ouverte pour cette date');
      return;
    }

    // Check if there are pending bills
    if (_pendingBills.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Factures en attente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Il y a ${_pendingBills.length} facture(s) en attente de paiement.'),
              const SizedBox(height: 8),
              const Text('Voulez-vous vraiment fermer la caisse ? Les factures en attente ne seront pas archivées et resteront disponibles pour traitement ultérieur.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Fermer quand même'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return; // User cancelled
      }
    }

    // Calculate expected cash amount
    final initialCash = _currentOpening?.initialCashAmount ?? 0.0;
    final cashPayments = _dailyTotals['Espèces'] ?? _dailyTotals['espèces'] ?? 0.0;
    final expectedCash = initialCash + cashPayments;
    
    print('Cash calculation:');
    print('  Initial cash: $initialCash');
    print('  Cash payments: $cashPayments');
    print('  Expected cash: $expectedCash');

    // Show cash reconciliation dialog
    final reconciledAmounts = await _showCashReconciliationDialog(expectedCash);
    if (reconciledAmounts == null) return; // User cancelled

    final actualCash = reconciledAmounts['Espèces'] ?? 0.0;
    final cashDifference = actualCash - expectedCash;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fermeture de caisse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            Text('Poste: ${_currentOpening?.shiftNumber ?? 1}'),
            const SizedBox(height: 16),
            Text('Total TTC: ${_dailyTotals['totalTtc']?.toStringAsFixed(2)}€'),
            const SizedBox(height: 8),
            Text('Espèces: ${(_dailyTotals['Espèces'] ?? _dailyTotals['espèces'] ?? 0.0).toStringAsFixed(2)}€'),
            Text('Carte: ${(_dailyTotals['Carte bancaire'] ?? _dailyTotals['carte bancaire'] ?? 0.0).toStringAsFixed(2)}€'),
            Text('Tickets: ${(_dailyTotals['Ticket restaurant'] ?? _dailyTotals['ticket restaurant'] ?? 0.0).toStringAsFixed(2)}€'),
            Text('Chèques: ${(_dailyTotals['Chèque'] ?? _dailyTotals['chèque'] ?? 0.0).toStringAsFixed(2)}€'),
            const SizedBox(height: 16),
            Text('Monnaie initiale: ${initialCash.toStringAsFixed(2)}€'),
            Text('Espèces attendues: ${expectedCash.toStringAsFixed(2)}€'),
            Text('Espèces réelles: ${actualCash.toStringAsFixed(2)}€'),
            Text(
              'Différence: ${cashDifference.toStringAsFixed(2)}€',
              style: TextStyle(
                color: cashDifference == 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Êtes-vous sûr de vouloir fermer la caisse ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFbfa14a),
              foregroundColor: const Color(0xFF231f2b),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Fermer la caisse'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('Creating cash register closing record...');
        print('_dailyTotals: $_dailyTotals');
        
        // Use reconciled amounts instead of calculated totals
        final paymentMethods = <String, double>{};
        for (final entry in reconciledAmounts.entries) {
          paymentMethods[entry.key] = entry.value;
        }
        print('Reconciled payment methods: $paymentMethods');
        
        // Calculate totals from reconciled amounts
        final reconciledTotalTtc = paymentMethods.values.fold(0.0, (sum, amount) => sum + amount);
        final reconciledTotalHt = reconciledTotalTtc / 1.2; // Approximate HT from TTC
        final reconciledTotalTva = reconciledTotalTtc - reconciledTotalHt;
        
        // Create closing record
        final closing = CashRegisterClosing(
          date: _selectedDate,
          shiftNumber: _currentOpening?.shiftNumber ?? 1,
          totalHt: reconciledTotalHt,
          totalTtc: reconciledTotalTtc,
          totalTva: reconciledTotalTva,
          paymentMethods: paymentMethods,
          numberOfBills: _dailyBills.length,
          expectedCashAmount: expectedCash,
          actualCashAmount: actualCash,
          cashDifference: cashDifference,
          closedAt: DateTime.now(),
          closedBy: widget.managerName,
        );
        
        print('Closing record created successfully');

        await _dbService.insertCashRegisterClosing(closing);

        // Archive all bills for this date
        await _dbService.archiveBillsByDate(_selectedDate);

        // Close the opening
        if (_currentOpening != null) {
          await _dbService.closeCashRegisterOpening(_currentOpening!.id!);
        }

        // Generate daily report
        try {
          final filePath = await ExcelUtils.generateDailyReport(
            closing: closing,
            bills: _dailyBills,
            managerName: widget.managerName,
          );
          final pendingCount = _pendingBills.length;
          if (pendingCount > 0) {
            _showSuccess('Caisse fermée avec succès. Factures payées archivées. $pendingCount facture(s) en attente conservée(s). Rapport généré: $filePath');
          } else {
            _showSuccess('Caisse fermée avec succès. Toutes les factures ont été archivées. Rapport généré: $filePath');
          }
        } catch (e) {
          print('Error generating daily report: $e');
          final pendingCount = _pendingBills.length;
          if (pendingCount > 0) {
            _showError('Caisse fermée avec succès. Factures payées archivées. $pendingCount facture(s) en attente conservée(s). Erreur rapport: $e');
          } else {
            _showError('Caisse fermée avec succès. Toutes les factures ont été archivées. Erreur rapport: $e');
          }
        }

        _loadDailyData();
      } catch (e) {
        _showError('Erreur lors de la fermeture: $e');
      }
    }
  }

  Future<Map<String, double>?> _showCashReconciliationDialog(double expectedCash) async {
    // Controllers pour chaque moyen de paiement
    final cashController = TextEditingController(text: expectedCash.toStringAsFixed(2));
    final cardController = TextEditingController(text: (_dailyTotals['Carte bancaire'] ?? _dailyTotals['carte bancaire'] ?? 0.0).toStringAsFixed(2));
    final ticketController = TextEditingController(text: (_dailyTotals['Ticket restaurant'] ?? _dailyTotals['ticket restaurant'] ?? 0.0).toStringAsFixed(2));
    final checkController = TextEditingController(text: (_dailyTotals['Chèque'] ?? _dailyTotals['chèque'] ?? 0.0).toStringAsFixed(2));
    
    return showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Réconciliation complète de caisse'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vérifiez et corrigez les montants pour chaque moyen de paiement:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Espèces
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('💵 Espèces:'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: cashController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Montant réel',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Carte bancaire
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('💳 Carte bancaire:'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: cardController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Montant réel',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Ticket restaurant
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('🎫 Ticket restaurant:'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: ticketController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Montant réel',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Chèque
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('📄 Chèque:'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: checkController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Montant réel',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final cashAmount = double.tryParse(cashController.text.replaceAll(',', '.'));
              final cardAmount = double.tryParse(cardController.text.replaceAll(',', '.'));
              final ticketAmount = double.tryParse(ticketController.text.replaceAll(',', '.'));
              final checkAmount = double.tryParse(checkController.text.replaceAll(',', '.'));
              
              if (cashAmount != null && cardAmount != null && ticketAmount != null && checkAmount != null &&
                  cashAmount >= 0 && cardAmount >= 0 && ticketAmount >= 0 && checkAmount >= 0) {
                Navigator.pop(context, {
                  'Espèces': cashAmount,
                  'Carte bancaire': cardAmount,
                  'Ticket restaurant': ticketAmount,
                  'Chèque': checkAmount,
                });
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _printDailyReport() async {
    try {
      // TODO: Implement daily report printing
      print('Printing daily report for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}');
      print('Total TTC: ${_dailyTotals['totalTtc']?.toStringAsFixed(2)}€');
      print('Total HT: ${_dailyTotals['totalHt']?.toStringAsFixed(2)}€');
      print('Total TVA: ${_dailyTotals['totalTva']?.toStringAsFixed(2)}€');
      
      _showSuccess('Rapport imprimé');
    } catch (e) {
      _showError('Erreur lors de l\'impression: $e');
    }
  }

  Future<void> _printProductionOrders() async {
    try {
      if (_pendingBills.isEmpty) {
        _showError('Aucune commande en attente à imprimer');
        return;
      }

      // Récupérer toutes les commandes en attente
      final productionService = ProductionService();
      int printedCount = 0;

      for (final bill in _pendingBills) {
        // Récupérer la commande et les articles
        final order = await _dbService.getOrderById(bill.orderId);
        if (order == null) continue;

        final orderItems = await _dbService.getOrderItemsByOrderId(bill.orderId);
        final menuItems = await _dbService.getMenuItems();

        // Générer les bons de production
        final productionOrders = await productionService.generateProductionOrders(order, orderItems, menuItems);

        // Afficher chaque bon (dans une vraie app, ceci serait envoyé aux imprimantes)
        for (final entry in productionOrders.entries) {
          final printerId = entry.key;
          final content = entry.value;
          
          print('=== BON DE PRODUCTION - ${printerId.toUpperCase()} ===');
          print(content);
          print('=== FIN DU BON ===');
        }

        // Générer aussi le bon complet pour la cuisine
        final completeOrder = await productionService.generateCompleteProductionOrder(order, orderItems, menuItems);
        print('=== BON COMPLET - CUISINE ===');
        print(completeOrder);
        print('=== FIN DU BON COMPLET ===');

        printedCount++;
      }

      _showSuccess('$printedCount bon(s) de production généré(s)');
    } catch (e) {
      _showError('Erreur lors de l\'impression des bons: $e');
    }
  }

  // Payment processing methods
  Future<void> _processPayment(Bill bill) async {
    if (!_isCashRegisterOpen) {
      _showError('La caisse doit être ouverte pour traiter un paiement');
      return;
    }

    // Check if bill is already paid
    if (bill.status == 'paid') {
      _showError('Cette facture a déjà été payée');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaymentDialog(bill: bill),
    );

    if (result != null) {
      try {
        final paymentMethod = result['paymentMethod'] as String;
        
        // Debug information
        print('Processing payment for bill ${bill.id}:');
        print('  Table: ${bill.tableName}');
        print('  Amount: ${bill.totalTtc.toStringAsFixed(2)}€');
        print('  Payment Method: $paymentMethod');
        print('  Previous Status: ${bill.status}');
        
        // Verify payment method mapping
        _verifyPaymentMethodMapping(paymentMethod);
        
        // Update bill with new payment method
        final updatedBill = bill.copyWith(
          paymentMethod: paymentMethod,
          status: 'paid',
        );

        await _dbService.updateBill(updatedBill);
        
        // Mettre à jour le statut de la table à "Libre" après paiement
        await _updateTableStatusToFree(bill);
        
        print('  New Status: ${updatedBill.status}');
        print('  Payment Method: ${updatedBill.paymentMethod}');
        print('  Payment processed successfully');
        
        _showSuccess('Paiement traité avec succès ($paymentMethod)');
        
        // Add a small delay to ensure database update is complete
        await Future.delayed(const Duration(milliseconds: 100));
        _loadDailyData(); // Refresh totals
        
        // Show updated totals for verification (removed - causes confusion)
        // _showUpdatedTotals(paymentMethod, bill.totalTtc);
      } catch (e) {
        print('Error processing payment: $e');
        _showError('Erreur lors du traitement du paiement: $e');
      }
    }
  }

  // Helper method to verify payment method mapping
  void _verifyPaymentMethodMapping(String paymentMethod) {
    final method = paymentMethod.toLowerCase().trim();
    String mappedKey;
    
    switch (method) {
      case 'espèces':
      case 'especes':
        mappedKey = 'espèces';
        break;
      case 'carte bancaire':
      case 'carte':
      case 'cb':
        mappedKey = 'carte bancaire';
        break;
      case 'ticket restaurant':
      case 'ticket':
      case 'tickets restaurant':
        mappedKey = 'ticket restaurant';
        break;
      case 'chèque':
      case 'cheque':
      case 'cheques':
        mappedKey = 'chèque';
        break;
      default:
        mappedKey = 'autres';
        break;
    }
    
    print('  Payment method mapping: "$paymentMethod" -> "$mappedKey"');
  }

  /// Met à jour le statut de la table à "Libre" après paiement de la facture
  Future<void> _updateTableStatusToFree(Bill bill) async {
    try {
      print('=== MISE À JOUR STATUT TABLE APRÈS PAIEMENT ===');
      print('Bill table name: ${bill.tableName}');
      
      // Extraire le numéro de table du nom de la table (format: "Table X")
      final tableNumberMatch = RegExp(r'Table (\d+)').firstMatch(bill.tableName);
      if (tableNumberMatch == null) {
        print('❌ Could not extract table number from: ${bill.tableName}');
        return;
      }
      
      final tableNumber = int.parse(tableNumberMatch.group(1)!);
      print('✅ Table number extracted: $tableNumber');
      
      // Récupérer toutes les tables
      final tables = await _dbService.getTables();
      print('✅ Found ${tables.length} tables in database');
      
      final table = tables.firstWhere(
        (t) => t.number == tableNumber,
        orElse: () => throw Exception('Table $tableNumber not found'),
      );
      
      print('✅ Found table: ID=${table.id}, Number=${table.number}, Status=${table.status}');
      
      // Mettre à jour le statut de la table à "Libre"
      final updatedTable = TableRestaurant(
        id: table.id,
        number: table.number,
        capacity: table.capacity,
        roomId: table.roomId,
        status: 'Libre',
      );
      
      print('🔄 Updating table ${table.number} status: ${table.status} -> Libre');
      await _dbService.updateTable(updatedTable);
      print('✅ Table ${table.number} status updated to: Libre');
      print('=== FIN MISE À JOUR STATUT TABLE ===');
    } catch (e) {
      print('❌ Error updating table status to free: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      // Ne pas afficher d'erreur à l'utilisateur car le paiement a réussi
      // Le statut de la table peut être mis à jour manuellement si nécessaire
    }
  }

  // Helper method to show updated totals after payment
  void _showUpdatedTotals(String paymentMethod, double amount) {
    // Wait a moment for the data to refresh, then show totals
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final method = paymentMethod.toLowerCase().trim();
        String mappedKey;
        
        switch (method) {
          case 'espèces':
          case 'especes':
            mappedKey = 'espèces';
            break;
          case 'carte bancaire':
          case 'carte':
          case 'cb':
            mappedKey = 'carte bancaire';
            break;
          case 'ticket restaurant':
          case 'ticket':
          case 'tickets restaurant':
            mappedKey = 'ticket restaurant';
            break;
          case 'chèque':
          case 'cheque':
          case 'cheques':
            mappedKey = 'chèque';
            break;
          default:
            mappedKey = 'autres';
            break;
        }
        
        final currentTotal = _dailyTotals[mappedKey] ?? 0.0;
        print('Updated totals after payment:');
        print('  Payment method: $paymentMethod -> $mappedKey');
        print('  Amount added: ${amount.toStringAsFixed(2)}€');
        print('  New total for $mappedKey: ${currentTotal.toStringAsFixed(2)}€');
        print('  Overall daily total: ${_dailyTotals['totalTtc']?.toStringAsFixed(2)}€');
      }
    });
  }

  Future<void> _printReceipt(Bill bill) async {
    try {
      // Check if bill is pending
      if (bill.status == 'pending') {
        _showError('Impossible d\'imprimer un ticket pour une facture en attente');
        return;
      }

      // Récupérer les détails de la commande et des articles
      final order = await _dbService.getOrderById(bill.orderId);
      if (order == null) {
        _showError('Commande introuvable');
        return;
      }

      final orderItems = await _dbService.getOrderItemsByOrderId(bill.orderId);
      
      // Générer le contenu du ticket avec les informations d'entreprise
      final receiptService = ReceiptPrinterService();
      final receiptContent = await receiptService.generateReceiptContent(bill, order, orderItems);
      
      // Afficher le contenu du ticket (pour l'instant, on l'affiche dans la console)
      // Dans une vraie application, ceci serait envoyé à l'imprimante thermique
      print('=== TICKET DE CAISSE ===');
      print(receiptContent);
      print('=== FIN DU TICKET ===');
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate printing
      _showSuccess('Ticket généré avec succès');
    } catch (e) {
      _showError('Erreur lors de l\'impression: $e');
    }
  }

  Future<void> _printInvoice(Bill bill) async {
    try {
      // Check if bill is pending
      if (bill.status == 'pending') {
        _showError('Impossible d\'imprimer une facture pour une facture en attente');
        return;
      }

      // Récupérer les détails de la commande et des articles
      final order = await _dbService.getOrderById(bill.orderId);
      if (order == null) {
        _showError('Commande introuvable');
        return;
      }

      final orderItems = await _dbService.getOrderItemsByOrderId(bill.orderId);
      
      // Générer le contenu de la facture avec les informations d'entreprise et ventilation TVA
      final receiptService = ReceiptPrinterService();
      final invoiceContent = await receiptService.generateInvoiceContent(bill, order, orderItems);
      
      // Afficher le contenu de la facture (pour l'instant, on l'affiche dans la console)
      // Dans une vraie application, ceci serait envoyé à l'imprimante thermique
      print('=== FACTURE DÉTAILLÉE ===');
      print(invoiceContent);
      print('=== FIN DE LA FACTURE ===');
      
      await Future.delayed(const Duration(seconds: 3)); // Simulate printing
      _showSuccess('Facture générée avec succès');
    } catch (e) {
      _showError('Erreur lors de l\'impression: $e');
    }
  }

  Future<void> _showBillDetails(Bill bill) async {
    // Get the order for this bill
    final order = await _dbService.getOrderById(bill.orderId);
    if (order != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillScreen(order: order),
        ),
      ).then((result) {
        if (result == true) {
          _loadDailyData(); // Refresh data if bill was updated
        }
      });
    } else {
      _showError('Commande non trouvée');
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la facture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir supprimer cette facture ?'),
            const SizedBox(height: 8),
            Text('Table: ${bill.tableName}'),
            Text('Montant: ${bill.totalTtc.toStringAsFixed(2)}€'),
            Text('Statut: ${bill.status}'),
            if (bill.status == 'paid') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: const Text(
                  '⚠️ Attention: Cette facture a déjà été payée. La suppression est irréversible.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbService.deleteBill(bill.id!);
        _showSuccess('Facture supprimée avec succès');
        _loadDailyData(); // Refresh the data
      } catch (e) {
        _showError('Erreur lors de la suppression: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text(
          'Caisse',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        actions: [
          if (_pendingBills.isNotEmpty && _isCashRegisterOpen)
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: () => _processPayment(_pendingBills.first),
              tooltip: 'Traiter le premier paiement en attente',
            ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CashRegisterStatisticsScreen(),
                ),
              );
            },
            tooltip: 'Statistiques et rapports',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printDailyReport,
            tooltip: 'Imprimer le rapport',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsConfigScreen(),
                ),
              );
            },
            tooltip: 'Configuration des rapports',
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrinterConfigScreen(),
                ),
              );
            },
            tooltip: 'Configuration des imprimantes',
          ),
          if (_pendingBills.isNotEmpty && _isCashRegisterOpen)
            IconButton(
              icon: const Icon(Icons.restaurant_menu),
              onPressed: _printProductionOrders,
              tooltip: 'Imprimer les bons de production',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFbfa14a),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                // Cash register status
                Container(
                  padding: const EdgeInsets.all(16),
                  color: _isCashRegisterOpen 
                      ? const Color(0xFF2d5a2d) 
                      : const Color(0xFF5a2d2d),
                  child: Row(
                    children: [
                      Icon(
                        _isCashRegisterOpen ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCashRegisterOpen ? 'Caisse ouverte' : 'Caisse fermée',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_currentOpening != null)
                              Text(
                                'Poste ${_currentOpening!.shiftNumber} - Monnaie: ${_currentOpening!.initialCashAmount.toStringAsFixed(2)}€',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            Text(
                              'Connecté en tant que: ${widget.managerName} ${widget.isManager ? '(Manager)' : '(Serveur)'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isCashRegisterOpen)
                        ElevatedButton(
                          onPressed: widget.isManager ? _openCashRegister : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFbfa14a),
                            foregroundColor: const Color(0xFF231f2b),
                          ),
                          child: Text(widget.isManager ? 'Ouvrir' : 'Caisse fermée'),
                        )
                      else
                        ElevatedButton(
                          onPressed: widget.isManager ? _changeShift : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFbfa14a),
                            foregroundColor: const Color(0xFF231f2b),
                          ),
                          child: Text(widget.isManager ? 'Changer de poste' : 'Caisse ouverte'),
                        ),
                    ],
                  ),
                ),
                
                // Date selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFbfa14a),
                            foregroundColor: const Color(0xFF231f2b),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Daily totals
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfff8e1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Totaux du jour',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF231f2b),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _TotalCard(
                              title: 'Total HT',
                              amount: _dailyTotals['totalHt'] ?? 0.0,
                              color: const Color(0xFF231f2b),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TotalCard(
                              title: 'Total TVA',
                              amount: _dailyTotals['totalTva'] ?? 0.0,
                              color: const Color(0xFFbfa14a),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TotalCard(
                              title: 'Total TTC',
                              amount: _dailyTotals['totalTtc'] ?? 0.0,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Payment methods breakdown
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2438),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Répartition par moyen de paiement',
                        style: TextStyle(
                          color: Color(0xFFbfa14a),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PaymentMethodRow(
                        icon: '💵',
                        label: 'Espèces',
                        amount: _dailyTotals['Espèces'] ?? _dailyTotals['espèces'] ?? 0.0,
                      ),
                      _PaymentMethodRow(
                        icon: '💳',
                        label: 'Carte bancaire',
                        amount: _dailyTotals['Carte bancaire'] ?? _dailyTotals['carte bancaire'] ?? 0.0,
                      ),
                      _PaymentMethodRow(
                        icon: '🎫',
                        label: 'Ticket restaurant',
                        amount: _dailyTotals['Ticket restaurant'] ?? _dailyTotals['ticket restaurant'] ?? 0.0,
                      ),
                      _PaymentMethodRow(
                        icon: '📄',
                        label: 'Chèque',
                        amount: _dailyTotals['Chèque'] ?? _dailyTotals['chèque'] ?? 0.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Cash reconciliation section (only show if cash register is open)
                if (_isCashRegisterOpen)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFbfa14a)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFFbfa14a),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Réconciliation de caisse',
                              style: TextStyle(
                                color: Color(0xFFbfa14a),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (widget.isManager)
                              ElevatedButton(
                                onPressed: _closeCashRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Fermer la caisse'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _CashReconciliationRow(
                          label: 'Monnaie initiale',
                          amount: _dailyTotals['initialCash'] ?? 0.0,
                          color: Colors.blue,
                        ),
                        _CashReconciliationRow(
                          label: 'Paiements espèces',
                          amount: _dailyTotals['Espèces'] ?? _dailyTotals['espèces'] ?? 0.0,
                          color: Colors.green,
                        ),
                        const Divider(color: Color(0xFFbfa14a)),
                        _CashReconciliationRow(
                          label: 'Espèces attendues en caisse',
                          amount: _dailyTotals['expectedCash'] ?? 0.0,
                          color: const Color(0xFFbfa14a),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Pending bills info (only show count if there are pending bills)
                if (_pendingBills.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfff3cd),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pending_actions,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_pendingBills.length} paiement(s) en attente dans la liste ci-dessous',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_pendingBills.isNotEmpty) const SizedBox(height: 16),
                
                // Bills list
                Container(
                  height: 350, // Hauteur réduite pour éviter l'overflow
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
                                Icons.receipt,
                                color: Color(0xFF231f2b),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Factures (${_dailyBills.length})',
                                style: const TextStyle(
                                  color: Color(0xFF231f2b),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: _dailyBills.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aucune facture pour cette date',
                                    style: TextStyle(
                                      color: Color(0xFF231f2b),
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _dailyBills.length,
                                  itemBuilder: (context, index) {
                                    final bill = _dailyBills[index];
                                    final isPending = bill.status == 'pending';
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      color: isPending ? const Color(0xFFfff3cd) : null, // Highlight pending bills
                                      child: Container(
                                        height: 120, // Hauteur fixe pour éviter l'overflow
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Contenu principal (gauche)
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${bill.tableName} - ${bill.formattedTime}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      if (isPending) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.orange,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: const Text(
                                                            'EN ATTENTE',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('${bill.paymentMethodIcon} ${bill.paymentMethod ?? 'En attente'}'),
                                                  Text('Status: ${bill.status == 'pending' ? 'En attente de paiement' : bill.status}'),
                                                ],
                                              ),
                                            ),
                                            // Montant et boutons (droite)
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${bill.totalTtc.toStringAsFixed(2)}€',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: isPending ? Colors.orange : const Color(0xFFbfa14a),
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        // Payment processing button
                                                        if (_isCashRegisterOpen)
                                                          IconButton(
                                                            icon: const Icon(Icons.payment, size: 24),
                                                            onPressed: () => _processPayment(bill),
                                                            tooltip: 'Traiter le paiement',
                                                            color: const Color(0xFFbfa14a),
                                                            padding: const EdgeInsets.all(4),
                                                            constraints: const BoxConstraints(
                                                              minWidth: 48,
                                                              minHeight: 48,
                                                            ),
                                                          ),
                                                        // Print receipt button
                                                        IconButton(
                                                          icon: const Icon(Icons.receipt, size: 16),
                                                          onPressed: () => _printReceipt(bill),
                                                          tooltip: 'Imprimer le ticket',
                                                          color: Colors.blue,
                                                          padding: const EdgeInsets.all(1),
                                                          constraints: const BoxConstraints(
                                                            minWidth: 24,
                                                            minHeight: 24,
                                                          ),
                                                        ),
                                                        // Print invoice button
                                                        IconButton(
                                                          icon: const Icon(Icons.description, size: 16),
                                                          onPressed: () => _printInvoice(bill),
                                                          tooltip: 'Imprimer la facture',
                                                          color: Colors.green,
                                                          padding: const EdgeInsets.all(1),
                                                          constraints: const BoxConstraints(
                                                            minWidth: 24,
                                                            minHeight: 24,
                                                          ),
                                                        ),
                                                        // View details button
                                                        IconButton(
                                                          icon: const Icon(Icons.info, size: 16),
                                                          onPressed: () => _showBillDetails(bill),
                                                          tooltip: 'Voir les détails',
                                                          color: Colors.orange,
                                                          padding: const EdgeInsets.all(1),
                                                          constraints: const BoxConstraints(
                                                            minWidth: 24,
                                                            minHeight: 24,
                                                          ),
                                                        ),
                                                        // Delete button
                                                        IconButton(
                                                          icon: const Icon(Icons.delete, size: 24),
                                                          onPressed: () => _deleteBill(bill),
                                                          tooltip: 'Supprimer la facture',
                                                          color: Colors.red,
                                                          padding: const EdgeInsets.all(4),
                                                          constraints: const BoxConstraints(
                                                            minWidth: 43,
                                                            minHeight: 43,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                
                // Informational section for non-managers
                if (!widget.isManager && _isCashRegisterOpen)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2a2438),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFbfa14a)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFbfa14a),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vous pouvez consulter la caisse. Seul un manager peut l\'ouvrir ou la fermer.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Informational section for non-managers when cash register is closed
                if (!widget.isManager && !_isCashRegisterOpen)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2a2438),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'La caisse est fermée. Contactez un manager pour l\'ouvrir.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final Bill bill;

  const _PaymentDialog({required this.bill});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _selectedPaymentMethod = 'Espèces';
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Espèces',
      'icon': '💵',
      'color': Colors.green,
    },
    {
      'name': 'Carte bancaire',
      'icon': '💳',
      'color': Colors.blue,
    },
    {
      'name': 'Ticket restaurant',
      'icon': '🍽️',
      'color': Colors.orange,
    },
    {
      'name': 'Chèque',
      'icon': '📄',
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set default payment method based on bill status
    if (widget.bill.paymentMethod != null) {
      _selectedPaymentMethod = widget.bill.paymentMethod!;
    } else {
      _selectedPaymentMethod = 'Espèces'; // Default for pending bills
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.bill.status == 'pending' ? 'Traiter le paiement en attente' : 'Traiter le paiement',
        style: const TextStyle(
          color: Color(0xFF231f2b),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table: ${widget.bill.tableName}',
            style: const TextStyle(
              color: Color(0xFF231f2b),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${widget.bill.totalTtc.toStringAsFixed(2)}€',
            style: const TextStyle(
              color: Color(0xFFbfa14a),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.bill.status == 'pending') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                'Facture en attente - Sélectionnez le mode de paiement',
                style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Mode de paiement:',
            style: TextStyle(
              color: Color(0xFF231f2b),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Payment method selection with large icons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method['name'];
                  });
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? method['color'].withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? method['color'] : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: method['color'].withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        method['icon'],
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method['name'],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected 
                              ? method['color'] 
                              : const Color(0xFF231f2b),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'paymentMethod': _selectedPaymentMethod,
          }),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFbfa14a),
            foregroundColor: const Color(0xFF231f2b),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _TotalCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)}€',
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String icon;
  final String label;
  final double amount;

  const _PaymentMethodRow({
    required this.icon,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)}€',
            style: const TextStyle(
              color: Color(0xFFbfa14a),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashReconciliationRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isTotal;

  const _CashReconciliationRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${amount.toStringAsFixed(2)}€',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

} 
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/bill.dart';
import '../services/api_database_service.dart';

class BillScreen extends StatefulWidget {
  final Order order;
  const BillScreen({super.key, required this.order});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  List<OrderItem> _orderItems = [];
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
  }

  Future<void> _loadOrderItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await _dbService.getOrderItems(widget.order.id!);
      setState(() {
        _orderItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  double get _totalHt => _orderItems.fold(0.0, (sum, item) => sum + item.totalHt);
  double get _totalTva => _orderItems.fold(0.0, (sum, item) => sum + item.totalTva);
  double get _totalTtc => _orderItems.fold(0.0, (sum, item) => sum + item.totalTtc);

  Map<String, double> get _tvaBreakdown {
    final breakdown = <String, double>{};
    for (final item in _orderItems) {
      breakdown[item.tvaRate] = (breakdown[item.tvaRate] ?? 0) + item.totalTva;
    }
    return breakdown;
  }

  Future<void> _generateBill() async {
    setState(() { _isLoading = true; });
    try {
      // Calculate totals
      double totalHt = _totalHt;
      double totalTva = _totalTva;
      double totalTtc = _totalTtc;

      // Create pending bill (no payment method yet)
      final bill = Bill(
        orderId: widget.order.id!,
        tableName: 'Table ${widget.order.tableId}',
        totalHt: totalHt,
        totalTva: totalTva,
        totalTtc: totalTtc,
        paymentMethod: null, // No payment method for pending bills
        createdAt: DateTime.now(),
        status: 'pending', // Set as pending
      );

      await _dbService.insertBill(bill);
      
      // Update order status to 'closed'
      final updatedOrder = widget.order.copyWith(status: 'closed');
      await _dbService.updateOrder(updatedOrder);
      
      if (!mounted) return;
      _showSuccess('Facture créée et ajoutée à la caisse en attente');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur lors de la création de la facture: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _printBill(Bill bill) async {
    setState(() { _isPrinting = true; });
    try {
      // TODO: Implement actual bill printing
      debugPrint('Printing bill:');
      debugPrint('Table: ${bill.tableName}');
      debugPrint('Total TTC: ${bill.totalTtc.toStringAsFixed(2)}€');
      debugPrint('Payment: ${bill.paymentMethod}');
      await Future.delayed(const Duration(seconds: 2)); // Simulate printing
      if (!mounted) return;
      _showSuccess('Facture imprimée');
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur lors de l\'impression: $e');
    } finally {
      if (mounted) setState(() { _isPrinting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text('Facture', style: TextStyle(color: Color(0xFFbfa14a))),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFbfa14a)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Table: ${widget.order.tableId}', style: const TextStyle(fontSize: 20, color: Color(0xFFbfa14a), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._orderItems.map((item) => ListTile(
                        title: Text(item.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('x${item.quantity} - TVA: ${item.tvaRate}', style: const TextStyle(color: Colors.white70)),
                        trailing: Text('${item.totalTtc.toStringAsFixed(2)}€', style: const TextStyle(color: Color(0xFFbfa14a), fontWeight: FontWeight.bold)),
                      )),
                  const Divider(color: Color(0xFFbfa14a)),
                  Text('Total HT: ${_totalHt.toStringAsFixed(2)}€', style: const TextStyle(color: Colors.white)),
                  Text('TVA: ${_totalTva.toStringAsFixed(2)}€', style: const TextStyle(color: Colors.white)),
                  Text('Total TTC: ${_totalTtc.toStringAsFixed(2)}€', style: const TextStyle(color: Color(0xFFbfa14a), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2a2438),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFbfa14a)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFbfa14a), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'La facture sera créée en attente. Le mode de paiement sera sélectionné à la caisse.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _generateBill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFbfa14a),
                            foregroundColor: const Color(0xFF231f2b),
                          ),
                          child: const Text('Créer la facture en attente'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
} 
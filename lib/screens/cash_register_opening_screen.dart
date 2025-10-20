import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cash_register_opening.dart';
import '../services/api_database_service.dart';

class CashRegisterOpeningScreen extends StatefulWidget {
  final String managerName;
  
  const CashRegisterOpeningScreen({
    required this.managerName,
    super.key,
  });

  @override
  State<CashRegisterOpeningScreen> createState() => _CashRegisterOpeningScreenState();
}

class _CashRegisterOpeningScreenState extends State<CashRegisterOpeningScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  final TextEditingController _initialCashController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isShiftChange = false;
  int _currentShiftNumber = 1;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  @override
  void dispose() {
    _initialCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentStatus() async {
    try {
      final isOpen = await _dbService.isCashRegisterOpenForDate(_selectedDate);
      if (isOpen) {
        final activeOpening = await _dbService.getActiveCashRegisterOpening(_selectedDate);
        if (activeOpening != null) {
          setState(() {
            _isShiftChange = true;
            _currentShiftNumber = activeOpening.shiftNumber;
          });
        }
      }
      
      final nextShift = await _dbService.getNextShiftNumber(_selectedDate);
      setState(() {
        _currentShiftNumber = nextShift;
      });
    } catch (e) {
      _showError('Erreur lors de la vérification: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      _checkCurrentStatus();
    }
  }

  Future<void> _openCashRegister() async {
    if (_initialCashController.text.isEmpty) {
      _showError('Veuillez saisir le montant initial de caisse');
      return;
    }

    final initialCash = double.tryParse(_initialCashController.text);
    if (initialCash == null || initialCash < 0) {
      _showError('Montant initial invalide');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final opening = CashRegisterOpening(
        date: _selectedDate,
        shiftNumber: _currentShiftNumber,
        initialCashAmount: initialCash,
        openedAt: DateTime.now(),
        openedBy: widget.managerName,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await _dbService.insertCashRegisterOpening(opening);

      _showSuccess(_isShiftChange 
        ? 'Changement de poste effectué (Poste $_currentShiftNumber)'
        : 'Caisse ouverte avec succès (Poste $_currentShiftNumber)'
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Erreur lors de l\'ouverture: $e');
    } finally {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: Text(
          _isShiftChange ? 'Changement de poste' : 'Ouverture de caisse',
          style: const TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2a2a3a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFbfa14a),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selectDate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFbfa14a),
                      foregroundColor: const Color(0xFF231f2b),
                    ),
                    child: const Text('Changer'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Shift information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2a2a3a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.work,
                    color: Color(0xFFbfa14a),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Poste',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Poste $_currentShiftNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Initial cash amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2a2a3a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.euro,
                        color: Color(0xFFbfa14a),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Montant initial de caisse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _initialCashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFbfa14a), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      filled: true,
                      fillColor: Color(0xFF1a1a2e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Montant pour la monnaie (donner la monnaie aux clients)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2a2a3a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.note,
                        color: Color(0xFFbfa14a),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Notes (optionnel)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ajouter des notes...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFbfa14a)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Open button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _openCashRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFbfa14a),
                  foregroundColor: const Color(0xFF231f2b),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Color(0xFF231f2b),
                      )
                    : Text(
                        _isShiftChange ? 'Changer de poste' : 'Ouvrir la caisse',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
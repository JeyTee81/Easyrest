import 'package:flutter/material.dart';
import 'dart:io';
import '../models/cash_register_closing.dart';
import '../services/api_database_service.dart';
import '../utils/excel_utils.dart';

class CashRegisterStatisticsScreen extends StatefulWidget {
  const CashRegisterStatisticsScreen({super.key});

  @override
  State<CashRegisterStatisticsScreen> createState() => _CashRegisterStatisticsScreenState();
}

class _CashRegisterStatisticsScreenState extends State<CashRegisterStatisticsScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  
  DateTime _selectedMonth = DateTime.now();
  List<CashRegisterClosing> _monthlyClosings = [];
  Map<String, double> _monthlyTotals = {};
  List<FileSystemEntity> _availableReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await Future.wait([
        _loadMonthlyData(),
        _loadAvailableReports(),
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

  Future<void> _loadMonthlyData() async {
    final closings = await _dbService.getCashRegisterClosings(
      startDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      endDate: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
    );

    final totals = await _dbService.getMonthlyTotals(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    setState(() {
      _monthlyClosings = closings;
      _monthlyTotals = totals;
    });
  }

  Future<void> _loadAvailableReports() async {
    try {
      final reports = await ExcelUtils.getAvailableReports();
      setState(() {
        _availableReports = reports;
      });
    } catch (e) {
      print('Error loading reports: $e');
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      _loadMonthlyData();
    }
  }

  Future<void> _generateMonthlyReport() async {
    try {
      if (_monthlyClosings.isEmpty) {
        _showError('Aucune donnée de fermeture pour ce mois');
        return;
      }

      final monthNames = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];

      final monthName = monthNames[_selectedMonth.month - 1];
      final filePath = await ExcelUtils.generateMonthlyReport(
        closings: _monthlyClosings,
        month: monthName,
        year: _selectedMonth.year,
      );

      _showSuccess('Rapport mensuel généré: $filePath');
      _loadAvailableReports(); // Refresh the list
    } catch (e) {
      _showError('Erreur lors de la génération: $e');
    }
  }

  Future<void> _deleteReport(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rapport'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce rapport ?'),
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
        await ExcelUtils.deleteReport(filePath);
        _showSuccess('Rapport supprimé');
        _loadAvailableReports();
      } catch (e) {
        _showError('Erreur lors de la suppression: $e');
      }
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

  String _getMonthName(DateTime date) {
    final monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return monthNames[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text(
          'Statistiques de caisse',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _generateMonthlyReport,
            tooltip: 'Générer rapport mensuel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFbfa14a),
              ),
            )
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  // Month selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectMonth,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${_getMonthName(_selectedMonth)} ${_selectedMonth.year}',
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
                  
                  // Tab bar
                  Container(
                    color: const Color(0xFF2a2a3a),
                    child: const TabBar(
                      labelColor: Color(0xFFbfa14a),
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Color(0xFFbfa14a),
                      tabs: [
                        Tab(text: 'Résumé'),
                        Tab(text: 'Détails'),
                        Tab(text: 'Rapports'),
                      ],
                    ),
                  ),
                  
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSummaryTab(),
                        _buildDetailsTab(),
                        _buildReportsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Monthly totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFfff8e1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résumé de ${_getMonthName(_selectedMonth)} ${_selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF231f2b),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total HT',
                        amount: _monthlyTotals['totalHt'] ?? 0.0,
                        color: const Color(0xFF231f2b),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total TVA',
                        amount: _monthlyTotals['totalTva'] ?? 0.0,
                        color: const Color(0xFFbfa14a),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total TTC',
                        amount: _monthlyTotals['totalTtc'] ?? 0.0,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Factures',
                        amount: _monthlyTotals['numberOfBills'] ?? 0.0,
                        color: const Color(0xFF231f2b),
                        isInteger: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Jours',
                        amount: _monthlyTotals['numberOfDays'] ?? 0.0,
                        color: const Color(0xFFbfa14a),
                        isInteger: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Moyenne/jour',
                        amount: (_monthlyTotals['totalTtc'] ?? 0.0) / (_monthlyTotals['numberOfDays'] ?? 1.0),
                        color: Colors.blue,
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
                ...(_monthlyTotals.entries
                    .where((entry) => !['totalHt', 'totalTtc', 'totalTva', 'numberOfBills', 'numberOfDays'].contains(entry.key))
                    .map((entry) => _PaymentMethodRow(
                          icon: _getPaymentMethodIcon(entry.key),
                          label: entry.key,
                          amount: entry.value,
                        ))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return _monthlyClosings.isEmpty
        ? const Center(
            child: Text(
              'Aucune fermeture de caisse pour ce mois',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _monthlyClosings.length,
            itemBuilder: (context, index) {
              final closing = _monthlyClosings[index];
              return Card(
                color: const Color(0xFF2a2a3a),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    '${closing.date.day.toString().padLeft(2, '0')}/${closing.date.month.toString().padLeft(2, '0')}/${closing.date.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fermé par: ${closing.closedBy}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Heure: ${closing.closedAt.hour.toString().padLeft(2, '0')}:${closing.closedAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Factures: ${closing.numberOfBills}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${closing.totalTtc.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Color(0xFFbfa14a),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'HT: ${closing.totalHt.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildReportsTab() {
    return _availableReports.isEmpty
        ? const Center(
            child: Text(
              'Aucun rapport disponible',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _availableReports.length,
            itemBuilder: (context, index) {
              final file = _availableReports[index] as File;
              final stat = file.statSync();
              final fileName = file.path.split('/').last;
              
              return Card(
                color: const Color(0xFF2a2a3a),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(
                    Icons.description,
                    color: Color(0xFFbfa14a),
                    size: 32,
                  ),
                  title: Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Créé le: ${stat.modified.day.toString().padLeft(2, '0')}/${stat.modified.month.toString().padLeft(2, '0')}/${stat.modified.year} à ${stat.modified.hour.toString().padLeft(2, '0')}:${stat.modified.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Color(0xFFbfa14a)),
                        onPressed: () => ExcelUtils.shareReport(file.path),
                        tooltip: 'Partager',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteReport(file.path),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  String _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'espèces':
        return '💵';
      case 'carte bancaire':
        return '💳';
      case 'ticket restaurant':
        return '🎫';
      case 'chèque':
        return '📄';
      default:
        return '💰';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final bool isInteger;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    this.isInteger = false,
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
            isInteger 
                ? amount.toInt().toString()
                : '${amount.toStringAsFixed(2)}€',
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
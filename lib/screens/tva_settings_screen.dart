import 'package:flutter/material.dart';
import '../utils/tva_utils.dart';

class TvaSettingsScreen extends StatefulWidget {
  const TvaSettingsScreen({super.key});

  @override
  State<TvaSettingsScreen> createState() => _TvaSettingsScreenState();
}

class _TvaSettingsScreenState extends State<TvaSettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _tvaRates = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final rate in TvaUtils.tvaRates.keys) {
      _controllers[rate] = TextEditingController(
        text: TvaUtils.tvaRates[rate].toString(),
      );
      _tvaRates[rate] = TvaUtils.tvaRates[rate]!;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateTvaRate(String rate, String value) {
    final newRate = double.tryParse(value);
    if (newRate != null && newRate >= 0) {
      setState(() {
        _tvaRates[rate] = newRate;
      });
    }
  }

  void _resetToDefaults() {
    setState(() {
      _tvaRates.clear();
      _tvaRates.addAll(TvaUtils.tvaRates);
      for (final entry in _tvaRates.entries) {
        _controllers[entry.key]?.text = entry.value.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        title: const Text(
          'Paramètres TVA',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TVA Information Card
            Card(
              color: const Color(0xFFfff8e1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taux de TVA Français',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFbfa14a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Configurez les taux de TVA selon la réglementation française :',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 5.5% : Taux réduit (livres, presse, etc.)'),
                    const Text('• 10% : Taux intermédiaire (restauration, etc.)'),
                    const Text('• 20% : Taux normal (majorité des biens)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TVA Rates Configuration
            Card(
              color: const Color(0xFFfff8e1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration des taux',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFbfa14a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...TvaUtils.tvaRates.keys.map((rate) => _buildTvaRateField(rate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TVA Calculator
            Card(
              color: const Color(0xFFfff8e1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculateur TVA',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFbfa14a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTvaCalculator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category TVA Rates
            Card(
              color: const Color(0xFFfff8e1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taux par catégorie',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFbfa14a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryTvaRates(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTvaRateField(String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'TVA $rate',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _controllers[rate],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _updateTvaRate(rate, value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvaCalculator() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix HT',
                  suffixText: '€',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // TODO: Implement real-time calculation
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Taux TVA',
                  border: OutlineInputBorder(),
                ),
                items: TvaUtils.getTvaRateOptions().map((rate) {
                  return DropdownMenuItem(
                    value: rate,
                    child: Text(rate),
                  );
                }).toList(),
                onChanged: (value) {
                  // TODO: Implement real-time calculation
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFbfa14a).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFbfa14a)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TVA :'),
              Text('0.00 €'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prix TTC :'),
              Text('0.00 €'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTvaRates() {
    final categories = [
      {'name': 'Boissons', 'rate': '20%'},
      {'name': 'Nourriture', 'rate': '10%'},
      {'name': 'Livres/Presse', 'rate': '5.5%'},
      {'name': 'Autres', 'rate': '20%'},
    ];

    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category['name']!,
                style: const TextStyle(fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFbfa14a),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category['rate']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 
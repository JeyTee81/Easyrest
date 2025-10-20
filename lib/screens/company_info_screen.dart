import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/company.dart';
import '../services/company_service.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyService = CompanyService();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vatController = TextEditingController();
  final _siretController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  Company? _currentCompany;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _vatController.dispose();
    _siretController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final company = await _companyService.getCompany();
      if (company != null) {
        _currentCompany = company;
        _nameController.text = company.name;
        _addressController.text = company.address;
        _phoneController.text = company.phone;
        _vatController.text = company.vatNumber;
        _siretController.text = company.siret;
        _emailController.text = company.email ?? '';
        _websiteController.text = company.website ?? '';
      }
    } catch (e) {
      _showError('Erreur lors du chargement des informations: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCompanyInfo() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final company = Company(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          vatNumber: _vatController.text.trim(),
          siret: _siretController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        );
        
        final success = await _companyService.saveCompany(company);
        
        if (success) {
          _currentCompany = company;
          setState(() {
            _isEditing = false;
          });
          
          _showSuccess('Informations d\'entreprise mises à jour avec succès !');
        } else {
          _showError('Erreur lors de la sauvegarde');
        }
      } catch (e) {
        _showError('Erreur lors de la sauvegarde: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations de l\'entreprise'),
        backgroundColor: const Color(0xFF231f2b),
        foregroundColor: const Color(0xFFbfa14a),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Modifier',
            ),
        ],
      ),
      backgroundColor: const Color(0xFF231f2b),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentCompany == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune information d\'entreprise configurée',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Appuyez sur le bouton + pour ajouter les informations',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête avec statut
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2a2438),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFbfa14a)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    color: _currentCompany!.isConfigured ? Colors.green : Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentCompany!.isConfigured ? 'Entreprise configurée' : 'Configuration incomplète',
                                    style: TextStyle(
                                      color: _currentCompany!.isConfigured ? Colors.green : Colors.orange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Les informations ci-dessous apparaîtront sur tous vos tickets et factures.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Champs d'information
                        _buildInfoField(
                          label: 'Nom du restaurant',
                          controller: _nameController,
                          icon: Icons.restaurant,
                          isRequired: true,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildInfoField(
                          label: 'Adresse',
                          controller: _addressController,
                          icon: Icons.location_on,
                          isRequired: true,
                          maxLines: 3,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildInfoField(
                          label: 'Téléphone',
                          controller: _phoneController,
                          icon: Icons.phone,
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildInfoField(
                          label: 'Numéro de TVA',
                          controller: _vatController,
                          icon: Icons.receipt,
                          isRequired: true,
                          hint: 'Ex: FR 12 345678901',
                          validator: _validateVatNumber,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildInfoField(
                          label: 'Numéro SIRET',
                          controller: _siretController,
                          icon: Icons.business_center,
                          isRequired: true,
                          hint: '14 chiffres',
                          keyboardType: TextInputType.number,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildInfoField(
                          label: 'Email (optionnel)',
                          controller: _emailController,
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildInfoField(
                          label: 'Site web (optionnel)',
                          controller: _websiteController,
                          icon: Icons.web,
                          keyboardType: TextInputType.url,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Boutons d'action
                        if (_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveCompanyInfo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFbfa14a),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Enregistrer'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                    _loadCompanyInfo(); // Recharger les données originales
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFbfa14a),
                                    side: const BorderSide(color: Color(0xFFbfa14a)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Annuler'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  String? _validateVatNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Numéro de TVA est obligatoire';
    }
    // Validation basique du numéro de TVA français
    final vatRegex = RegExp(r'^FR\s?\d{2}\s?\d{9}$');
    if (!vatRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Format de TVA invalide (ex: FR 12 345678901)';
    }
    return null;
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFbfa14a), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFbfa14a),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: !_isEditing,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: _isEditing ? const Color(0xFF2a2438) : const Color(0xFF1a1a1a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFbfa14a)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFbfa14a)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFbfa14a), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator ?? (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est requis';
                  }
                  if (label.contains('Téléphone') && !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                    return 'Numéro de téléphone invalide';
                  }
                  if (label.contains('SIRET') && !RegExp(r'^[0-9]{14}$').hasMatch(value)) {
                    return 'Numéro SIRET invalide (14 chiffres)';
                  }
                  if (label.contains('Email') && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Adresse email invalide';
                  }
                  return null;
                }
              : null),
        ),
      ],
    );
  }
}









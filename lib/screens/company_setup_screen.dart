import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import 'dashboard_screen.dart';

class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyService = CompanyService();
  
  // Contrôleurs pour les champs
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _siretController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _vatNumberController.dispose();
    _siretController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final company = Company(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        vatNumber: _vatNumberController.text.trim(),
        siret: _siretController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
      );

      final success = await _companyService.saveCompany(company);
      
      if (success) {
        await _companyService.markFirstLaunchCompleted();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informations d\'entreprise sauvegardées avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Naviguer vers l'écran principal
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(isManager: true, staffName: 'Manager'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la sauvegarde. Veuillez réessayer.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est obligatoire';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Téléphone est obligatoire';
    }
    // Validation basique du téléphone français
    final phoneRegex = RegExp(r'^(?:(?:\+|00)33|0)\s*[1-9](?:[\s.-]*\d{2}){4}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Format de téléphone invalide (ex: 01 23 45 67 89)';
    }
    return null;
  }

  String? _validateSiret(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'SIRET est obligatoire';
    }
    // Validation du SIRET (14 chiffres)
    final siretRegex = RegExp(r'^\d{14}$');
    if (!siretRegex.hasMatch(value.trim().replaceAll(' ', ''))) {
      return 'SIRET doit contenir 14 chiffres';
    }
    return null;
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

  String? _validateEmail(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Format d\'email invalide';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        title: const Text(
          'Configuration de l\'entreprise',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFbfa14a),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.business,
                      size: 48,
                      color: Color(0xFFbfa14a),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bienvenue dans EasyRest !',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF231f2b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Veuillez configurer les informations de votre restaurant pour personnaliser les tickets et factures.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Formulaire
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations obligatoires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF231f2b),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Nom de l'entreprise
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du restaurant *',
                        hintText: 'Ex: Restaurant Le Gourmet',
                        prefixIcon: Icon(Icons.restaurant),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _validateRequired(value, 'Nom du restaurant'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Adresse
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse *',
                        hintText: 'Ex: 123 Rue de la Paix, 75001 Paris',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) => _validateRequired(value, 'Adresse'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone *',
                        hintText: 'Ex: 01 23 45 67 89',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Numéro de TVA
                    TextFormField(
                      controller: _vatNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de TVA *',
                        hintText: 'Ex: FR 12 345678901',
                        prefixIcon: Icon(Icons.receipt_long),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateVatNumber,
                    ),
                    const SizedBox(height: 16),
                    
                    // SIRET
                    TextFormField(
                      controller: _siretController,
                      decoration: const InputDecoration(
                        labelText: 'SIRET *',
                        hintText: 'Ex: 12345678901234',
                        prefixIcon: Icon(Icons.business_center),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(14),
                      ],
                      validator: _validateSiret,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Informations optionnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF231f2b),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Ex: contact@restaurant.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    
                    // Site web
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Site web',
                        hintText: 'Ex: www.restaurant.com',
                        prefixIcon: Icon(Icons.web),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton de sauvegarde
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCompany,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFbfa14a),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Sauvegarde...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Sauvegarder et continuer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

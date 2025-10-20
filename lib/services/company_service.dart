import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company.dart';

class CompanyService {
  static const String _companyKey = 'company_info';
  static const String _firstLaunchKey = 'first_launch_completed';

  // Instance singleton
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  // Cache de l'entreprise
  Company? _cachedCompany;

  /// Vérifier si c'est le premier lancement
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_firstLaunchKey) ?? false);
    } catch (e) {
      print('Erreur lors de la vérification du premier lancement: $e');
      return true; // En cas d'erreur, considérer comme premier lancement
    }
  }

  /// Marquer que le premier lancement est terminé
  Future<void> markFirstLaunchCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true);
    } catch (e) {
      print('Erreur lors de la marque du premier lancement: $e');
    }
  }

  /// Sauvegarder les informations de l'entreprise
  Future<bool> saveCompany(Company company) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyJson = jsonEncode(company.toMap());
      final success = await prefs.setString(_companyKey, companyJson);
      
      if (success) {
        _cachedCompany = company;
        print('Informations d\'entreprise sauvegardées avec succès');
      }
      
      return success;
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'entreprise: $e');
      return false;
    }
  }

  /// Charger les informations de l'entreprise
  Future<Company?> getCompany() async {
    try {
      // Retourner le cache si disponible
      if (_cachedCompany != null) {
        return _cachedCompany;
      }

      final prefs = await SharedPreferences.getInstance();
      final companyJson = prefs.getString(_companyKey);
      
      if (companyJson != null && companyJson.isNotEmpty) {
        final companyMap = jsonDecode(companyJson) as Map<String, dynamic>;
        _cachedCompany = Company.fromMap(companyMap);
        return _cachedCompany;
      }
      
      return null;
    } catch (e) {
      print('Erreur lors du chargement de l\'entreprise: $e');
      return null;
    }
  }

  /// Vérifier si l'entreprise est configurée
  Future<bool> isCompanyConfigured() async {
    try {
      final company = await getCompany();
      return company?.isConfigured ?? false;
    } catch (e) {
      print('Erreur lors de la vérification de la configuration: $e');
      return false;
    }
  }

  /// Mettre à jour les informations de l'entreprise
  Future<bool> updateCompany(Company company) async {
    return await saveCompany(company);
  }

  /// Supprimer les informations de l'entreprise (pour les tests)
  Future<bool> deleteCompany() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_companyKey);
      
      if (success) {
        _cachedCompany = null;
        print('Informations d\'entreprise supprimées');
      }
      
      return success;
    } catch (e) {
      print('Erreur lors de la suppression de l\'entreprise: $e');
      return false;
    }
  }

  /// Réinitialiser le premier lancement (pour les tests)
  Future<bool> resetFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_firstLaunchKey);
    } catch (e) {
      print('Erreur lors de la réinitialisation du premier lancement: $e');
      return false;
    }
  }

  /// Obtenir le nom de l'entreprise (méthode de commodité)
  Future<String> getCompanyName() async {
    final company = await getCompany();
    return company?.name ?? 'Restaurant';
  }

  /// Obtenir l'adresse de l'entreprise (méthode de commodité)
  Future<String> getCompanyAddress() async {
    final company = await getCompany();
    return company?.address ?? '';
  }

  /// Obtenir le téléphone de l'entreprise (méthode de commodité)
  Future<String> getCompanyPhone() async {
    final company = await getCompany();
    return company?.phone ?? '';
  }

  /// Obtenir le numéro de TVA (méthode de commodité)
  Future<String> getVatNumber() async {
    final company = await getCompany();
    return company?.vatNumber ?? '';
  }

  /// Obtenir le SIRET (méthode de commodité)
  Future<String> getSiret() async {
    final company = await getCompany();
    return company?.siret ?? '';
  }
}

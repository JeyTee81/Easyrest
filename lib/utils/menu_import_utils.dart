import '../models/menu_item.dart';

class MenuImportUtils {
  // CSV Headers for menu import
  static const List<String> csvHeaders = [
    'Nom',
    'Prix_TTC',
    'TVA_Rate',
    'Description',
    'Catégorie',
    'Type',
    'Disponible',
    'Menu_Préétabli',
    'Groupe_Menu', // For preset menu items (Entrée, Plat, Dessert, Boisson)
  ];

  // Generate CSV template
  static String generateCsvTemplate() {
    final buffer = StringBuffer();
    
    // Add headers
    buffer.writeln(csvHeaders.join(','));
    
    // Add example rows
    buffer.writeln('Salade César,12.50,10%,Salade avec poulet et parmesan,Entrées,Plat,1,0,');
    buffer.writeln('Steak Frites,18.90,10%,Steak de bœuf avec frites maison,Plats,Plat,1,0,');
    buffer.writeln('Tiramisu,7.50,10%,Dessert italien classique,Desserts,Dessert,1,0,');
    buffer.writeln('Coca Cola,3.50,20%,Boisson gazeuse,Boissons,Boisson,1,0,');
    buffer.writeln('Menu Découverte,25.00,10%,Menu complet avec entrée plat dessert,Menus préétablis,Menu,1,1,Entrée');
    buffer.writeln('Salade Niçoise,0.00,10%,Incluse dans le menu,Entrées,Plat,1,0,Entrée');
    buffer.writeln('Poulet Rôti,0.00,10%,Incluse dans le menu,Plats,Plat,1,0,Plat');
    buffer.writeln('Crème Brûlée,0.00,10%,Incluse dans le menu,Desserts,Dessert,1,0,Dessert');
    
    return buffer.toString();
  }

  // Parse CSV content
  static List<Map<String, dynamic>> parseCsvContent(String csvContent) {
    final lines = csvContent.trim().split('\n');
    if (lines.isEmpty) return [];

    final headers = lines[0].split(',');
    final data = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split(',');
      if (values.length >= headers.length) {
        final row = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          row[headers[j]] = values[j].trim();
        }
        data.add(row);
      }
    }

    return data;
  }

  // Convert CSV data to MenuItem objects
  static List<MenuItem> csvToMenuItems(List<Map<String, dynamic>> csvData) {
    final menuItems = <MenuItem>[];
    
    for (final row in csvData) {
      try {
        final name = row['Nom']?.toString() ?? '';
        if (name.isEmpty) continue;

        final priceTtc = double.tryParse(row['Prix_TTC']?.toString() ?? '0') ?? 0.0;
        final tvaRate = row['TVA_Rate']?.toString() ?? '10%';
        final description = row['Description']?.toString() ?? '';
        final category = row['Catégorie']?.toString() ?? '';
        final type = row['Type']?.toString() ?? '';
        final isAvailable = row['Disponible']?.toString() == '1';
        final isPresetMenu = row['Menu_Préétabli']?.toString() == '1';
        final group = row['Groupe_Menu']?.toString() ?? '';

        if (isPresetMenu) {
          // Create preset menu
          final menuItem = MenuItem.presetMenu(
            name: name,
            priceTtc: priceTtc,
            description: description,
            isAvailable: isAvailable,
          );
          menuItems.add(menuItem);
        } else {
          // Create regular menu item
          final menuItem = MenuItem.withPriceTtc(
            name: name,
            priceTtc: priceTtc,
            tvaRate: tvaRate,
            description: description,
            category: category,
            type: type,
            isAvailable: isAvailable,
          );
          menuItems.add(menuItem);
        }
      } catch (e) {
        print('Error parsing menu item: $e');
        continue;
      }
    }

    return menuItems;
  }

  // Generate import instructions
  static String getImportInstructions() {
    return '''
INSTRUCTIONS D'IMPORT DE MENU

1. FORMAT CSV REQUIS:
   - Utilisez des virgules (,) pour séparer les colonnes
   - Pas d'espaces autour des virgules
   - Utilisez des points (.) pour les décimales

2. COLONNES OBLIGATOIRES:
   - Nom: Nom du plat/boisson
   - Prix_TTC: Prix TTC (utilisez 0.00 pour les items inclus dans un menu)
   - TVA_Rate: Taux de TVA (5.5%, 10%, 20%)
   - Description: Description du plat
   - Catégorie: Entrées, Plats, Desserts, Boissons, etc.
   - Type: Plat, Boisson, Dessert, etc.
   - Disponible: 1 pour disponible, 0 pour indisponible
   - Menu_Préétabli: 1 pour menu préétabli, 0 pour item normal
   - Groupe_Menu: Entrée, Plat, Dessert, Boisson (pour items de menu)

3. EXEMPLES:
   - Item normal: "Salade César,12.50,10%,Salade avec poulet,Entrées,Plat,1,0,"
   - Menu préétabli: "Menu Découverte,25.00,10%,Menu complet,Menus préétablis,Menu,1,1,Entrée"
   - Item de menu: "Salade Niçoise,0.00,10%,Incluse dans le menu,Entrées,Plat,1,0,Entrée"

4. CONSEILS:
   - Vérifiez que tous les prix sont corrects
   - Assurez-vous que les catégories sont cohérentes
   - Pour les menus préétablis, ajoutez d'abord le menu, puis ses items
   - Utilisez 0.00 pour les prix des items inclus dans un menu
''';
  }

  // Validate CSV data
  static List<String> validateCsvData(List<Map<String, dynamic>> csvData) {
    final errors = <String>[];
    
    for (int i = 0; i < csvData.length; i++) {
      final row = csvData[i];
      final rowNumber = i + 2; // +2 because of header row and 0-based index
      
      // Check required fields
      if (row['Nom']?.toString().isEmpty ?? true) {
        errors.add('Ligne $rowNumber: Nom manquant');
      }
      
      if (row['Prix_TTC'] == null || double.tryParse(row['Prix_TTC'].toString()) == null) {
        errors.add('Ligne $rowNumber: Prix_TTC invalide');
      }
      
      if (row['Catégorie']?.toString().isEmpty ?? true) {
        errors.add('Ligne $rowNumber: Catégorie manquante');
      }
      
      if (row['Type']?.toString().isEmpty ?? true) {
        errors.add('Ligne $rowNumber: Type manquant');
      }
    }
    
    return errors;
  }
} 
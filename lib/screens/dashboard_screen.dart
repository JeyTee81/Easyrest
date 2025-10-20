import 'package:flutter/material.dart';
import '../main.dart';
import 'splash_screen.dart';
import 'menu_screen.dart';
import 'stock_screen.dart';
import 'tables_screen.dart';
import 'orders_screen.dart';
import 'printers_screen.dart';
import 'staff_screen.dart';
import 'settings_screen.dart';
import 'tva_settings_screen.dart';
import 'preset_menus_screen.dart';
import 'menu_import_screen.dart';
import 'cash_register_screen.dart';
import 'remote_connection_screen.dart';
import 'database_diagnostic_screen.dart';
import 'backup_management_screen.dart';
import 'company_info_screen.dart';
import 'reservations_screen.dart';
import '../services/touch_screen_service.dart';

class DashboardScreen extends StatefulWidget {
  final bool isManager;
  final bool isSuperUser;
  final String staffName;
  const DashboardScreen({super.key, this.isManager = true, this.isSuperUser = false, required this.staffName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  List<Widget> _getDashboardButtons() {
    List<Widget> buttons = [];
    
    // Boutons accessibles à tous les rôles
    buttons.add(_DashboardButton(
      icon: Icons.receipt_long,
      label: "Commandes",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
        );
      },
    ));
    
    buttons.add(_DashboardButton(
      icon: Icons.point_of_sale,
      label: "Caisse",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CashRegisterScreen(
            managerName: widget.staffName,
            isManager: widget.isManager,
          )),
        );
      },
    ));
    
    // Boutons accessibles uniquement aux Managers et Super Utilisateurs
    if (widget.isManager || widget.isSuperUser) {
      buttons.add(_DashboardButton(
        icon: Icons.restaurant_menu,
        label: "Menu",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.restaurant,
        label: "Menus préétablis",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PresetMenusScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.inventory,
        label: "Stock",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.table_restaurant,
        label: "Tables",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TablesScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.event_available,
        label: "Réservations",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReservationsScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.people,
        label: "Personnel",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StaffScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.print,
        label: "Imprimantes",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PrintersScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.business,
        label: "Entreprise",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompanyInfoScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.cloud_sync,
        label: "Connexion Distante",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RemoteConnectionScreen()),
          );
        },
      ));
    }
    
    // Boutons accessibles uniquement aux Super Utilisateurs
    if (widget.isSuperUser) {
      buttons.add(_DashboardButton(
        icon: Icons.settings,
        label: "Paramètres",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.account_balance,
        label: "TVA",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TvaSettingsScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.upload_file,
        label: "Import Menu",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuImportScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.backup,
        label: "Sauvegarde",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupManagementScreen()),
          );
        },
      ));
      
      buttons.add(_DashboardButton(
        icon: Icons.analytics,
        label: "Diagnostic DB",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DatabaseDiagnosticScreen()),
          );
        },
      ));
    }
    
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231f2b),
        elevation: 0,
        title: const Row(
          children: [
            // If you have a logo asset, uncomment the next line:
            // Image.asset('assets/logo.png', height: 40),
            // const SizedBox(width: 12),
            Text(
              "EasyRest",
              style: TextStyle(
                color: Color(0xFFbfa14a),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFbfa14a)),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2438),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFbfa14a)),
            ),
            child: Column(
              children: [
                Text(
                  'Bienvenue, ${widget.staffName}',
                  style: const TextStyle(
                    color: Color(0xFFbfa14a),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isSuperUser ? 'Mode Super Utilisateur' : 
                  widget.isManager ? 'Mode Manager' : 'Mode Employé',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Main dashboard content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: TouchScreenService.optimalMaxWidth),
                child: GridView.count(
                  padding: TouchScreenService.optimalPadding,
                  crossAxisCount: TouchScreenService.optimalGridColumns,
                  crossAxisSpacing: TouchScreenService.optimalSpacing,
                  mainAxisSpacing: TouchScreenService.optimalSpacing,
                  childAspectRatio: TouchScreenService.optimalGridAspectRatio,
                  children: _getDashboardButtons(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2438),
          title: const Text(
            'Déconnexion',
            style: TextStyle(color: Color(0xFFbfa14a)),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFbfa14a),
                foregroundColor: Colors.white,
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2a2438),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFbfa14a)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: TouchScreenService.optimalIconSize,
              color: const Color(0xFFbfa14a),
            ),
            SizedBox(height: TouchScreenService.optimalSpacing / 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TouchScreenService.optimalTextStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

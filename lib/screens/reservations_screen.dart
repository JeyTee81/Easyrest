import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../models/table_restaurant.dart';
import '../services/api_database_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final ApiDatabaseService _dbService = ApiDatabaseService();
  
  DateTime _selectedDate = DateTime.now();
  List<Reservation> _reservations = [];
  List<TableRestaurant> _tables = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reservations = await _dbService.getReservationsByDate(_selectedDate);
      final tables = await _dbService.getTables();

      setState(() {
        _reservations = reservations;
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFbfa14a),
              onPrimary: Color(0xFF231f2b),
              surface: Color(0xFF2a2438),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && date != _selectedDate) {
      setState(() {
        _selectedDate = date;
      });
      await _loadData();
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

  Future<void> _addReservation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReservationScreen(
          selectedDate: _selectedDate,
          tables: _tables,
        ),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _editReservation(Reservation reservation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReservationScreen(
          selectedDate: _selectedDate,
          reservation: reservation,
          tables: _tables,
        ),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _deleteReservation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2438),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la réservation de ${reservation.customerName} ?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFFbfa14a)),
            ),
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
        await _dbService.deleteReservation(reservation.id!);
        _showSuccess('Réservation supprimée');
        await _loadData();
      } catch (e) {
        _showError('Erreur lors de la suppression: $e');
      }
    }
  }

  Future<void> _updateReservationStatus(Reservation reservation, String newStatus) async {
    try {
      final updatedReservation = reservation.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      
      await _dbService.updateReservation(updatedReservation);
      _showSuccess('Statut mis à jour');
      await _loadData();
    } catch (e) {
      _showError('Erreur lors de la mise à jour: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == tomorrow) {
      return 'Demain';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  List<Reservation> _getReservationsForTimeSlot(int hour) {
    return _reservations.where((reservation) => 
      reservation.reservationTime.hour == hour
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        title: const Text(
          'Réservations',
          style: TextStyle(color: Color(0xFFbfa14a)),
        ),
        backgroundColor: const Color(0xFF2a2438),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        actions: [
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Changer la date',
          ),
          IconButton(
            onPressed: _addReservation,
            icon: const Icon(Icons.add),
            tooltip: 'Nouvelle réservation',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFbfa14a)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // En-tête avec la date sélectionnée
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFbfa14a).withOpacity(0.1),
                            const Color(0xFFbfa14a).withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFFbfa14a),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(_selectedDate),
                                style: const TextStyle(
                                  color: Color(0xFFbfa14a),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_reservations.length} réservation(s)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Liste des réservations par créneaux horaires
                    Expanded(
                      child: _reservations.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucune réservation pour cette date',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: 24, // 24 heures
                              itemBuilder: (context, index) {
                                final hour = index;
                                final reservations = _getReservationsForTimeSlot(hour);
                                
                                if (reservations.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Card(
                                  color: const Color(0xFF2a2438),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // En-tête de l'heure
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFbfa14a).withOpacity(0.1),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          '${hour.toString().padLeft(2, '0')}:00',
                                          style: const TextStyle(
                                            color: Color(0xFFbfa14a),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      
                                      // Liste des réservations pour cette heure
                                      ...reservations.map((reservation) => 
                                        _buildReservationCard(reservation)
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final tableNumbers = reservation.tableIds.map((id) {
      final table = _tables.firstWhere(
        (t) => t.id == id,
        orElse: () => TableRestaurant(
          id: id,
          number: id,
          capacity: 4,
          roomId: 1,
          status: 'Libre',
        ),
      );
      return table.number;
    }).join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icône de statut
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: reservation.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              reservation.statusIcon,
              color: reservation.statusColor,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Informations de la réservation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reservation.customerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      reservation.reservationTime.toString(),
                      style: const TextStyle(
                        color: Color(0xFFbfa14a),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reservation.numberOfGuests} personnes',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.table_restaurant,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Table(s) $tableNumbers',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                if (reservation.specialRequests != null && 
                    reservation.specialRequests!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reservation.specialRequests!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Menu d'actions
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFFbfa14a),
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editReservation(reservation);
                  break;
                case 'confirm':
                  _updateReservationStatus(reservation, 'confirmed');
                  break;
                case 'cancel':
                  _updateReservationStatus(reservation, 'cancelled');
                  break;
                case 'complete':
                  _updateReservationStatus(reservation, 'completed');
                  break;
                case 'no_show':
                  _updateReservationStatus(reservation, 'no_show');
                  break;
                case 'delete':
                  _deleteReservation(reservation);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFFbfa14a)),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'confirm',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Confirmer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Annuler'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Terminer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'no_show',
                child: Row(
                  children: [
                    Icon(Icons.person_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Absent'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Écran pour ajouter/modifier une réservation
class AddReservationScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<TableRestaurant> tables;
  final Reservation? reservation;

  const AddReservationScreen({
    super.key,
    required this.selectedDate,
    required this.tables,
    this.reservation,
  });

  @override
  State<AddReservationScreen> createState() => _AddReservationScreenState();
}

class _AddReservationScreenState extends State<AddReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _guestsController = TextEditingController();
  final _requestsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  CustomTimeOfDay _selectedTime = const CustomTimeOfDay(hour: 19, minute: 0);
  List<int> _selectedTableIds = [];
  String _status = 'confirmed';

  final ApiDatabaseService _dbService = ApiDatabaseService();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    
    if (widget.reservation != null) {
      final reservation = widget.reservation!;
      _nameController.text = reservation.customerName;
      _phoneController.text = reservation.customerPhone ?? '';
      _emailController.text = reservation.customerEmail ?? '';
      _guestsController.text = reservation.numberOfGuests.toString();
      _requestsController.text = reservation.specialRequests ?? '';
      _selectedDate = reservation.reservationDate;
      _selectedTime = reservation.reservationTime;
      _selectedTableIds = List.from(reservation.tableIds);
      _status = reservation.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _guestsController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFbfa14a),
              onPrimary: Color(0xFF231f2b),
              surface: Color(0xFF2a2438),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedTime.hour, minute: _selectedTime.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFbfa14a),
              onPrimary: Color(0xFF231f2b),
              surface: Color(0xFF2a2438),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = CustomTimeOfDay(hour: time.hour, minute: time.minute);
      });
    }
  }

  void _toggleTableSelection(int tableId) {
    setState(() {
      if (_selectedTableIds.contains(tableId)) {
        _selectedTableIds.remove(tableId);
      } else {
        _selectedTableIds.add(tableId);
      }
    });
  }

  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTableIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une table'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final reservation = Reservation(
        id: widget.reservation?.id,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        customerEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        reservationDate: _selectedDate,
        reservationTime: _selectedTime,
        numberOfGuests: int.parse(_guestsController.text),
        tableIds: _selectedTableIds,
        specialRequests: _requestsController.text.trim().isEmpty ? null : _requestsController.text.trim(),
        status: _status,
        createdAt: widget.reservation?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.reservation == null) {
        await _dbService.insertReservation(reservation);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _dbService.updateReservation(reservation);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231f2b),
      appBar: AppBar(
        title: Text(
          widget.reservation == null ? 'Nouvelle réservation' : 'Modifier la réservation',
          style: const TextStyle(color: Color(0xFFbfa14a)),
        ),
        backgroundColor: const Color(0xFF2a2438),
        iconTheme: const IconThemeData(color: Color(0xFFbfa14a)),
        actions: [
          IconButton(
            onPressed: _saveReservation,
            icon: const Icon(Icons.save),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informations client
            Card(
              color: const Color(0xFF2a2438),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations client',
                      style: TextStyle(
                        color: Color(0xFFbfa14a),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFfff8e1),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFfff8e1),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFfff8e1),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Détails de la réservation
            Card(
              color: const Color(0xFF2a2438),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails de la réservation',
                      style: TextStyle(
                        color: Color(0xFFbfa14a),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFFfff8e1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF231f2b)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(color: Color(0xFF231f2b)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFFfff8e1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0xFF231f2b)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTime.toString(),
                                    style: const TextStyle(color: Color(0xFF231f2b)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _guestsController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de personnes *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFfff8e1),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nombre de personnes est obligatoire';
                        }
                        final guests = int.tryParse(value);
                        if (guests == null || guests <= 0) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _requestsController,
                      decoration: const InputDecoration(
                        labelText: 'Demandes spéciales',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFfff8e1),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sélection des tables
            Card(
              color: const Color(0xFF2a2438),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tables à réserver',
                      style: TextStyle(
                        color: Color(0xFFbfa14a),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez les tables pour cette réservation',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.tables.map((table) {
                        final isSelected = _selectedTableIds.contains(table.id);
                        return FilterChip(
                          label: Text('Table ${table.number} (${table.capacity} pers.)'),
                          selected: isSelected,
                          onSelected: (selected) => _toggleTableSelection(table.id!),
                          selectedColor: const Color(0xFFbfa14a).withOpacity(0.3),
                          checkmarkColor: const Color(0xFFbfa14a),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFFbfa14a) : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statut (seulement pour la modification)
            if (widget.reservation != null) ...[
              Card(
                color: const Color(0xFF2a2438),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statut',
                        style: TextStyle(
                          color: Color(0xFFbfa14a),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFfff8e1),
                        ),
                        dropdownColor: const Color(0xFFfff8e1),
                        style: const TextStyle(color: Color(0xFF231f2b)),
                        items: const [
                          DropdownMenuItem(
                            value: 'confirmed',
                            child: Text('Confirmée'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Annulée'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Terminée'),
                          ),
                          DropdownMenuItem(
                            value: 'no_show',
                            child: Text('Absent'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _saveReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFbfa14a),
                foregroundColor: const Color(0xFF231f2b),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.reservation == null ? 'Créer la réservation' : 'Mettre à jour',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/cash_register_closing.dart';
import '../models/bill.dart';
import '../config/reports_config.dart';

class ExcelUtils {
  static const String _reportsFolder = 'EasyRest_Reports';
  
  /// Generate Excel-compatible CSV file for daily cash register closing
  static Future<String> generateDailyReport({
    required CashRegisterClosing closing,
    required List<Bill> bills,
    required String managerName,
  }) async {
    try {
      print('Starting daily report generation...');
      final directory = await _getReportsDirectory();
      print('Reports directory: ${directory.path}');
      
      final fileName = 'caisse_${_formatDateForFilename(closing.date)}.csv';
      final file = File('${directory.path}/$fileName');
      print('Target file: ${file.path}');
      
      final csvContent = _buildDailyReportCsv(closing, bills, managerName);
      print('CSV content generated, length: ${csvContent.length} characters');
      
      await file.writeAsString(csvContent, encoding: utf8);
      print('File written successfully: ${file.path}');
      
      return file.path;
    } catch (e) {
      print('Error generating daily report: $e');
      throw Exception('Failed to generate daily report: $e');
    }
  }

  /// Generate monthly summary report
  static Future<String> generateMonthlyReport({
    required List<CashRegisterClosing> closings,
    required String month,
    required int year,
  }) async {
    try {
      final directory = await _getReportsDirectory();
      final fileName = 'Rapport_Mensuel_${month}_$year.csv';
      final file = File('${directory.path}/$fileName');
      
      final csvContent = _buildMonthlyReportCsv(closings, month, year);
      await file.writeAsString(csvContent, encoding: utf8);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to generate monthly report: $e');
    }
  }

  /// Get the reports directory, create if it doesn't exist
  static Future<Directory> _getReportsDirectory() async {
    try {
      // First, try to get the configured path
      final configuredPath = await ReportsConfig.getReportsPath();
      if (configuredPath != null && await ReportsConfig.isPathValid(configuredPath)) {
        final directory = Directory(configuredPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        print('Using configured reports directory: ${directory.path}');
        return directory;
      }
      
      // If no configured path or invalid, use default
      final defaultPath = await ReportsConfig.getDefaultReportsPath();
      final directory = Directory(defaultPath);
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      print('Using default reports directory: ${directory.path}');
      return directory;
    } catch (e) {
      print('Error accessing reports directory: $e');
      
      // Last resort: try to create in temp directory
      final tempDir = Directory.systemTemp;
      final reportsDir = Directory('${tempDir.path}/$_reportsFolder');
      
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      
      print('Using temp directory: ${reportsDir.path}');
      return reportsDir;
    }
  }

  /// Build CSV content for daily report
  static String _buildDailyReportCsv(
    CashRegisterClosing closing,
    List<Bill> bills,
    String managerName,
  ) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('RAPPORT DE CAISSE - ${_formatDate(closing.date)}');
    buffer.writeln('Fermé par: $managerName');
    buffer.writeln('Heure de fermeture: ${_formatDateTime(closing.closedAt)}');
    buffer.writeln('');
    
    // Summary
    buffer.writeln('RÉSUMÉ JOURNALIER');
    buffer.writeln('Total HT,Total TTC,Total TVA,Nombre de factures');
    buffer.writeln('${closing.totalHt.toStringAsFixed(2)},${closing.totalTtc.toStringAsFixed(2)},${closing.totalTva.toStringAsFixed(2)},${closing.numberOfBills}');
    buffer.writeln('');
    
    // Payment methods breakdown
    buffer.writeln('RÉPARTITION PAR MOYEN DE PAIEMENT');
    buffer.writeln('Moyen de paiement,Montant');
    for (final entry in closing.paymentMethods.entries) {
      buffer.writeln('${entry.key},${entry.value.toStringAsFixed(2)}');
    }
    buffer.writeln('');
    
    // Detailed bills
    buffer.writeln('DÉTAIL DES FACTURES');
    buffer.writeln('Heure,Table,Moyen de paiement,Total HT,Total TVA,Total TTC');
    for (final bill in bills) {
      buffer.writeln('${_formatTime(bill.createdAt)},${bill.tableName},${bill.paymentMethod},${bill.totalHt.toStringAsFixed(2)},${bill.totalTva.toStringAsFixed(2)},${bill.totalTtc.toStringAsFixed(2)}');
    }
    
    return buffer.toString();
  }

  /// Build CSV content for monthly report
  static String _buildMonthlyReportCsv(
    List<CashRegisterClosing> closings,
    String month,
    int year,
  ) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('RAPPORT MENSUEL - $month $year');
    buffer.writeln('');
    
    // Summary
    buffer.writeln('RÉSUMÉ MENSUEL');
    buffer.writeln('Jour,Total HT,Total TTC,Total TVA,Nombre de factures');
    
    double monthlyHt = 0;
    double monthlyTtc = 0;
    double monthlyTva = 0;
    int totalBills = 0;
    
    for (final closing in closings) {
      buffer.writeln('${_formatDate(closing.date)},${closing.totalHt.toStringAsFixed(2)},${closing.totalTtc.toStringAsFixed(2)},${closing.totalTva.toStringAsFixed(2)},${closing.numberOfBills}');
      
      monthlyHt += closing.totalHt;
      monthlyTtc += closing.totalTtc;
      monthlyTva += closing.totalTva;
      totalBills += closing.numberOfBills;
    }
    
    buffer.writeln('');
    buffer.writeln('TOTAUX MENSUELS');
    buffer.writeln('Total HT,Total TTC,Total TVA,Nombre total de factures');
    buffer.writeln('${monthlyHt.toStringAsFixed(2)},${monthlyTtc.toStringAsFixed(2)},${monthlyTva.toStringAsFixed(2)},$totalBills');
    buffer.writeln('');
    
    // Payment methods summary
    final paymentMethodsSummary = <String, double>{};
    for (final closing in closings) {
      for (final entry in closing.paymentMethods.entries) {
        paymentMethodsSummary[entry.key] = (paymentMethodsSummary[entry.key] ?? 0) + entry.value;
      }
    }
    
    buffer.writeln('RÉPARTITION MENSUELLE PAR MOYEN DE PAIEMENT');
    buffer.writeln('Moyen de paiement,Montant total');
    for (final entry in paymentMethodsSummary.entries) {
      buffer.writeln('${entry.key},${entry.value.toStringAsFixed(2)}');
    }
    
    return buffer.toString();
  }

  /// Get list of available reports
  static Future<List<FileSystemEntity>> getAvailableReports() async {
    try {
      final directory = await _getReportsDirectory();
      final files = directory.listSync()
          .where((entity) => entity is File && entity.path.endsWith('.csv'))
          .toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      throw Exception('Failed to get available reports: $e');
    }
  }

  /// Delete a report file
  static Future<void> deleteReport(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  /// Share a report file (placeholder for future implementation)
  static Future<void> shareReport(String filePath) async {
    // This would integrate with platform-specific sharing
    // For now, just return the file path
    print('Report available at: $filePath');
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDateForFilename(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}${date.month.toString().padLeft(2, '0')}${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
  }
} 
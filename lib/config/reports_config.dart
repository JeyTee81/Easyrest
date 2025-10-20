import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsConfig {
  static const String _reportsPathKey = 'reports_directory_path';
  static String? _cachedReportsPath;

  /// Get the configured reports directory path
  static Future<String?> getReportsPath() async {
    if (_cachedReportsPath != null) {
      return _cachedReportsPath;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_reportsPathKey);
      _cachedReportsPath = path;
      return path;
    } catch (e) {
      print('Error getting reports path: $e');
      return null;
    }
  }

  /// Set the reports directory path
  static Future<void> setReportsPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reportsPathKey, path);
      _cachedReportsPath = path;
      print('Reports path set to: $path');
    } catch (e) {
      print('Error setting reports path: $e');
    }
  }

  /// Check if a path is valid and writable
  static Future<bool> isPathValid(String path) async {
    try {
      final directory = Directory(path);
      
      // Check if directory exists
      if (!await directory.exists()) {
        // Try to create it
        await directory.create(recursive: true);
      }
      
      // Test if we can write to it
      final testFile = File('${directory.path}/.write_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return true;
    } catch (e) {
      print('Path validation failed: $e');
      return false;
    }
  }

  /// Get default reports path (Documents/EasyRest_Reports)
  static Future<String> getDefaultReportsPath() async {
    try {
      final documentsDir = await _getDocumentsDirectory();
      return '${documentsDir.path}/EasyRest_Reports';
    } catch (e) {
      // Fallback to current directory
      return '${Directory.current.path}/EasyRest_Reports';
    }
  }

  /// Get documents directory with fallback
  static Future<Directory> _getDocumentsDirectory() async {
    try {
      // Try to get the user's documents directory
      final documentsDir = Directory('${Platform.environment['USERPROFILE'] ?? ''}/Documents');
      if (await documentsDir.exists()) {
        return documentsDir;
      }
    } catch (e) {
      print('Error getting documents directory: $e');
    }
    
    // Fallback to current directory
    return Directory.current;
  }

  /// Clear cached path (useful for testing)
  static void clearCache() {
    _cachedReportsPath = null;
  }
}










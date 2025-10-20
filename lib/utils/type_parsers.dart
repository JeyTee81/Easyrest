// Utility functions for parsing types from PostgreSQL results

/// Parse a double value from PostgreSQL result
/// PostgreSQL returns numeric values as strings, so we need to handle conversion
double parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

/// Parse an integer value from PostgreSQL result
int parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

/// Parse a boolean value from PostgreSQL result
bool parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final lowerValue = value.toLowerCase();
    return lowerValue == 'true' || lowerValue == '1' || lowerValue == 't';
  }
  return false;
}

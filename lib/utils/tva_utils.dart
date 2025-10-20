class TvaUtils {
  // French TVA rates
  static const double tvaReduced = 5.5; // 5.5% - Reduced rate
  static const double tvaIntermediate = 10.0; // 10% - Intermediate rate
  static const double tvaStandard = 20.0; // 20% - Standard rate

  // TVA categories with descriptions
  static const Map<String, double> tvaRates = {
    '5.5%': tvaReduced,
    '10%': tvaIntermediate,
    '20%': tvaStandard,
  };

  // Get TVA rate by percentage string
  static double getTvaRate(String percentage) {
    return tvaRates[percentage] ?? tvaStandard;
  }

  // Calculate TVA amount from price excluding TVA
  static double calculateTvaAmount(double priceHt, String tvaRate) {
    final rate = getTvaRate(tvaRate);
    return priceHt * (rate / 100);
  }

  // Calculate price including TVA from price excluding TVA
  static double calculatePriceTtc(double priceHt, String tvaRate) {
    final tvaAmount = calculateTvaAmount(priceHt, tvaRate);
    return priceHt + tvaAmount;
  }

  // Calculate price excluding TVA from price including TVA
  static double calculatePriceHt(double priceTtc, String tvaRate) {
    final rate = getTvaRate(tvaRate);
    return priceTtc / (1 + (rate / 100));
  }

  // Get TVA amount from price including TVA
  static double getTvaAmountFromTtc(double priceTtc, String tvaRate) {
    final priceHt = calculatePriceHt(priceTtc, tvaRate);
    return priceTtc - priceHt;
  }

  // Format TVA rate for display
  static String formatTvaRate(String tvaRate) {
    return 'TVA $tvaRate';
  }

  // Get TVA rate options for dropdown
  static List<String> getTvaRateOptions() {
    return tvaRates.keys.toList();
  }

  // Validate TVA rate
  static bool isValidTvaRate(String tvaRate) {
    return tvaRates.containsKey(tvaRate);
  }

  // Get default TVA rate (20% for most items)
  static String getDefaultTvaRate() {
    return '20%';
  }

  // Get TVA rate for specific categories
  static String getTvaRateForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'boissons':
      case 'boisson':
      case 'drinks':
        return '20%';
      case 'nourriture':
      case 'food':
      case 'alimentation':
        return '10%';
      case 'livres':
      case 'books':
      case 'presse':
        return '5.5%';
      default:
        return '20%';
    }
  }
} 
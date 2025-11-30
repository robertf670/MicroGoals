class AppConstants {
  AppConstants._(); // Private constructor

  // Goal limits
  static const int freeGoalLimit = 3;  // 3 active goals for free
  static const int premiumGoalLimit = 30;  // 30 active goals for premium

  // Product IDs
  static const String premiumAnnualProductId = 'premium_annual';
  static const String premiumLifetimeProductId = 'premium_lifetime';

  // Database
  static const String databaseName = 'microgoals.db';
  static const int databaseVersion = 1;

  // SharedPreferences keys
  static const String premiumStatusKey = 'is_premium';
  static const String purchaseTokenKey = 'purchase_token';

  // Default values
  static const String defaultIcon = 'flag';
  static const String defaultColor = '#9C27B0';  // Purple
  static const String defaultUnit = '';  // No unit by default

  // Milestone percentages (premium)
  static const List<double> milestonePercentages = [25.0, 50.0, 75.0];

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration purchaseProcessingDelay = Duration(seconds: 1);
}


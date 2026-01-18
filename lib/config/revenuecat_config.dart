import 'package:flutter_dotenv/flutter_dotenv.dart';

/// RevenueCat configuration from environment variables
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Get RevenueCat API key for iOS
  static String get iosApiKey {
    final key = dotenv.env['REVENUECAT_IOS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('REVENUECAT_IOS_API_KEY not found in .env file');
    }
    return key;
  }

  /// Get RevenueCat API key for Android
  static String get androidApiKey {
    final key = dotenv.env['REVENUECAT_ANDROID_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('REVENUECAT_ANDROID_API_KEY not found in .env file');
    }
    return key;
  }

  /// Entitlement IDs
  static const String silverEntitlement = 'silver';
  static const String goldEntitlement = 'gold';

  /// Package identifiers (these match what you set in RevenueCat dashboard)
  static const String silverPackageId = '\$rc_monthly_silver';
  static const String goldPackageId = '\$rc_monthly_gold';

  /// Get price for a specific tier
  static double getPriceForTier(String tier) {
    switch (tier) {
      case 'silver':
        return 1.99;
      case 'gold':
        return 3.99;
      case 'free':
      default:
        return 0.00;
    }
  }

  /// Get display name for tier
  static String getDisplayNameForTier(String tier) {
    switch (tier) {
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold Premium';
      case 'free':
      default:
        return 'Free';
    }
  }
}


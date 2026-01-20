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
  static const String proEntitlement = 'PutnamApp PRO';

  /// Product identifiers from App Store Connect / RevenueCat
  static const String proMonthlyProductId = 'putnamapp_pro_monthly';
  static const String proYearlyProductId = 'PutnamApp_PRO_Yearly';

  /// Optional package identifiers (if you set them in RevenueCat offerings)
  static const String proMonthlyPackageId = '\$rc_monthly';
  static const String proYearlyPackageId = '\$rc_annual';

  /// Get price for a specific tier
  static double getPriceForTier(String tier) {
    switch (tier) {
      case 'pro':
        return 3.99;
      case 'free':
      default:
        return 0.00;
    }
  }

  /// Get display name for tier
  static String getDisplayNameForTier(String tier) {
    switch (tier) {
      case 'pro':
        return 'PRO';
      case 'free':
      default:
        return 'Free';
    }
  }
}

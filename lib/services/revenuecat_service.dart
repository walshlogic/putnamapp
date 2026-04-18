import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/revenuecat_config.dart';
import '../exceptions/app_exceptions.dart';

/// Service for managing RevenueCat purchases and subscriptions
class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  /// Initialize RevenueCat SDK
  static Future<void> initialize() async {
    try {
      debugPrint('🛒 RevenueCat: Initializing...');

      // Configure RevenueCat
      PurchasesConfiguration configuration;
      
      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(RevenueCatConfig.iosApiKey);
        debugPrint('🛒 RevenueCat: Configured for iOS');
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(RevenueCatConfig.androidApiKey);
        debugPrint('🛒 RevenueCat: Configured for Android');
      } else {
        debugPrint('⚠️  RevenueCat: Platform not supported, skipping initialization');
        return;
      }

      // Set log level for debugging
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      await Purchases.configure(configuration);
      
      debugPrint('✅ RevenueCat: Initialized successfully');
    } catch (e) {
      debugPrint('❌ RevenueCat: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Set user ID (call after login)
  Future<void> identifyUser(String userId) async {
    try {
      debugPrint('👤 RevenueCat: Identifying user: $userId');
      await Purchases.logIn(userId);
      debugPrint('✅ RevenueCat: User identified');
    } catch (e) {
      debugPrint('❌ RevenueCat: Failed to identify user: $e');
      throw AuthenticationException('Failed to identify user: $e');
    }
  }

  /// Log out user
  Future<void> logoutUser() async {
    try {
      debugPrint('👋 RevenueCat: Logging out user');
      await Purchases.logOut();
      debugPrint('✅ RevenueCat: User logged out');
    } catch (e) {
      debugPrint('❌ RevenueCat: Failed to logout: $e');
    }
  }

  /// Get available offerings (subscription packages)
  Future<Offerings> getOfferings() async {
    try {
      debugPrint('📦 RevenueCat: Fetching offerings...');
      final offerings = await Purchases.getOfferings();
      debugPrint('✅ RevenueCat: Offerings fetched');
      
      if (offerings.current == null) {
        debugPrint('⚠️  RevenueCat: No current offering found');
      } else {
        debugPrint('   Available packages: ${offerings.current!.availablePackages.length}');
      }
      
      return offerings;
    } catch (e) {
      debugPrint('❌ RevenueCat: Failed to fetch offerings: $e');
      throw DatabaseException('Failed to fetch subscription packages: $e');
    }
  }

  /// Purchase a package
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      debugPrint('💳 RevenueCat: Purchasing package: ${package.identifier}');
      debugPrint('   Price: ${package.storeProduct.priceString}');
      
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = purchaseResult.customerInfo;

      debugPrint('✅ RevenueCat: Purchase successful!');
      debugPrint('   Active entitlements: ${customerInfo.entitlements.active.keys}');

      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('❌ RevenueCat: Purchase failed with code: $errorCode');
      
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('   User cancelled purchase');
        throw AuthenticationException('Purchase cancelled');
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        debugPrint('   Payment pending');
        throw AuthenticationException('Payment is pending');
      } else {
        debugPrint('   Error: ${e.message}');
        throw AuthenticationException('Purchase failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ RevenueCat: Unexpected error: $e');
      throw AuthenticationException('Purchase failed: $e');
    }
  }

  /// Restore purchases
  Future<CustomerInfo> restorePurchases() async {
    try {
      debugPrint('🔄 RevenueCat: Restoring purchases...');
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('✅ RevenueCat: Purchases restored');
      debugPrint('   Active entitlements: ${customerInfo.entitlements.active.keys}');
      return customerInfo;
    } catch (e) {
      debugPrint('❌ RevenueCat: Failed to restore purchases: $e');
      throw DatabaseException('Failed to restore purchases: $e');
    }
  }

  /// Get customer info (subscription status)
  Future<CustomerInfo> getCustomerInfo() async {
    try {
      debugPrint('📊 RevenueCat: Getting customer info...');
      final customerInfo = await Purchases.getCustomerInfo();
      debugPrint('✅ RevenueCat: Customer info retrieved');
      debugPrint('   Active subscriptions: ${customerInfo.activeSubscriptions.length}');
      debugPrint('   Active entitlements: ${customerInfo.entitlements.active.keys}');
      return customerInfo;
    } catch (e) {
      debugPrint('❌ RevenueCat: Failed to get customer info: $e');
      throw DatabaseException('Failed to get customer info: $e');
    }
  }

  /// Check if user has specific entitlement
  bool hasEntitlement(CustomerInfo customerInfo, String entitlementId) {
    final entitlement = customerInfo.entitlements.all[entitlementId];
    final isActive = entitlement?.isActive ?? false;
    
    debugPrint('🔍 RevenueCat: Checking entitlement "$entitlementId": $isActive');
    
    return isActive;
  }

  /// Get current subscription tier from entitlements
  String getTierFromEntitlements(CustomerInfo customerInfo) {
    if (hasEntitlement(customerInfo, RevenueCatConfig.proEntitlement)) {
      return 'pro';
    }
    return 'free';
  }

  /// Open manage subscriptions (directs to App/Play Store)
  Future<void> manageSubscriptions() async {
    try {
      debugPrint('⚙️  RevenueCat: Opening manage subscriptions...');
      
      // RevenueCat SDK provides this URL
      final customerInfo = await Purchases.getCustomerInfo();
      final managementUrl = customerInfo.managementURL;
      
      if (managementUrl != null && managementUrl.isNotEmpty) {
        debugPrint('✅ RevenueCat: Management URL available: $managementUrl');
        
        // Launch the management URL
        final uri = Uri.parse(managementUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('✅ RevenueCat: Management URL opened successfully');
        } else {
          debugPrint('❌ RevenueCat: Cannot launch management URL');
          throw Exception('Cannot open subscription management page');
        }
      } else {
        debugPrint('⚠️  RevenueCat: No management URL available');
        // Fallback: Try to open App Store subscription management
        // On iOS, this is typically: https://apps.apple.com/account/subscriptions
        if (Platform.isIOS) {
          const fallbackUrl = 'https://apps.apple.com/account/subscriptions';
          final uri = Uri.parse(fallbackUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            debugPrint('✅ RevenueCat: Opened App Store subscription management');
          } else {
            throw Exception('Cannot open subscription management page');
          }
        } else {
          throw Exception('Subscription management URL not available');
        }
      }
    } catch (e) {
      debugPrint('❌ RevenueCat: Failed to open management page: $e');
      rethrow;
    }
  }
}


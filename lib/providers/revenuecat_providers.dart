import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/revenuecat_service.dart';

/// Provider for RevenueCatService instance
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService.instance;
});

/// Provider for RevenueCat customer info
final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  return await service.getCustomerInfo();
});

/// Provider for available offerings
final offeringsProvider = FutureProvider<Offerings>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  return await service.getOfferings();
});

/// Provider to check current subscription tier from RevenueCat
final revenueCatTierProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  final customerInfo = await ref.watch(customerInfoProvider.future);
  return service.getTierFromEntitlements(customerInfo);
});

/// Provider to purchase a package
final purchasePackageProvider =
    Provider<Future<CustomerInfo> Function(Package package)>((ref) {
  final service = ref.watch(revenueCatServiceProvider);
  return (Package package) async {
    final customerInfo = await service.purchasePackage(package);
    // Invalidate providers to refresh
    ref.invalidate(customerInfoProvider);
    ref.invalidate(revenueCatTierProvider);
    return customerInfo;
  };
});

/// Provider to restore purchases
final restorePurchasesProvider = Provider<Future<CustomerInfo> Function()>((ref) {
  final service = ref.watch(revenueCatServiceProvider);
  return () async {
    final customerInfo = await service.restorePurchases();
    // Invalidate providers to refresh
    ref.invalidate(customerInfoProvider);
    ref.invalidate(revenueCatTierProvider);
    return customerInfo;
  };
});

/// Provider to open manage subscriptions
final manageSubscriptionsProvider = Provider<Future<void> Function()>((ref) {
  final service = ref.watch(revenueCatServiceProvider);
  return () async {
    await service.manageSubscriptions();
  };
});


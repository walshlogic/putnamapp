import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:go_router/go_router.dart';
import '../extensions/build_context_extensions.dart';
import '../providers/auth_providers.dart';
import '../providers/revenuecat_providers.dart';
import '../config/revenuecat_config.dart';
import '../config/route_paths.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user_profile.dart'; // Import to access extension methods

class TierSelectionScreen extends ConsumerWidget {
  const TierSelectionScreen({super.key});

  static const List<String> _proFeatures = <String>[
    'NO ADS OR POP-UPS... EVER!',
    'MAKE & READ COMMENTS EVERYWHERE!',
    'CREATE YOUR OWN PROFILE & USERNAME!',
    'ALL FEATURES UNLOCKED!',
    'PRIORITY SUPPORT!',
    'ADVISORY BOARD MEMBER!',
    'ADD & EDIT YOUR BUSINESS INFO!',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final offeringsAsync = ref.watch(offeringsProvider);
    final appColors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('CHOOSE YOUR PLAN')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          final currentTier = profile.subscriptionTier;
          // Use extension methods for trial checking
          final isInTrial = profile.isInTrial;
          final remainingHours = profile.remainingTrialHours;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header
                const Text(
                  'Go PRO!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Trial Status Banner (if in trial)
                if (isInTrial && remainingHours != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.green.shade50,
                          Colors.blue.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.access_time,
                          color: Colors.green.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Free Trial Active!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                remainingHours > 24
                                    ? '${(remainingHours / 24).floor()} days remaining'
                                    : '$remainingHours hours remaining',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Subscription Tiers
                offeringsAsync.when(
                  data: (offerings) {
                    final currentOffering = offerings.current;
                    if (currentOffering == null) {
                      return _buildFallbackTiers(
                        context: context,
                        ref: ref,
                        currentTier: currentTier,
                        isInTrial: isInTrial,
                      );
                    }

                    // Find packages
                    Package? monthlyPackage;
                    Package? yearlyPackage;

                    for (final package in currentOffering.availablePackages) {
                      final packageId = package.identifier.toLowerCase();
                      final productId = package.storeProduct.identifier
                          .toLowerCase();
                      final periodText = package.storeProduct.subscriptionPeriod
                          .toString()
                          .toLowerCase();
                      final isMonthlyPeriod =
                          periodText.contains('month') ||
                          periodText.contains('p1m');
                      final isYearlyPeriod =
                          periodText.contains('year') ||
                          periodText.contains('annual') ||
                          periodText.contains('p1y') ||
                          periodText.contains('p12m');
                      if (package.identifier ==
                              RevenueCatConfig.proMonthlyPackageId ||
                          productId ==
                              RevenueCatConfig.proMonthlyProductId
                                  .toLowerCase() ||
                          packageId.contains('monthly') ||
                          packageId.contains('month') ||
                          isMonthlyPeriod) {
                        monthlyPackage ??= package;
                      } else if (package.identifier ==
                              RevenueCatConfig.proYearlyPackageId ||
                          productId ==
                              RevenueCatConfig.proYearlyProductId
                                  .toLowerCase() ||
                          packageId.contains('annual') ||
                          packageId.contains('yearly') ||
                          packageId.contains('year') ||
                          isYearlyPeriod) {
                        yearlyPackage ??= package;
                      }
                    }

                    final hasSinglePlan =
                        (monthlyPackage != null) ^ (yearlyPackage != null);

                    if (monthlyPackage != null && yearlyPackage != null) {
                      return Column(
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _buildTierCard(
                                  context: context,
                                  ref: ref,
                                  tier: 'pro_monthly',
                                  name: 'MONTHLY',
                                  price:
                                      monthlyPackage.storeProduct.priceString,
                                  badge: 'PRO',
                                  color: Colors.blue.shade300,
                                  billingPeriodLabel: '/month',
                                  isCurrentTier: currentTier == 'pro',
                                  package: monthlyPackage,
                                  isInTrial: isInTrial,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTierCard(
                                  context: context,
                                  ref: ref,
                                  tier: 'pro_yearly',
                                  name: 'YEARLY',
                                  price: yearlyPackage.storeProduct.priceString,
                                  badge: 'PRO',
                                  color: appColors.accentGoldDark,
                                  billingPeriodLabel: '/year',
                                  isCurrentTier: currentTier == 'pro',
                                  isFeatured: true,
                                  package: yearlyPackage,
                                  isInTrial: isInTrial,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBenefitsCard(context),
                        ],
                      );
                    }

                    return Column(
                      children: <Widget>[
                        if (monthlyPackage != null)
                          _buildTierCard(
                            context: context,
                            ref: ref,
                            tier: 'pro_monthly',
                            name: 'Monthly',
                            price: monthlyPackage.storeProduct.priceString,
                            badge: 'PRO',
                            color: Colors.blue.shade300,
                            billingPeriodLabel: '/month',
                            isCurrentTier:
                                hasSinglePlan && currentTier == 'pro',
                            package: monthlyPackage,
                            isInTrial: isInTrial,
                          ),
                        if (monthlyPackage != null) const SizedBox(height: 16),
                        if (yearlyPackage != null)
                          _buildTierCard(
                            context: context,
                            ref: ref,
                            tier: 'pro_yearly',
                            name: 'Yearly',
                            price: yearlyPackage.storeProduct.priceString,
                            badge: 'PRO',
                            color: appColors.accentGoldDark,
                            billingPeriodLabel: '/year',
                            isCurrentTier:
                                hasSinglePlan && currentTier == 'pro',
                            isFeatured: true,
                            package: yearlyPackage,
                            isInTrial: isInTrial,
                          ),
                        if (monthlyPackage != null || yearlyPackage != null)
                          const SizedBox(height: 16),
                        if (monthlyPackage != null || yearlyPackage != null)
                          _buildBenefitsCard(context),
                        if (yearlyPackage == null && monthlyPackage == null)
                          _buildFallbackTiers(
                            context: context,
                            ref: ref,
                            currentTier: currentTier,
                            isInTrial: isInTrial,
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) {
                    // Fallback to static tiers if offerings fail to load
                    return _buildFallbackTiers(
                      context: context,
                      ref: ref,
                      currentTier: currentTier,
                      isInTrial: isInTrial,
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Terms of Use and Privacy Policy Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => context.push(RoutePaths.termsOfUse),
                      child: const Text(
                        'Terms of Use',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => context.push(RoutePaths.privacy),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Restore Purchases button (more prominent)
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final restorePurchases = ref.read(
                        restorePurchasesProvider,
                      );
                      await restorePurchases();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Purchases restored successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      // Refresh profile to show updated subscription status
                      ref.invalidate(currentUserProfileProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to restore purchases: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Purchases'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Manage Subscriptions link
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final manageSubscriptions = ref.read(
                        manageSubscriptionsProvider,
                      );
                      await manageSubscriptions();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Unable to open subscription settings. Please go to Settings > [Your Apple ID] > Subscriptions on your device.',
                            ),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text(
                    'Manage Subscriptions',
                    style: TextStyle(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Fine print - Apple HIG compliant messaging
                const Text(
                  'Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is cancelled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading profile: $error')),
      ),
    );
  }

  Widget _buildFallbackTiers({
    required BuildContext context,
    required WidgetRef ref,
    required String currentTier,
    required bool isInTrial,
  }) {
    final appColors = context.appColors;
    return Column(
      children: <Widget>[
        // PRO Monthly (fallback - no package available)
        _buildTierCard(
          context: context,
          ref: ref,
          tier: 'pro_monthly',
          name: 'Monthly',
          price: '\$3.99',
          badge: 'PRO',
          color: Colors.blue.shade300,
          billingPeriodLabel: '/month',
          isCurrentTier: currentTier == 'pro',
          package: null,
          isInTrial: isInTrial,
        ),
        const SizedBox(height: 16),

        // PRO Yearly (fallback - no package available)
        _buildTierCard(
          context: context,
          ref: ref,
          tier: 'pro_yearly',
          name: 'Yearly',
          price: '\$19.99',
          badge: 'PRO',
          color: appColors.accentGoldDark,
          billingPeriodLabel: '/year',
          isCurrentTier: currentTier == 'pro',
          isFeatured: true,
          package: null,
          isInTrial: isInTrial,
        ),
        const SizedBox(height: 16),
        _buildBenefitsCard(context),
      ],
    );
  }

  Widget _buildTierCard({
    required BuildContext context,
    required WidgetRef ref,
    required String tier,
    required String name,
    required String price,
    required String badge,
    required Color color,
    required String billingPeriodLabel,
    bool isCurrentTier = false,
    bool isFeatured = false,
    Package? package,
    bool isInTrial = false,
  }) {
    final appColors = context.appColors;
    final primaryPurple = appColors.primaryPurple;
    final lightPurple = appColors.primaryPurple.withOpacity(0.7);
    final goldDark = appColors.accentGoldDark;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isFeatured ? goldDark : Colors.grey.shade300,
          width: isFeatured ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isCurrentTier ? Colors.green.shade50 : Colors.white,
      ),
      child: Stack(
        children: <Widget>[
          // Featured badge
          if (isFeatured)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: goldDark,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Tier name and badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                      ),
                    ),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: lightPurple,
                      ),
                    ),
                  ],
                ),
                // Price with subscription period
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Subscribe button or Current Plan
                if (isCurrentTier)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: const Text(
                      '✓ Current Plan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (isInTrial)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: const Text(
                      'Subscribe to continue after trial',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: package != null
                          ? () => _handlePurchase(context, ref, package, tier)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFeatured ? goldDark : color,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 8,
                      ),
                      child: package != null
                          ? Text(
                              isFeatured
                                  ? 'SAVE YEARLY'
                                  : 'SUBSCRIBE MONTHLY',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : const Text(
                              'Not available yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'PRO BENEFITS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: appColors.accentGoldDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ..._proFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.check_circle,
                    size: 32,
                    color: appColors.accentGoldDark,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(feature, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    Package package,
    String tier,
  ) async {
    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Purchase package
      final purchasePackage = ref.read(purchasePackageProvider);
      await purchasePackage(package);

      // Invalidate profile to refresh subscription status
      ref.invalidate(currentUserProfileProvider);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully subscribed to $tier!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthenticationException catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

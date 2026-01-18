import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../providers/revenuecat_providers.dart';
import '../config/revenuecat_config.dart';
import '../config/route_paths.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user_profile.dart'; // Import to access extension methods

class TierSelectionScreen extends ConsumerWidget {
  const TierSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final offeringsAsync = ref.watch(offeringsProvider);

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
                  'Upgrade Your Experience',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose the plan that\'s right for you',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

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
                    Package? silverPackage;
                    Package? goldPackage;

                    for (final package in currentOffering.availablePackages) {
                      if (package.identifier ==
                              RevenueCatConfig.silverPackageId ||
                          package.identifier.contains('silver')) {
                        silverPackage = package;
                      } else if (package.identifier ==
                              RevenueCatConfig.goldPackageId ||
                          package.identifier.contains('gold')) {
                        goldPackage = package;
                      }
                    }

                    return Column(
                      children: <Widget>[
                        // Silver Tier Card
                        if (silverPackage != null)
                          _buildTierCard(
                            context: context,
                            ref: ref,
                            tier: 'silver',
                            name: 'Silver',
                            price: silverPackage.storeProduct.priceString,
                            badge: '⭐',
                            color: Colors.grey.shade300,
                            features: <String>[
                              'All Standard Features',
                              'No Ads',
                              '(Still See Pop-Ups)',
                              'Message Support',
                            ],
                            isCurrentTier: currentTier == 'silver',
                            package: silverPackage,
                            isInTrial: isInTrial,
                          ),
                        if (silverPackage != null) const SizedBox(height: 16),

                        // Gold Tier Card (Featured)
                        if (goldPackage != null)
                          _buildTierCard(
                            context: context,
                            ref: ref,
                            tier: 'gold',
                            name: 'Gold Premium',
                            price: goldPackage.storeProduct.priceString,
                            badge: '⭐⭐',
                            color: Colors.amber.shade400,
                            features: <String>[
                              'NO Ads or Pop-Ups!',
                              'Comment on Arrests!',
                              'Comment Everywhere!',
                              'Add/Hide Profile Info!',
                              'All Features Unlocked!',
                              'Premium Support!',
                              'Early Access!',
                              'Surveys and Input!',
                            ],
                            isCurrentTier: currentTier == 'gold',
                            isFeatured: true,
                            package: goldPackage,
                            isInTrial: isInTrial,
                          ),
                        if (goldPackage == null && silverPackage == null)
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
    return Column(
      children: <Widget>[
        // Silver Tier Card (fallback - no package available)
        _buildTierCard(
          context: context,
          ref: ref,
          tier: 'silver',
          name: 'Silver',
          price: '\$2.99',
          badge: '⭐',
          color: Colors.grey.shade300,
          features: <String>[
            'All premium features',
            'Priority support',
            'Early access to updates',
          ],
          isCurrentTier: currentTier == 'silver',
          package: null,
          isInTrial: isInTrial,
        ),
        const SizedBox(height: 16),

        // Gold Tier Card (fallback - no package available)
        _buildTierCard(
          context: context,
          ref: ref,
          tier: 'gold',
          name: 'Gold Premium',
          price: '\$4.99',
          badge: '⭐⭐',
          color: Colors.amber.shade400,
          features: <String>[
            'All premium features',
            'Premium support',
            'Early access to new features',
            'Exclusive content',
          ],
          isCurrentTier: currentTier == 'gold',
          isFeatured: true,
          package: null,
          isInTrial: isInTrial,
        ),
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
    required List<String> features,
    bool isCurrentTier = false,
    bool isFeatured = false,
    Package? package,
    bool isInTrial = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isFeatured ? Colors.amber : Colors.grey.shade300,
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
                  color: Colors.amber,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Tier name and badge
                Row(
                  children: <Widget>[
                    Text(badge, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price with subscription period
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            '/month',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    if (package != null &&
                        package.storeProduct.subscriptionPeriod != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Auto-renewable subscription',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                        backgroundColor: isFeatured ? Colors.amber : color,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: package != null
                          ? Text(
                              'Subscribe to $name',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Text(
                              'Loading...',
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

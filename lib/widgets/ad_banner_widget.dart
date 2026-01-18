import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../services/admob_service.dart';

/// Widget that displays an ad banner based on subscription tier
/// Free: Full ads
/// Silver: Reduced ads (show less frequently)
/// Gold: No ads
class AdBannerWidget extends ConsumerWidget {
  const AdBannerWidget({super.key, this.height = 50});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        
        // Gold users: No ads!
        if (profile.isGold) {
          return const SizedBox.shrink();
        }
        
        // Silver users: Reduced ads (show smaller banner)
        if (profile.isSilver) {
          return AdMobBannerWidget(
            height: height * 0.6, // 60% of normal height
            shouldShowAd: true,
          );
        }
        
        // Free users: Full ad banner
        return AdMobBannerWidget(
          height: height,
          shouldShowAd: true,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Widget that displays an interstitial ad
/// Use this between screens or after certain actions
class InterstitialAdWidget {
  const InterstitialAdWidget._();

  /// Show an interstitial ad if user is on free tier
  /// Returns true if ad was shown, false otherwise
  static Future<bool> show(WidgetRef ref) async {
    final shouldShowAds = ref.read(shouldShowAdsProvider);

    if (!shouldShowAds) {
      return false;
    }

    // Show interstitial ad using AdMob service
    return await InterstitialAdManager.instance.showInterstitialAd();
  }

  /// Preload interstitial ad (call this early in app lifecycle)
  static void preload(WidgetRef ref) {
    final shouldShowAds = ref.read(shouldShowAdsProvider);
    if (shouldShowAds) {
      InterstitialAdManager.instance.preloadInterstitialAd();
    }
  }
}

/// Premium upgrade prompt widget
/// Shows a card prompting free users to upgrade
class PremiumUpgradePrompt extends ConsumerWidget {
  const PremiumUpgradePrompt({super.key, this.onUpgrade});

  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumUserProvider);

    // Don't show for premium users
    if (isPremium) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.star, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  'Go Ad-Free!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Upgrade to Premium for just \$1.99/month and enjoy an ad-free experience.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Upgrade Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


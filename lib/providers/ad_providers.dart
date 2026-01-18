import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../services/admob_service.dart';

/// Provider to check if ads should be shown
/// Returns true for free users, false for paid users (silver/gold)
final shouldShowAdsProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return true; // Show ads if not logged in
      // Show ads only for free tier users
      return profile.isFree;
    },
    loading: () => true, // Show ads while loading (safe default)
    error: (_, __) => true, // Show ads on error (safe default)
  );
});

/// Provider for AdMob service instance
final admobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService.instance;
});

/// Provider for interstitial ad manager instance
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  return InterstitialAdManager.instance;
});


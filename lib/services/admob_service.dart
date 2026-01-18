import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for managing Google AdMob ads
/// Handles initialization and ad lifecycle
class AdMobService {
  AdMobService._();

  static final AdMobService instance = AdMobService._();

  bool _isInitialized = false;

  /// Initialize AdMob SDK
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    try {
      debugPrint('📱 AdMob: Initializing...');

      // Get app ID from environment or use test IDs
      String? appId;

      if (Platform.isIOS) {
        // iOS App ID
        appId = 'ca-app-pub-2965747653429801~6964866156';
      } else if (Platform.isAndroid) {
        // Android App ID
        appId = 'ca-app-pub-2965747653429801~6964866156';
      }

      if (appId == null) {
        debugPrint('⚠️  AdMob: Platform not supported');
        return;
      }

      await MobileAds.instance.initialize();

      instance._isInitialized = true;
      debugPrint('✅ AdMob: Initialized successfully');
    } catch (e) {
      debugPrint('❌ AdMob: Failed to initialize: $e');
      // Don't throw - ads are not critical for app functionality
    }
  }

  /// Check if AdMob is initialized
  bool get isInitialized => _isInitialized;

  /// Get banner ad unit ID (use test ID for development)
  String getBannerAdUnitId() {
    if (Platform.isIOS) {
      // Replace with your actual iOS banner ad unit ID
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    } else if (Platform.isAndroid) {
      // Replace with your actual Android banner ad unit ID
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    }
    return '';
  }

  /// Get interstitial ad unit ID (use test ID for development)
  String getInterstitialAdUnitId() {
    if (Platform.isIOS) {
      // Replace with your actual iOS interstitial ad unit ID
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    } else if (Platform.isAndroid) {
      // Replace with your actual Android interstitial ad unit ID
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    }
    return '';
  }

  /// Get rewarded ad unit ID (optional - for rewarded ads)
  String getRewardedAdUnitId() {
    if (Platform.isIOS) {
      // Replace with your actual iOS rewarded ad unit ID
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    } else if (Platform.isAndroid) {
      // Replace with your actual Android rewarded ad unit ID
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    }
    return '';
  }
}

/// Banner ad widget that respects subscription status
class AdMobBannerWidget extends StatefulWidget {
  const AdMobBannerWidget({
    super.key,
    this.height = 50,
    this.shouldShowAd = true,
  });

  final double height;
  final bool shouldShowAd;

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldShowAd && AdMobService.instance.isInitialized) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    final adUnitId = AdMobService.instance.getBannerAdUnitId();

    if (adUnitId.isEmpty) {
      debugPrint('⚠️  AdMob: No banner ad unit ID configured');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
          debugPrint('✅ AdMob: Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ AdMob: Banner ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
        onAdOpened: (_) {
          debugPrint('📱 AdMob: Banner ad opened');
        },
        onAdClosed: (_) {
          debugPrint('📱 AdMob: Banner ad closed');
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ad if user shouldn't see ads
    if (!widget.shouldShowAd) {
      return const SizedBox.shrink();
    }

    // Don't show ad if not initialized
    if (!AdMobService.instance.isInitialized) {
      return const SizedBox.shrink();
    }

    // Show ad if loaded, otherwise show placeholder
    if (_isAdLoaded && _bannerAd != null) {
      return SizedBox(
        height: widget.height,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Show loading placeholder
    return Container(
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Interstitial ad manager
class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  /// Load an interstitial ad
  Future<void> loadInterstitialAd() async {
    if (!AdMobService.instance.isInitialized) {
      debugPrint('⚠️  AdMob: Not initialized, cannot load interstitial ad');
      return;
    }

    if (_isLoading) {
      debugPrint('⚠️  AdMob: Already loading interstitial ad');
      return;
    }

    if (_interstitialAd != null) {
      debugPrint('✅ AdMob: Interstitial ad already loaded');
      return;
    }

    _isLoading = true;
    final adUnitId = AdMobService.instance.getInterstitialAdUnitId();

    if (adUnitId.isEmpty) {
      debugPrint('⚠️  AdMob: No interstitial ad unit ID configured');
      _isLoading = false;
      return;
    }

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoading = false;
            debugPrint('✅ AdMob: Interstitial ad loaded');

            // Set full screen content callback
            _interstitialAd!
                .fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                debugPrint('📱 AdMob: Interstitial ad dismissed');
                // Load next ad
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _interstitialAd = null;
                debugPrint('❌ AdMob: Interstitial ad failed to show: $error');
                _isLoading = false;
              },
            );
          },
          onAdFailedToLoad: (error) {
            _interstitialAd = null;
            _isLoading = false;
            debugPrint('❌ AdMob: Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      debugPrint('❌ AdMob: Error loading interstitial ad: $e');
    }
  }

  /// Show interstitial ad if loaded
  /// Returns true if ad was shown, false otherwise
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('⚠️  AdMob: No interstitial ad loaded, loading now...');
      await loadInterstitialAd();
      return false;
    }

    try {
      await _interstitialAd!.show();
      debugPrint('📱 AdMob: Showing interstitial ad');
      return true;
    } catch (e) {
      debugPrint('❌ AdMob: Error showing interstitial ad: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return false;
    }
  }

  /// Preload interstitial ad (call this early in app lifecycle)
  void preloadInterstitialAd() {
    if (_interstitialAd == null && !_isLoading) {
      loadInterstitialAd();
    }
  }

  /// Dispose of current ad
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
  }
}

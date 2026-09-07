import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/subscription_service.dart';

class AdHelper {
  static String get bannerAdUnitId {
    return 'ca-app-pub-2670566453813351/7374327598';
  }

  static String get interstitialAdUnitId {
    return 'ca-app-pub-2670566453813351/2627443542';
  }

  static String get rewardedAdUnitId {
    return 'ca-app-pub-2670566453813351/4838673913';
  }

  static String get nativeAdUnitId {
    return 'ca-app-pub-2670566453813351/6991184210';
  }

  static String get appOpenAdUnitId {
    return 'ca-app-pub-2670566453813351/6762234879';
  }

  // Loaded instances
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdLoading = false;

  static AppOpenAd? _appOpenAd;
  static bool _isAppOpenAdLoading = false;
  static DateTime? _appOpenLoadTime;

  /// Load Interstitial Ad
  static void loadInterstitial({VoidCallback? onAdClosed}) {
    if (_isInterstitialAdLoading || _interstitialAd != null) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              if (onAdClosed != null) onAdClosed();
              loadInterstitial(); // Pre-load next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              if (onAdClosed != null) onAdClosed();
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  static DateTime? _lastInterstitialTime;

  /// Show Interstitial Ad if loaded
  static void showInterstitial({required VoidCallback onAdClosed}) {
    if (!SubscriptionService.instance.current.shouldShowAds) {
      onAdClosed();
      return;
    }
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      onAdClosed();
      loadInterstitial();
    }
  }

  /// Show Interstitial Ad with a 5-minute cooldown
  static void showInterstitialWithCooldown({required VoidCallback onAdClosed}) {
    if (!SubscriptionService.instance.current.shouldShowAds) {
      onAdClosed();
      return;
    }
    final now = DateTime.now();
    if (_lastInterstitialTime == null || now.difference(_lastInterstitialTime!).inMinutes >= 5) {
      if (_interstitialAd != null) {
        _lastInterstitialTime = now;
        _interstitialAd!.show();
      } else {
        onAdClosed();
        loadInterstitial();
      }
    } else {
      onAdClosed();
    }
  }


  /// Load Rewarded Ad
  static void loadRewarded({VoidCallback? onAdClosed}) {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              if (onAdClosed != null) onAdClosed();
              loadRewarded(); // Preload
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              if (onAdClosed != null) onAdClosed();
              loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Show Rewarded Ad if loaded
  static void showRewarded({
    required Function(RewardItem) onUserEarnedReward,
    required VoidCallback onAdClosed,
  }) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward(reward);
        },
      );
    } else {
      onAdClosed();
      loadRewarded();
    }
  }

  /// Load App Open Ad
  static void loadAppOpenAd() {
    if (_isAppOpenAdLoading || _appOpenAd != null) return;
    _isAppOpenAdLoading = true;
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _isAppOpenAdLoading = false;
          _appOpenAd = null;
        },
      ),
    );
  }

  static bool get isAppOpenAdAvailable {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        DateTime.now().subtract(const Duration(hours: 4)).isBefore(_appOpenLoadTime!);
  }

  /// Show App Open Ad
  static void showAppOpenAdIfAvailable() {
    if (!SubscriptionService.instance.current.shouldShowAds) {
      return;
    }
    if (!isAppOpenAdAvailable) {
      loadAppOpenAd();
      return;
    }
    
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }
}

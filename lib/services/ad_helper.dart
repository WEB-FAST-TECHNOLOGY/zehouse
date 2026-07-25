import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static String get bannerAdUnitId {
    // Test Banner Ad Unit ID
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get interstitialAdUnitId {
    // Test Interstitial Ad Unit ID
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  static String get rewardedAdUnitId {
    // Test Rewarded Ad Unit ID
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  // Loaded instances
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdLoading = false;

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

  /// Show Interstitial Ad if loaded
  static void showInterstitial({required VoidCallback onAdClosed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      onAdClosed();
      loadInterstitial();
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
}

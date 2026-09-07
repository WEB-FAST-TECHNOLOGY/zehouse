import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';

class GlobalNativeAdWidget extends StatefulWidget {
  const GlobalNativeAdWidget({super.key});

  @override
  State<GlobalNativeAdWidget> createState() => _GlobalNativeAdWidgetState();
}

class _GlobalNativeAdWidgetState extends State<GlobalNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 10.0,
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      if (kDebugMode) {
        return Container(
          constraints: const BoxConstraints(
            minWidth: 320,
            minHeight: 120,
            maxWidth: 400,
            maxHeight: 120,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Native Ad Space (Waiting for Google Fill)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 320,
        minHeight: 120,
        maxWidth: 400,
        maxHeight: 120,
      ),
      alignment: Alignment.center,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../services/ad_helper.dart';
import '../services/subscription_service.dart';
import '../services/advertiser_service.dart';
import '../routes/app_routes.dart';

class GlobalBannerAdWidget extends StatefulWidget {
  const GlobalBannerAdWidget({super.key});

  @override
  State<GlobalBannerAdWidget> createState() => _GlobalBannerAdWidgetState();
}

class _GlobalBannerAdWidgetState extends State<GlobalBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _showInternalPromo = false;

  Map<String, dynamic>? _partnerCampaign;

  @override
  void initState() {
    super.initState();
    if (SubscriptionService.instance.current.shouldShowAds) {
      _loadPartnerCampaignOrFallback();
    }
  }

  Future<void> _loadPartnerCampaignOrFallback() async {
    try {
      final campaigns = await AdvertiserService.instance.getBannerCampaigns();
      if (campaigns.isNotEmpty) {
        final selected = campaigns[Random().nextInt(campaigns.length)];
        if (mounted) {
          setState(() {
            _partnerCampaign = selected;
          });
          AdvertiserService.instance.logImpression(selected['id'].toString());
          return;
        }
      }
    } catch (_) {}

    if (Random().nextBool()) {
      setState(() {
        _showInternalPromo = true;
      });
    } else {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _showInternalPromo = true;
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SubscriptionService.instance.current.shouldShowAds) {
      return const SizedBox.shrink();
    }

    if (_partnerCampaign != null) {
      return _buildPartnerAdBanner(context, _partnerCampaign!);
    }

    if (_showInternalPromo) {
      return _buildInternalPromoBanner(context);
    }

    if (!_isLoaded || _bannerAd == null) {
      if (kDebugMode) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            height: 50,
            color: Colors.grey.withOpacity(0.2),
            alignment: Alignment.center,
            child: const Text(
              'Banner Ad Space (Waiting for Google Fill)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width,
        height: _bannerAd!.size.height.toDouble(),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }

  Widget _buildPartnerAdBanner(BuildContext context, Map<String, dynamic> campaign) {
    final title = campaign['title'] ?? 'Partenaire Zehouse';
    final targetUrl = campaign['target_url'] as String? ?? '';
    final imageUrl = campaign['image_url'] as String? ?? '';
    final advertiser = campaign['advertisers'] as Map<String, dynamic>?;
    final companyName = advertiser?['company_name'] ?? 'Partenaire Officiel';
    final tier = (advertiser?['tier'] as String?)?.toUpperCase() ?? 'PRO';

    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: () async {
          final campaignId = campaign['id']?.toString();
          if (campaignId != null) {
            AdvertiserService.instance.logClick(campaignId);
          }
          if (targetUrl.isNotEmpty) {
            final uri = Uri.parse(targetUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {
            Navigator.pushNamed(context, AppRoutes.subscriptionPlansScreen);
          }
        },
        child: Container(
          width: double.infinity,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tier == 'ULTRA'
                  ? const [Color(0xFFE11D48), Color(0xFFBE123C)]
                  : const [Color(0xFF0284C7), Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (tier == 'ULTRA' ? const Color(0xFFE11D48) : const Color(0xFF0284C7)).withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tier == 'ULTRA' ? Icons.workspace_premium_rounded : Icons.verified_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tier == 'ULTRA' ? 'ULTRA' : 'PRO',
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withAlpha(220),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Découvrir',
                  style: GoogleFonts.outfit(
                    color: tier == 'ULTRA' ? const Color(0xFFE11D48) : const Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInternalPromoBanner(BuildContext context) {
    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.subscriptionPlansScreen);
        },
        child: Container(
          width: double.infinity,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF0066CC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passez à ZEHOUSE Pro !',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Profitez de -30% (35\$ au lieu de 50\$)',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withAlpha(220),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Voir',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0066CC),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

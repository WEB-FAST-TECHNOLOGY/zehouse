import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum AdvertiserTier {
  none,
  pro,
  ultra,
}

class AdvertiserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final AdvertiserTier tier;
  final String contractStatus; // 'active', 'pending', 'expired', 'suspended'
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final String? socialLinks;

  const AdvertiserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.tier,
    required this.contractStatus,
    this.contractStart,
    this.contractEnd,
    this.socialLinks,
  });

  bool get isActive => contractStatus == 'active';

  String get tierLabel {
    switch (tier) {
      case AdvertiserTier.ultra:
        return 'Zehouse Ultra Annonceur';
      case AdvertiserTier.pro:
        return 'Zehouse Pro Annonceur';
      case AdvertiserTier.none:
        return 'Standard';
    }
  }

  factory AdvertiserProfile.fromJson(Map<String, dynamic> json) {
    final rawTier = (json['tier'] as String?)?.toLowerCase() ?? 'none';
    AdvertiserTier t = AdvertiserTier.none;
    if (rawTier == 'ultra') t = AdvertiserTier.ultra;
    if (rawTier == 'pro') t = AdvertiserTier.pro;

    return AdvertiserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['company_name'] ?? 'Annonceur',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      tier: t,
      contractStatus: json['contract_status'] ?? 'inactive',
      contractStart: json['contract_start'] != null
          ? DateTime.tryParse(json['contract_start'])
          : null,
      contractEnd: json['contract_end'] != null
          ? DateTime.tryParse(json['contract_end'])
          : null,
      socialLinks: json['social_links'],
    );
  }
}

class AdvertiserService {
  static AdvertiserService? _instance;
  static AdvertiserService get instance {
    _instance ??= AdvertiserService._();
    return _instance!;
  }

  AdvertiserService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Fetches active partner advertising campaigns for display in banners
  Future<List<Map<String, dynamic>>> getBannerCampaigns() async {
    try {
      final response = await _client
          .from('advertiser_campaigns')
          .select('*, advertisers(company_name, tier)')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final List data = response as List;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdvertiserService.getBannerCampaigns error: $e');
      return [];
    }
  }

  /// Logs an impression for a banner campaign
  Future<void> logImpression(String campaignId) async {
    try {
      final current = await _client
          .from('advertiser_campaigns')
          .select('impressions')
          .eq('id', campaignId)
          .maybeSingle();

      final currentImpressions = (current?['impressions'] as num?)?.toInt() ?? 0;
      await _client
          .from('advertiser_campaigns')
          .update({'impressions': currentImpressions + 1})
          .eq('id', campaignId);
    } catch (e) {
      debugPrint('AdvertiserService.logImpression error: $e');
    }
  }

  /// Logs a click for a banner campaign
  Future<void> logClick(String campaignId) async {
    try {
      final current = await _client
          .from('advertiser_campaigns')
          .select('clicks')
          .eq('id', campaignId)
          .maybeSingle();

      final currentClicks = (current?['clicks'] as num?)?.toInt() ?? 0;
      await _client
          .from('advertiser_campaigns')
          .update({'clicks': currentClicks + 1})
          .eq('id', campaignId);
    } catch (e) {
      debugPrint('AdvertiserService.logClick error: $e');
    }
  }

  /// Submits a partner application from mobile app user
  Future<bool> submitPartnerApplication({
    required String name,
    required String email,
    required String phone,
    required String socialChannels,
    required String proposedTier,
    required String message,
  }) async {
    try {
      final user = _client.auth.currentUser;
      await _client.from('advertiser_applications').insert({
        'user_id': user?.id,
        'name': name,
        'email': email,
        'phone': phone,
        'social_channels': socialChannels,
        'proposed_tier': proposedTier,
        'message': message,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('AdvertiserService.submitPartnerApplication error: $e');
      return false;
    }
  }

  /// Checks if current user has an advertiser profile in Supabase
  Future<AdvertiserProfile?> getCurrentUserAdvertiserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final email = user.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) return null;

      final res = await _client
          .from('advertisers')
          .select()
          .or('user_id.eq.${user.id},email.ilike.$email')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (res != null) {
        final profile = AdvertiserProfile.fromJson(res);
        // Link user_id if missing
        if (res['user_id'] == null && user.id.isNotEmpty) {
          try {
            await _client.from('advertisers').update({'user_id': user.id}).eq('id', profile.id);
          } catch (_) {}
        }
        return profile;
      }
    } catch (e) {
      debugPrint('AdvertiserService.getCurrentUserAdvertiserProfile error: $e');
    }
    return null;
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zehouse/services/supabase_service.dart';

enum SubscriptionPlan {
  none,
  plus,
  pro,
  ultra,
}

enum BillingCycle { monthly, yearly }

enum SubscriptionStatus { inactive, trial, active, expired }

class SubscriptionInfo {
  final SubscriptionPlan plan;
  final BillingCycle billingCycle;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? trialEndDate;
  final DateTime? expiryDate;
  final String? transactionId;
  final bool sponsoredListings;
  final bool hasUsedTrial;

  const SubscriptionInfo({
    required this.plan,
    this.billingCycle = BillingCycle.monthly,
    required this.status,
    this.startDate,
    this.trialEndDate,
    this.expiryDate,
    this.transactionId,
    this.sponsoredListings = false,
    this.hasUsedTrial = false,
  });

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;

  bool get isTrial => status == SubscriptionStatus.trial;

  int get daysRemaining {
    if (status == SubscriptionStatus.trial && trialEndDate != null) {
      final diff = trialEndDate!.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    }
    if (status == SubscriptionStatus.active && expiryDate != null) {
      final diff = expiryDate!.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    }
    return 0;
  }

  int get maxListings {
    switch (plan) {
      case SubscriptionPlan.ultra:
        return 999999; // Unlimited
      case SubscriptionPlan.pro:
        return 100;
      case SubscriptionPlan.plus:
        return 30;
      case SubscriptionPlan.none:
        return SubscriptionService.freeTierMaxListings; // 10
    }
  }

  bool canPublishWithoutFee(int currentListingsCount) {
    if (plan == SubscriptionPlan.none && currentListingsCount < SubscriptionService.freeTierMaxListings) return true; // Free tier
    if (isActive && currentListingsCount < maxListings) return true; // Paid or trial
    return false; // Limit reached or inactive
  }

  bool get shouldShowAds {
    if (status == SubscriptionStatus.active && plan != SubscriptionPlan.none) {
      return false; // Paid active subscription -> NO ADS
    }
    return true; // Trial, expired, inactive, or none -> SHOW ADS
  }

  String get planLabel {
    switch (plan) {
      case SubscriptionPlan.plus:
        return 'ZEHOUSE Plus+';
      case SubscriptionPlan.pro:
        return 'ZEHOUSE Pro';
      case SubscriptionPlan.ultra:
        return 'ZEHOUSE Ultra';
      case SubscriptionPlan.none:
        return 'Standard (Gratuit)';
    }
  }

  String get statusLabel {
    switch (status) {
      case SubscriptionStatus.trial:
        return 'Essai gratuit';
      case SubscriptionStatus.active:
        return 'Actif';
      case SubscriptionStatus.expired:
        return 'Expiré';
      case SubscriptionStatus.inactive:
        return 'Inactif';
    }
  }

  Map<String, dynamic> toJson() => {
    'plan': plan.name,
    'billingCycle': billingCycle.name,
    'status': status.name,
    'startDate': startDate?.toIso8601String(),
    'trialEndDate': trialEndDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'transactionId': transactionId,
    'sponsoredListings': sponsoredListings,
    'hasUsedTrial': hasUsedTrial,
  };

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.none,
      ),
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == json['billingCycle'],
        orElse: () => BillingCycle.monthly,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.inactive,
      ),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.tryParse(json['trialEndDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      transactionId: json['transactionId'],
      sponsoredListings: json['sponsoredListings'] as bool? ?? false,
      hasUsedTrial: json['hasUsedTrial'] as bool? ?? false,
    );
  }

  static SubscriptionInfo get empty => const SubscriptionInfo(
    plan: SubscriptionPlan.none,
    status: SubscriptionStatus.inactive,
    hasUsedTrial: false,
  );
}

class SubscriptionService {
  static const String _key = 'zehouse_subscription';

  /// Free tier limits for non-professional users
  static const int freeTierMaxListings = 10;
  static const int freeTierMaxFavorites = 5;

  static SubscriptionService? _instance;
  static SubscriptionService get instance {
    _instance ??= SubscriptionService._();
    return _instance!;
  }

  SubscriptionService._();

  SubscriptionInfo _current = SubscriptionInfo.empty;
  SubscriptionInfo get current => _current;

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _current = SubscriptionInfo.fromJson(json);
        _current = _checkExpiry(_current);
        
        // Sync with Supabase to prevent local clearing abuse
        try {
          final user = SupabaseService.instance.client.auth.currentUser;
          if (user != null) {
            final hasUsedTrialMetadata = user.userMetadata?['hasUsedTrial'] as bool? ?? false;
            if (hasUsedTrialMetadata && !_current.hasUsedTrial) {
              _current = SubscriptionInfo(
                plan: _current.plan,
                billingCycle: _current.billingCycle,
                status: _current.status,
                startDate: _current.startDate,
                trialEndDate: _current.trialEndDate,
                expiryDate: _current.expiryDate,
                transactionId: _current.transactionId,
                sponsoredListings: _current.sponsoredListings,
                hasUsedTrial: true,
              );
            }
          }
        } catch (_) {}

        await _save();
      } else {
        // No local data, check Supabase
        try {
          final user = SupabaseService.instance.client.auth.currentUser;
          if (user != null) {
            final hasUsedTrialMetadata = user.userMetadata?['hasUsedTrial'] as bool? ?? false;
            if (hasUsedTrialMetadata) {
              _current = SubscriptionInfo(
                plan: SubscriptionPlan.none,
                status: SubscriptionStatus.inactive,
                hasUsedTrial: true,
              );
              await _save();
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  SubscriptionInfo _checkExpiry(SubscriptionInfo info) {
    final now = DateTime.now();
    if (info.status == SubscriptionStatus.trial &&
        info.trialEndDate != null &&
        now.isAfter(info.trialEndDate!)) {
      return SubscriptionInfo(
        plan: info.plan,
        billingCycle: info.billingCycle,
        status: SubscriptionStatus.expired,
        startDate: info.startDate,
        trialEndDate: info.trialEndDate,
        expiryDate: info.expiryDate,
        transactionId: info.transactionId,
        sponsoredListings: info.sponsoredListings,
        hasUsedTrial: info.hasUsedTrial,
      );
    }
    if (info.status == SubscriptionStatus.active &&
        info.expiryDate != null &&
        now.isAfter(info.expiryDate!)) {
      return SubscriptionInfo(
        plan: info.plan,
        billingCycle: info.billingCycle,
        status: SubscriptionStatus.expired,
        startDate: info.startDate,
        trialEndDate: info.trialEndDate,
        expiryDate: info.expiryDate,
        transactionId: info.transactionId,
        sponsoredListings: info.sponsoredListings,
        hasUsedTrial: info.hasUsedTrial,
      );
    }
    return info;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_current.toJson()));
    } catch (_) {}
  }

  Future<void> activateTrial(
    SubscriptionPlan plan, {
    bool sponsored = false,
  }) async {
    final now = DateTime.now();
    _current = SubscriptionInfo(
      plan: plan,
      billingCycle: _current.billingCycle, // trial doesn't dictate cycle really, but keep current
      status: SubscriptionStatus.trial,
      startDate: now,
      trialEndDate: now.add(const Duration(days: 30)),
      expiryDate: null,
      transactionId: null,
      sponsoredListings: sponsored,
      hasUsedTrial: true,
    );
    await _save();
    
    // Persist to Supabase metadata to prevent abuse
    try {
      await SupabaseService.instance.client.auth.updateUser(
        UserAttributes(data: {'hasUsedTrial': true}),
      );
    } catch (_) {}

    _notify();
  }

  Future<void> activatePaidSubscription(
    SubscriptionPlan plan,
    String transactionId,
    BillingCycle billingCycle, {
    bool sponsored = false,
  }) async {
    final now = DateTime.now();
    final expiry = billingCycle == BillingCycle.yearly
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));

    _current = SubscriptionInfo(
      plan: plan,
      billingCycle: billingCycle,
      status: SubscriptionStatus.active,
      startDate: now,
      trialEndDate: null,
      expiryDate: expiry,
      transactionId: transactionId,
      sponsoredListings: sponsored,
      hasUsedTrial: _current.hasUsedTrial,
    );
    await _save();
    _notify();
  }

  Future<void> cancelSubscription() async {
    _current = SubscriptionInfo(
      plan: SubscriptionPlan.none,
      status: SubscriptionStatus.inactive,
      hasUsedTrial: _current.hasUsedTrial,
    );
    await _save();
    _notify();
  }

  bool canPublishListing(SubscriptionPlan requiredPlan) {
    if (!_current.isActive) return false;
    if (_current.plan == SubscriptionPlan.ultra) return true; // Ultra has all
    if (_current.plan == requiredPlan) return true;
    return false;
  }

  bool get hasActiveSponsoring =>
      _current.isActive && _current.sponsoredListings;
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionPlan {
  none,
  hotel,
  appartement,
  agent,
  architecte,
  plombier,
  electricien,
  macon,
  peintre,
  menuisier,
  carreleur,
  couvreur,
  serrurier,
  chauffagiste,
  decorateur,
  soudeur,
  charpentier,
  ferrailleur,
  professionnel,
}

enum SubscriptionStatus { inactive, trial, active, expired }

class SubscriptionInfo {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? trialEndDate;
  final DateTime? expiryDate;
  final String? transactionId;
  final bool sponsoredListings;

  const SubscriptionInfo({
    required this.plan,
    required this.status,
    this.startDate,
    this.trialEndDate,
    this.expiryDate,
    this.transactionId,
    this.sponsoredListings = false,
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

  String get planLabel {
    switch (plan) {
      case SubscriptionPlan.hotel:
        return 'Hôtel';
      case SubscriptionPlan.appartement:
        return 'Appartement Meublé';
      case SubscriptionPlan.agent:
        return 'Agent Immobilier';
      case SubscriptionPlan.architecte:
        return 'Architecte';
      case SubscriptionPlan.plombier:
        return 'Plombier';
      case SubscriptionPlan.electricien:
        return 'Électricien';
      case SubscriptionPlan.macon:
        return 'Maçon';
      case SubscriptionPlan.peintre:
        return 'Peintre';
      case SubscriptionPlan.menuisier:
        return 'Menuisier';
      case SubscriptionPlan.carreleur:
        return 'Carreleur';
      case SubscriptionPlan.couvreur:
        return 'Couvreur';
      case SubscriptionPlan.serrurier:
        return 'Serrurier';
      case SubscriptionPlan.chauffagiste:
        return 'Chauffagiste';
      case SubscriptionPlan.decorateur:
        return 'Décorateur';
      case SubscriptionPlan.soudeur:
        return 'Soudeur';
      case SubscriptionPlan.charpentier:
        return 'Charpentier';
      case SubscriptionPlan.ferrailleur:
        return 'Ferrailleur';
      case SubscriptionPlan.professionnel:
        return 'Professionnel';
      case SubscriptionPlan.none:
        return 'Aucun';
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
    'status': status.name,
    'startDate': startDate?.toIso8601String(),
    'trialEndDate': trialEndDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'transactionId': transactionId,
    'sponsoredListings': sponsoredListings,
  };

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.none,
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
    );
  }

  static SubscriptionInfo get empty => const SubscriptionInfo(
    plan: SubscriptionPlan.none,
    status: SubscriptionStatus.inactive,
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
        await _save();
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
        status: SubscriptionStatus.expired,
        startDate: info.startDate,
        trialEndDate: info.trialEndDate,
        expiryDate: info.expiryDate,
        transactionId: info.transactionId,
        sponsoredListings: info.sponsoredListings,
      );
    }
    if (info.status == SubscriptionStatus.active &&
        info.expiryDate != null &&
        now.isAfter(info.expiryDate!)) {
      return SubscriptionInfo(
        plan: info.plan,
        status: SubscriptionStatus.expired,
        startDate: info.startDate,
        trialEndDate: info.trialEndDate,
        expiryDate: info.expiryDate,
        transactionId: info.transactionId,
        sponsoredListings: info.sponsoredListings,
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
      status: SubscriptionStatus.trial,
      startDate: now,
      trialEndDate: now.add(const Duration(days: 40)),
      expiryDate: null,
      transactionId: null,
      sponsoredListings: sponsored,
    );
    await _save();
    _notify();
  }

  Future<void> activatePaidSubscription(
    SubscriptionPlan plan,
    String transactionId, {
    bool sponsored = false,
  }) async {
    final now = DateTime.now();
    _current = SubscriptionInfo(
      plan: plan,
      status: SubscriptionStatus.active,
      startDate: now,
      trialEndDate: null,
      expiryDate: now.add(const Duration(days: 365)),
      transactionId: transactionId,
      sponsoredListings: sponsored,
    );
    await _save();
    _notify();
  }

  Future<void> cancelSubscription() async {
    _current = SubscriptionInfo.empty;
    await _save();
    _notify();
  }

  bool canPublishListing(SubscriptionPlan requiredPlan) {
    if (!_current.isActive) return false;
    if (_current.plan == requiredPlan) return true;
    return false;
  }

  bool get hasActiveSponsoring =>
      _current.isActive && _current.sponsoredListings;
}

/// User profile model with subscription information
class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.appUserId,
    this.avatarUrl,
    this.isPremium = false,
    this.commentAnonymous = false,
    this.premiumExpiresAt,
    this.subscriptionTier = 'free',
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.stripeSubscriptionStatus,
    this.isAdmin = false,
    this.trialStartedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? appUserId;
  final String? avatarUrl;
  final bool isPremium;
  final bool commentAnonymous;
  final DateTime? premiumExpiresAt;
  final String subscriptionTier; // 'free', 'pro'
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? stripeSubscriptionStatus; // active, canceled, past_due, etc.
  final bool isAdmin; // Admin flag for managing directory
  final DateTime? trialStartedAt; // When user started their 48-hour trial
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Create UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      appUserId: json['app_user_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      commentAnonymous: json['comment_anonymous'] as bool? ?? false,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'] as String)
          : null,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      stripeCustomerId: json['stripe_customer_id'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      stripeSubscriptionStatus: json['stripe_subscription_status'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      trialStartedAt: json['trial_started_at'] != null
          ? DateTime.parse(json['trial_started_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert UserProfile to JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'display_name': displayName,
      'app_user_id': appUserId,
      'avatar_url': avatarUrl,
      'is_premium': isPremium,
      'comment_anonymous': commentAnonymous,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'subscription_tier': subscriptionTier,
      'stripe_customer_id': stripeCustomerId,
      'stripe_subscription_id': stripeSubscriptionId,
      'stripe_subscription_status': stripeSubscriptionStatus,
      'is_admin': isAdmin,
      'trial_started_at': trialStartedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? appUserId,
    String? avatarUrl,
    bool? isPremium,
    bool? commentAnonymous,
    DateTime? premiumExpiresAt,
    String? subscriptionTier,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    String? stripeSubscriptionStatus,
    bool? isAdmin,
    DateTime? trialStartedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      appUserId: appUserId ?? this.appUserId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPremium: isPremium ?? this.isPremium,
      commentAnonymous: commentAnonymous ?? this.commentAnonymous,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      stripeSubscriptionStatus:
          stripeSubscriptionStatus ?? this.stripeSubscriptionStatus,
      isAdmin: isAdmin ?? this.isAdmin,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if subscription is active
  bool get hasActiveStripeSubscription {
    return stripeSubscriptionStatus == 'active' ||
        stripeSubscriptionStatus == 'trialing';
  }

  /// Check if user is Silver tier or higher
  bool get isSilverOrHigher =>
      subscriptionTier == 'silver' || subscriptionTier == 'gold';

  /// Check if user is Gold tier
  bool get isGold => subscriptionTier == 'gold';

  /// Check if user is Silver tier specifically
  bool get isSilver => subscriptionTier == 'silver';

  /// Check if user is Free tier
  bool get isFree => subscriptionTier == 'free';

  /// Get user-friendly tier name
  String get tierDisplayName {
    switch (subscriptionTier) {
      case 'gold':
        return 'Gold Premium';
      case 'silver':
        return 'Silver';
      case 'free':
      default:
        return 'Free';
    }
  }

  /// Get tier badge emoji
  String get tierBadge {
    switch (subscriptionTier) {
      case 'gold':
        return '⭐⭐';
      case 'silver':
        return '⭐';
      case 'free':
      default:
        return '';
    }
  }
}

/// Extension to check subscription status
extension UserProfileExtension on UserProfile {
  /// Check if user is currently in their 48-hour trial period
  bool get isInTrial {
    if (trialStartedAt == null) return false;
    final now = DateTime.now();
    final trialEnd = trialStartedAt!.add(const Duration(hours: 48));
    return now.isBefore(trialEnd);
  }

  /// Get remaining trial time in hours
  int? get remainingTrialHours {
    if (!isInTrial) return null;
    final now = DateTime.now();
    final trialEnd = trialStartedAt!.add(const Duration(hours: 48));
    final remaining = trialEnd.difference(now);
    return remaining.inHours;
  }

  /// Check if user has active premium subscription OR is in trial
  bool get hasActivePremium {
    // Check if in trial period
    if (isInTrial) return true;

    // Check if has active subscription
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return false;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  /// Check if user should see ads (backwards compatible - no ads in trial or subscription)
  bool get shouldShowAds => !hasActivePremium;

  /// Check if user needs to subscribe (trial expired and no subscription)
  bool get needsSubscription {
    return !hasActivePremium && !isInTrial;
  }
}

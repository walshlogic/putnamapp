import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Provider for AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Provider for current auth state
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user session
final currentSessionProvider = Provider<Session?>((ref) {
  final authService = ref.watch(authServiceProvider);
  // Watch auth state to trigger rebuild - handle AsyncValue properly
  final authStateAsync = ref.watch(authStateProvider);
  
  // Get session from auth state if available, otherwise from authService
  final session = authStateAsync.when(
    data: (authState) => authState.session ?? authService.currentSession,
    loading: () => authService.currentSession, // Use current session while loading
    error: (_, __) => authService.currentSession, // Use current session on error
  );

  return session;
});

/// Provider for checking if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session != null;
});

/// Provider for current user profile
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final session = ref.watch(currentSessionProvider);

  if (session == null) {
    return null;
  }

  final userId = session.user.id;

  try {
    var profile = await authService.getUserProfile(userId);
    
    // Start trial for new users who don't have one yet (e.g., OAuth signups)
    // Only start if they don't have a trial_started_at and don't have an active subscription
    if (profile.trialStartedAt == null && !profile.hasActivePremium) {
      try {
        profile = await authService.startTrial(userId);
      } catch (e) {
        // If trial start fails, continue with existing profile
        // (might be an existing user or database issue)
        debugPrint('⚠️ Failed to start trial: $e');
      }
    }
    
    return profile;
  } catch (e) {
    // If profile doesn't exist yet (e.g., OAuth user), return null
    return null;
  }
});

/// Provider for checking if user has active premium subscription
final isPremiumUserProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.when(
    data: (profile) => profile?.hasActivePremium ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for checking if user should see ads
final shouldShowAdsProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumUserProvider);
  return !isPremium;
});

/// Provider for user subscription tier (returns 'free', 'silver', or 'gold')
final subscriptionTierProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.when(
    data: (profile) => profile?.subscriptionTier ?? 'free',
    loading: () => 'free',
    error: (_, __) => 'free',
  );
});

/// Provider for sign in action
final signInProvider =
    Provider<
      Future<UserProfile> Function({
        required String email,
        required String password,
      })
    >((ref) {
      final authService = ref.watch(authServiceProvider);
      return ({required String email, required String password}) async {
        debugPrint('🔧 signInProvider: Starting sign in process');
        final profile = await authService.signIn(
          email: email,
          password: password,
        );

        debugPrint('🔧 signInProvider: Login successful, refreshing auth state');
        // Force refresh of all auth state
        ref.invalidate(authStateProvider);
        ref.invalidate(currentSessionProvider);
        ref.invalidate(currentUserProfileProvider);
        ref.invalidate(isLoggedInProvider);

        // Give providers a moment to refresh
        await Future.delayed(const Duration(milliseconds: 100));

        debugPrint('🔧 signInProvider: Auth state refreshed');
        return profile;
      };
    });

/// Provider for sign up action
final signUpProvider =
    Provider<
      Future<UserProfile> Function({
        required String email,
        required String password,
        String? displayName,
      })
    >((ref) {
      final authService = ref.watch(authServiceProvider);
      return ({
        required String email,
        required String password,
        String? displayName,
      }) async {
        final profile = await authService.signUp(
          email: email,
          password: password,
          displayName: displayName,
        );
        // Invalidate profile to refresh
        ref.invalidate(currentUserProfileProvider);
        return profile;
      };
    });

/// Provider for sign out action
final signOutProvider = Provider<Future<void> Function()>((ref) {
  final authService = ref.watch(authServiceProvider);
  return () async {
    await authService.signOut();
    // Invalidate all auth-related providers
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(authStateProvider);
  };
});

/// Provider for Apple sign in action
final signInWithAppleProvider = Provider<Future<bool> Function()>((ref) {
  final authService = ref.watch(authServiceProvider);
  return () async {
    final result = await authService.signInWithApple();
    if (result) {
      ref.invalidate(currentUserProfileProvider);
    }
    return result;
  };
});

/// Provider for password reset action
final resetPasswordProvider = Provider<Future<void> Function(String email)>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  return (String email) async {
    await authService.resetPassword(email);
  };
});

/// Provider for updating user profile
final updateUserProfileProvider =
    Provider<
      Future<UserProfile> Function({
        String? displayName,
        String? avatarUrl,
        bool removeAvatar,
      })
    >((ref) {
      final authService = ref.watch(authServiceProvider);
      return ({
        String? displayName,
        String? avatarUrl,
        bool removeAvatar = false,
      }) async {
        final profile = await authService.updateUserProfile(
          displayName: displayName,
          avatarUrl: avatarUrl,
          removeAvatar: removeAvatar,
        );
        // Invalidate profile to refresh
        ref.invalidate(currentUserProfileProvider);
        return profile;
      };
    });

/// Provider for updating subscription status
final updateSubscriptionStatusProvider =
    Provider<
      Future<UserProfile> Function({
        required bool isPremium,
        DateTime? expiresAt,
      })
    >((ref) {
      final authService = ref.watch(authServiceProvider);
      return ({required bool isPremium, DateTime? expiresAt}) async {
        final profile = await authService.updateSubscriptionStatus(
          isPremium: isPremium,
          expiresAt: expiresAt,
        );
        // Invalidate profile to refresh
        ref.invalidate(currentUserProfileProvider);
        return profile;
      };
    });

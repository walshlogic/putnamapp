import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Service for managing authentication and user profiles
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Get current user session
  Session? get currentSession => _client.auth.currentSession;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentSession != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      debugPrint('📝 AuthService: Starting signup for $email');
      
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{
          'display_name': displayName,
        },
      );

      debugPrint('📝 AuthService: Signup response received');
      debugPrint('📝 AuthService: User ID: ${response.user?.id}');

      if (response.user == null) {
        throw AuthenticationException('Failed to create user account');
      }

      // Wait a moment for the trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('📝 AuthService: Fetching auto-created profile');

      // Fetch the profile that was auto-created by the trigger
      var profile = await getUserProfile(response.user!.id);
      
      // Start the 48-hour trial if not already started
      if (profile.trialStartedAt == null) {
        debugPrint('🎁 AuthService: Starting 48-hour trial for new user');
        profile = await startTrial(response.user!.id);
      }
      
      debugPrint('✅ AuthService: Signup successful! Profile created: ${profile.email}');

      return profile;
    } on AuthException catch (e) {
      debugPrint('❌ AuthService: AuthException during signup: ${e.message}');
      throw AuthenticationException(e.message);
    } catch (e) {
      debugPrint('❌ AuthService: Error during signup: $e');
      throw AuthenticationException('Failed to sign up: $e');
    }
  }

  /// Sign in with email and password
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 AuthService: Starting sign in for $email');
      
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('🔐 AuthService: Sign in response received');
      debugPrint('🔐 AuthService: User ID: ${response.user?.id}');
      debugPrint('🔐 AuthService: Session: ${response.session != null ? "exists" : "null"}');

      if (response.user == null) {
        debugPrint('❌ AuthService: Response user is null');
        throw AuthenticationException('Failed to sign in');
      }

      debugPrint('🔐 AuthService: Fetching user profile for ${response.user!.id}');
      
      // Fetch user profile from database
      final profile = await getUserProfile(response.user!.id);
      
      debugPrint('✅ AuthService: Sign in successful! Profile: ${profile.email}');
      return profile;
    } on AuthException catch (e) {
      debugPrint('❌ AuthService: AuthException: ${e.message}');
      throw AuthenticationException(e.message);
    } catch (e) {
      debugPrint('❌ AuthService: Unexpected error: $e');
      throw AuthenticationException('Failed to sign in: $e');
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      final bool result = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.putnamapp://login-callback',
      );

      return result;
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Failed to sign in with Google: $e');
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      final bool result = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.putnamapp://login-callback',
      );

      return result;
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Failed to sign in with Apple: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Failed to sign out: $e');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Failed to send reset email: $e');
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw AuthenticationException('Failed to update password: $e');
    }
  }

  /// Get user profile from database
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      debugPrint('📊 AuthService: Querying user_profiles for user: $userId');
      
      final Map<String, dynamic>? data = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('📊 AuthService: Query result: ${data != null ? "found" : "null"}');

      if (data == null) {
        debugPrint('❌ AuthService: User profile not found in database');
        throw NotFoundException('User profile not found');
      }

      debugPrint('✅ AuthService: Profile data retrieved: ${data['email']}');
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('❌ AuthService: Error fetching profile: $e');
      if (e is NotFoundException) rethrow;
      throw DatabaseException('Failed to fetch user profile: $e');
    }
  }

  /// Update user profile in database
  Future<UserProfile> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      if (currentUser == null) {
        throw AuthenticationException('No user logged in');
      }

      final Map<String, dynamic> updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updates['display_name'] = displayName;
      }

      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      final List<Map<String, dynamic>> data = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', currentUser!.id)
          .select();

      if (data.isEmpty) {
        throw NotFoundException('User profile not found');
      }

      return UserProfile.fromJson(data.first);
    } catch (e) {
      if (e is NotFoundException || e is AuthenticationException) rethrow;
      throw DatabaseException('Failed to update user profile: $e');
    }
  }

  /// Start the 48-hour trial for a user
  Future<UserProfile> startTrial(String userId) async {
    try {
      final now = DateTime.now();
      final Map<String, dynamic> updates = <String, dynamic>{
        'trial_started_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final List<Map<String, dynamic>> data = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select();

      if (data.isEmpty) {
        throw NotFoundException('User profile not found');
      }

      debugPrint('✅ AuthService: Trial started at ${now.toIso8601String()}');
      return UserProfile.fromJson(data.first);
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw DatabaseException('Failed to start trial: $e');
    }
  }

  /// Update user subscription status (for admin or payment processing)
  Future<UserProfile> updateSubscriptionStatus({
    required bool isPremium,
    DateTime? expiresAt,
  }) async {
    try {
      if (currentUser == null) {
        throw AuthenticationException('No user logged in');
      }

      final Map<String, dynamic> updates = <String, dynamic>{
        'is_premium': isPremium,
        'premium_expires_at': expiresAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final List<Map<String, dynamic>> data = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', currentUser!.id)
          .select();

      if (data.isEmpty) {
        throw NotFoundException('User profile not found');
      }

      return UserProfile.fromJson(data.first);
    } catch (e) {
      if (e is NotFoundException || e is AuthenticationException) rethrow;
      throw DatabaseException('Failed to update subscription status: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) {
        throw AuthenticationException('No user logged in');
      }

      // Delete user profile from database
      await _client.from('user_profiles').delete().eq('id', currentUser!.id);

      // Delete auth user (requires admin privileges or RLS policy)
      // Note: Supabase doesn't allow users to delete themselves by default
      // You'll need to implement this via Edge Function or Admin API
      await signOut();
    } catch (e) {
      throw DatabaseException('Failed to delete account: $e');
    }
  }
}


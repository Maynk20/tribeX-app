import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'supabase_service.dart';

class OtpResult {
  final bool success;
  final String? code;
  final String? message;

  OtpResult({required this.success, this.code, this.message});
}

class AuthService {
  static SupabaseClient? get _client => SupabaseService.client;

  /// Parse Supabase errors into user-friendly OtpResult messages
  static OtpResult _parseError(dynamic error, String fallback) {
    final str = error.toString().toLowerCase();

    // Rate limit
    if (str.contains('over_email_send_rate_limit') ||
        str.contains('rate limit') ||
        str.contains('429') ||
        str.contains('email rate limit')) {
      return OtpResult(
        success: false,
        code: 'RATE_LIMIT',
        message:
            'Too many requests. Please check your inbox for an existing code or wait 60 seconds.',
      );
    }

    // Expired / invalid OTP
    if (str.contains('otp_expired') ||
        str.contains('token has expired') ||
        str.contains('otp_disabled') ||
        str.contains('invalid') && str.contains('otp')) {
      return OtpResult(
        success: false,
        code: 'OTP_EXPIRED',
        message:
            'Code has expired or is invalid. Please tap Resend code to get a new one.',
      );
    }

    // User not found (sign-in mode with shouldCreateUser: false)
    if (str.contains('user not found') ||
        str.contains('signups not allowed') ||
        str.contains('otp_disabled')) {
      return OtpResult(
        success: false,
        code: 'NO_ACCOUNT',
        message: 'No account found with this email. Please Sign Up first!',
      );
    }

    // User already registered (duplicate signup)
    if (str.contains('user already registered') ||
        str.contains('already exists')) {
      return OtpResult(
        success: false,
        code: 'ACCOUNT_EXISTS',
        message: 'Account already exists! Please click Log In below.',
      );
    }

    // Network / generic
    if (str.contains('socketexception') ||
        str.contains('network') ||
        str.contains('timeout') ||
        str.contains('connection')) {
      return OtpResult(
        success: false,
        code: 'NETWORK_ERROR',
        message:
            'Network error. Please check your internet connection and try again.',
      );
    }

    // Extract message from AuthException if available
    if (error is AuthException) {
      return OtpResult(
        success: false,
        code: error.statusCode,
        message: error.message.isNotEmpty ? error.message : fallback,
      );
    }

    return OtpResult(success: false, message: fallback);
  }

  // ---------------------------------------------------------------------------
  // REQUEST OTP
  // ---------------------------------------------------------------------------

  /// Request Sign-In OTP for an existing user.
  /// Supabase Auth sends the email via the configured SMTP provider.
  static Future<OtpResult> requestSignInOtp(String email) async {
    final normalized = email.trim().toLowerCase();
    final client = _client;

    if (client == null) {
      return OtpResult(
        success: false,
        message: 'Supabase client not initialized',
      );
    }

    try {
      await client.auth.signInWithOtp(
        email: normalized,
        shouldCreateUser: false,
      );
      return OtpResult(
        success: true,
        message: 'Security code sent. Check your email inbox.',
      );
    } catch (e) {
      return _parseError(e, "Couldn't send security code. Please try again.");
    }
  }

  /// Request Sign-Up OTP for a new user.
  /// Supabase Auth creates the user and sends the OTP email.
  static Future<OtpResult> requestSignUpOtp({
    required String email,
    required String fullName,
    required String username,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();
    final trimmedName = fullName.trim();
    final client = _client;

    if (client == null) {
      return OtpResult(
        success: false,
        message: 'Supabase client not initialized',
      );
    }

    // Check if username is already taken before sending OTP
    try {
      final existing = await client
          .from('profiles')
          .select('id')
          .eq('username', normalizedUsername)
          .limit(1);
      if (existing.isNotEmpty) {
        return OtpResult(
          success: false,
          code: 'USERNAME_TAKEN',
          message: 'That username is already taken. Try another.',
        );
      }
    } catch (_) {
      // If check fails, proceed — Supabase will handle the rest
    }

    try {
      await client.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: true,
        data: {
          'full_name': trimmedName,
          'username': normalizedUsername,
        },
      );
      return OtpResult(
        success: true,
        message: 'Security code sent. Check your email inbox.',
      );
    } catch (e) {
      return _parseError(e, "Couldn't send security code. Please try again.");
    }
  }

  // ---------------------------------------------------------------------------
  // VERIFY OTP
  // ---------------------------------------------------------------------------

  /// Verify the 6-digit OTP code entered by the user.
  /// Works for both sign-in and sign-up — Supabase handles both identically.
  /// On success, Supabase Auth creates/authenticates the session automatically.
  static Future<OtpResult> verifyOtp({
    required String email,
    required String code,
  }) async {
    final normalized = email.trim().toLowerCase();
    final trimmedCode = code.trim();
    final client = _client;

    if (client == null) {
      return OtpResult(
        success: false,
        message: 'Supabase client not initialized',
      );
    }

    try {
      final res = await client.auth.verifyOTP(
        email: normalized,
        token: trimmedCode,
        type: OtpType.email,
      );

      if (res.session != null) {
        return OtpResult(success: true);
      }

      // Session is null but no exception — edge case
      return OtpResult(
        success: false,
        code: 'OTP_EXPIRED',
        message:
            'Invalid or expired code. Please tap Resend code to get a new one.',
      );
    } catch (e) {
      return _parseError(e, 'Invalid code. Please check and try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE OAUTH
  // ---------------------------------------------------------------------------

  /// Sign In with Google OAuth (unchanged — independent from Email OTP)
  static Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) return false;
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.tribex.app://callback',
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------

  /// Sign Out
  static Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // PROFILE
  // ---------------------------------------------------------------------------

  /// Fetch User Profile from DB
  static Future<UserProfile?> fetchUserProfile(String userId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res != null) {
        return UserProfile.fromJson(res);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}

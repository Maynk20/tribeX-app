import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'supabase_service.dart';

class OtpResult {
  final bool success;
  final String? code;
  final String? message;
  final String? tokenHash;

  OtpResult({required this.success, this.code, this.message, this.tokenHash});
}

class AuthService {
  static const List<String> serverBaseUrls = [
    String.fromEnvironment('SERVER_BASE_URL', defaultValue: ''),
    'http://10.0.2.2:8080', // Android emulator -> host port 8080
    'http://localhost:8080', // Web / desktop -> port 8080
    'http://10.0.2.2:3000',
    'http://localhost:3000',
  ];

  static SupabaseClient? get _client => SupabaseService.client;

  /// Parse tagged errors and rate limits cleanly
  static OtpResult _parseError(dynamic body, String fallback) {
    final str = body.toString();

    if (str.contains('over_email_send_rate_limit') ||
        str.contains('rate limit exceeded') ||
        str.contains('429')) {
      return OtpResult(
        success: false,
        code: 'RATE_LIMIT',
        message: 'Too many OTP requests. Please check your email inbox for the code or wait 60 seconds before trying again.',
      );
    }

    if (str.contains('otp_expired') ||
        str.contains('Token has expired') ||
        str.contains('invalid') ||
        str.contains('403')) {
      return OtpResult(
        success: false,
        code: 'OTP_EXPIRED',
        message: 'Security code has expired or is invalid. Please tap Resend code to get a new code.',
      );
    }

    if (body is Map<String, dynamic>) {
      final code = body['code'] as String?;
      final msg = body['message'] as String? ?? fallback;

      if (msg.startsWith('ACCOUNT_EXISTS:')) {
        return OtpResult(
          success: false,
          code: 'ACCOUNT_EXISTS',
          message: 'Account already exists! Please click Log In below.',
        );
      }
      if (msg.startsWith('NO_ACCOUNT:')) {
        return OtpResult(
          success: false,
          code: 'NO_ACCOUNT',
          message: 'No account found with this email. Please Sign Up first!',
        );
      }
      if (msg.startsWith('USERNAME_TAKEN:')) {
        return OtpResult(
          success: false,
          code: 'USERNAME_TAKEN',
          message: msg.replaceFirst('USERNAME_TAKEN:', ''),
        );
      }

      return OtpResult(success: false, code: code, message: msg);
    }

    if (str.startsWith('ACCOUNT_EXISTS:')) {
      return OtpResult(
        success: false,
        code: 'ACCOUNT_EXISTS',
        message: 'Account already exists! Please click Log In below.',
      );
    }
    if (str.startsWith('NO_ACCOUNT:')) {
      return OtpResult(
        success: false,
        code: 'NO_ACCOUNT',
        message: 'No account found with this email. Please Sign Up first!',
      );
    }
    if (str.startsWith('USERNAME_TAKEN:')) {
      return OtpResult(
        success: false,
        code: 'USERNAME_TAKEN',
        message: str.replaceFirst('USERNAME_TAKEN:', ''),
      );
    }

    return OtpResult(success: false, message: str.isEmpty ? fallback : str);
  }

  /// Helper to post to custom server OTP endpoints trying available URLs
  static Future<http.Response?> _postToApi(
    String path,
    Map<String, dynamic> payload,
  ) async {
    for (final baseUrl in serverBaseUrls) {
      if (baseUrl.isEmpty) continue;
      try {
        final uri = Uri.parse('$baseUrl$path');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || response.statusCode == 400) {
          return response;
        }
      } catch (_) {
        // try next URL
      }
    }
    return null;
  }

  /// Request Sign In OTP (6-digit code email via server function)
  static Future<OtpResult> requestSignInOtp(String email) async {
    final normalized = email.trim().toLowerCase();

    final response = await _postToApi('/api/otp/request', {
      'mode': 'signin',
      'email': normalized,
    });

    if (response != null) {
      try {
        final body = jsonDecode(response.body);
        if (response.statusCode == 200 && (body['success'] == true)) {
          return OtpResult(
            success: true,
            message: body['message'] ?? 'Security code sent.',
          );
        } else {
          return _parseError(
            body,
            "Couldn't send security code. Please try again.",
          );
        }
      } catch (_) {}
    }

    // Fallback to Supabase Auth
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
      return _parseError(e.toString(), "Couldn't send security code.");
    }
  }

  /// Request Sign Up OTP (6-digit code email via server function)
  static Future<OtpResult> requestSignUpOtp({
    required String email,
    required String fullName,
    required String username,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();
    final trimmedName = fullName.trim();

    final response = await _postToApi('/api/otp/request', {
      'mode': 'signup',
      'email': normalizedEmail,
      'full_name': trimmedName,
      'username': normalizedUsername,
    });

    if (response != null) {
      try {
        final body = jsonDecode(response.body);
        if (response.statusCode == 200 && (body['success'] == true)) {
          return OtpResult(
            success: true,
            message: body['message'] ?? 'Security code sent.',
          );
        } else {
          return _parseError(
            body,
            "Couldn't send security code. Please try again.",
          );
        }
      } catch (_) {}
    }

    // Fallback to Supabase Auth
    final client = _client;
    if (client == null) {
      return OtpResult(
        success: false,
        message: 'Supabase client not initialized',
      );
    }

    try {
      await client.auth.signInWithOtp(
        email: normalizedEmail,
        data: {'full_name': trimmedName, 'username': normalizedUsername},
      );
      return OtpResult(
        success: true,
        message: 'Security code sent. Check your email inbox.',
      );
    } catch (e) {
      return _parseError(e.toString(), "Couldn't send security code.");
    }
  }

  /// Verify Sign In OTP
  static Future<OtpResult> verifySignInOtp({
    required String email,
    required String code,
  }) async {
    final normalized = email.trim().toLowerCase();
    final client = _client;

    final response = await _postToApi('/api/otp/verify', {
      'mode': 'signin',
      'email': normalized,
      'code': code.trim(),
    });

    if (response != null) {
      try {
        final body = jsonDecode(response.body);
        if (response.statusCode == 200) {
          final tokenHash = body['token_hash'] as String?;
          final emailOtp = body['email_otp'] as String?;

          if (client != null) {
            if (tokenHash != null) {
              try {
                final authRes = await client.auth.verifyOTP(
                  email: normalized,
                  token: tokenHash,
                  type: OtpType.magiclink,
                );
                if (authRes.session != null) {
                  return OtpResult(success: true, tokenHash: tokenHash);
                }
              } catch (_) {}
            }

            if (emailOtp != null) {
              try {
                final authRes2 = await client.auth.verifyOTP(
                  email: normalized,
                  token: emailOtp,
                  type: OtpType.email,
                );
                if (authRes2.session != null) {
                  return OtpResult(success: true, tokenHash: emailOtp);
                }
              } catch (_) {}
            }

            return OtpResult(
              success: false,
              code: 'OTP_EXPIRED',
              message: 'Security code expired or session failed. Please request a new code.',
            );
          }
        } else {
          return _parseError(body, "Invalid code. Please try again.");
        }
      } catch (err) {
        return _parseError(err, "Verification failed. Please try again.");
      }
    }

    // Fallback to Supabase Auth
    if (client == null) {
      return OtpResult(
        success: false,
        message: 'Supabase client not initialized',
      );
    }

    try {
      final res = await client.auth.verifyOTP(
        email: normalized,
        token: code.trim(),
        type: OtpType.email,
      );
      if (res.session != null) {
        return OtpResult(success: true);
      }
      final res2 = await client.auth.verifyOTP(
        email: normalized,
        token: code.trim(),
        type: OtpType.magiclink,
      );
      if (res2.session != null) {
        return OtpResult(success: true);
      }
      return OtpResult(
        success: false,
        code: 'OTP_EXPIRED',
        message: 'Invalid or expired OTP code',
      );
    } catch (e) {
      return _parseError(e.toString(), 'Invalid code. Please try again.');
    }
  }

  /// Verify Sign Up OTP
  static Future<OtpResult> verifySignUpOtp({
    required String email,
    required String code,
    required String fullName,
    required String username,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();
    final trimmedName = fullName.trim();
    final client = _client;

    final response = await _postToApi('/api/otp/verify', {
      'mode': 'signup',
      'email': normalizedEmail,
      'code': code.trim(),
      'full_name': trimmedName,
      'username': normalizedUsername,
    });

    if (response != null) {
      try {
        final body = jsonDecode(response.body);
        if (response.statusCode == 200) {
          final tokenHash = body['token_hash'] as String?;
          final emailOtp = body['email_otp'] as String?;

          if (client != null) {
            if (tokenHash != null) {
              try {
                final authRes = await client.auth.verifyOTP(
                  email: normalizedEmail,
                  token: tokenHash,
                  type: OtpType.magiclink,
                );
                if (authRes.session != null) {
                  return OtpResult(success: true, tokenHash: tokenHash);
                }
              } catch (_) {}
            }

            if (emailOtp != null) {
              try {
                final authRes2 = await client.auth.verifyOTP(
                  email: normalizedEmail,
                  token: emailOtp,
                  type: OtpType.email,
                );
                if (authRes2.session != null) {
                  return OtpResult(success: true, tokenHash: emailOtp);
                }
              } catch (_) {}
            }

            return OtpResult(
              success: false,
              code: 'OTP_EXPIRED',
              message: 'Security code expired or session failed. Please request a new code.',
            );
          }
        } else {
          return _parseError(body, "Invalid code. Please try again.");
        }
      } catch (err) {
        return _parseError(err, "Verification failed. Please try again.");
      }
    }

    return verifySignInOtp(email: normalizedEmail, code: code);
  }

  /// Sign In with Google OAuth
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

  /// Sign Out
  static Future<void> signOut() async {
    await _client?.auth.signOut();
  }

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

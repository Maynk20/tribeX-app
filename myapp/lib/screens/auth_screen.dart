import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_toast.dart';
import '../services/auth_service.dart';
import '../widgets/common/google_g_logo.dart';
import 'terms_and_policies_screen.dart';

enum AuthMode { signup, login }

enum AuthStep { email, code }

class AuthNotice {
  final String kind; // 'account_exists' | 'no_account' | 'info'
  final String message;

  AuthNotice({required this.kind, required this.message});
}

class AuthScreen extends StatefulWidget {
  final AuthMode defaultMode;

  const AuthScreen({super.key, this.defaultMode = AuthMode.signup});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode;
  AuthStep _step = AuthStep.email;

  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _unameCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _isBusy = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  AuthNotice? _notice;

  final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final _usernameRegex = RegExp(r'^[a-z0-9_]{3,24}$');

  @override
  void initState() {
    super.initState();
    _mode = widget.defaultMode;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _unameCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  void _resetTransient() {
    setState(() {
      _step = AuthStep.email;
      _otpCtrl.clear();
      _isBusy = false;
      _cooldown = 0;
      _notice = null;
    });
    _cooldownTimer?.cancel();
  }

  void _switchMode(AuthMode next) {
    setState(() {
      _mode = next;
      _resetTransient();
    });
  }

  void _onEmailChanged(String text) {
    if (_step != AuthStep.email ||
        _otpCtrl.text.isNotEmpty ||
        _notice != null) {
      setState(() {
        _step = AuthStep.email;
        _otpCtrl.clear();
        _cooldown = 0;
        _notice = null;
      });
      _cooldownTimer?.cancel();
    }
  }

  void _sendCode({bool isResend = false}) async {
    if (_isBusy) return;

    final trimmedEmail = _emailCtrl.text.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      _showToast('Please enter your email address');
      return;
    }
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      _showToast('Please enter a valid email address (e.g. name@example.com)');
      return;
    }

    final trimmedName = _nameCtrl.text.trim();
    final trimmedUsername = _unameCtrl.text.trim().toLowerCase();

    if (_mode == AuthMode.signup) {
      if (trimmedName.isEmpty) {
        _showToast('Please enter your full name');
        return;
      }
      if (trimmedName.length < 2) {
        _showToast('Enter your full name (at least 2 characters)');
        return;
      }
      if (trimmedUsername.isEmpty) {
        _showToast('Please choose a username');
        return;
      }
      if (!_usernameRegex.hasMatch(trimmedUsername)) {
        _showToast(
          'Username: 3–24 chars, lowercase letters, numbers or underscores',
        );
        return;
      }
    }

    if (_cooldown > 0 && isResend) return;

    setState(() {
      _isBusy = true;
      _notice = null;
    });

    final res = _mode == AuthMode.signup
        ? await AuthService.requestSignUpOtp(
            email: trimmedEmail,
            fullName: trimmedName,
            username: trimmedUsername,
          )
        : await AuthService.requestSignInOtp(trimmedEmail);

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (!res.success) {
      final code = res.code;
      final msg =
          res.message ?? "Couldn't send security code. Please try again.";

      if (code == 'ACCOUNT_EXISTS') {
        _showToast('Account already exists! Please Log In.');
        setState(() {
          _mode = AuthMode.login;
          _step = AuthStep.email;
          _otpCtrl.clear();
          _notice = AuthNotice(
            kind: 'account_exists',
            message: 'Account already exists — please log in.',
          );
        });
        return;
      }

      if (code == 'NO_ACCOUNT') {
        _showToast('No account found with this email. Please Sign Up first!');
        setState(() {
          _mode = AuthMode.signup;
          _step = AuthStep.email;
          _otpCtrl.clear();
          _notice = AuthNotice(
            kind: 'no_account',
            message: 'No account found — create one to continue.',
          );
        });
        return;
      }

      if (code == 'USERNAME_TAKEN') {
        setState(() {
          _notice = AuthNotice(kind: 'info', message: msg);
        });
        _showToast(msg);
        return;
      }

      _showToast(msg);
      return;
    }

    _showToast(
      isResend
          ? 'New code sent. Check your inbox and spam folder.'
          : 'Security code sent. Check your inbox and spam folder.',
    );

    setState(() {
      _step = AuthStep.code;
      _otpCtrl.clear();
    });
    _startCooldown(60);
  }

  void _verifyCode() async {
    if (_isBusy) return;

    final code = _otpCtrl.text.trim();
    if (code.isEmpty) {
      _showToast('Please enter the 6-digit code sent to your email.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showToast('Code must be exactly 6 digits.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isBusy = true);

    final trimmedEmail = _emailCtrl.text.trim().toLowerCase();

    final res = await AuthService.verifyOtp(
      email: trimmedEmail,
      code: code,
    );

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (res.success) {
      _showToast(
        _mode == AuthMode.signup ? 'Welcome to tribeX!' : "You're signed in!",
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } else {
      final msg = res.message ?? "Couldn't verify code. Please try again.";
      if (res.code == 'OTP_EXPIRED') {
        _showToast('Code expired or invalid. Please tap Resend code.');
      } else {
        _showToast(msg);
      }
    }
  }

  void _googleAuth() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final success = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (success) {
      _showToast("You're signed in!");
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } else {
      _showToast('Google Sign-In failed or cancelled.');
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    AppToast.show(
      context,
      msg,
      isError: isError,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching TanStack auth.tsx
              Text(
                'GET STARTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  children: const [
                    TextSpan(text: 'Join '),
                    TextSpan(
                      text: 'tribe',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(text: 'X'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Passwordless — we'll email you a one-time code.",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 20),

              // Google Auth Button
              GestureDetector(
                onTap: _isBusy ? null : _googleAuth,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleGLogo(size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: border.withValues(alpha: 0.6)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: border.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Mode Pill Switch (Sign up / Log in)
              Container(
                height: 38,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchMode(AuthMode.signup),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _mode == AuthMode.signup
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _mode == AuthMode.signup
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForegroundLight),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchMode(AuthMode.login),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _mode == AuthMode.login
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _mode == AuthMode.login
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForegroundLight),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // STEP 1: EMAIL & USER DETAILS FORM
              if (_step == AuthStep.email) ...[
                if (_mode == AuthMode.signup) ...[
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(LucideIcons.user, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: _emailCtrl,
                  onChanged: _onEmailChanged,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(LucideIcons.mail, size: 18),
                  ),
                ),

                if (_mode == AuthMode.signup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _unameCtrl,
                    onChanged: (val) {
                      final formatted = val.toLowerCase().replaceAll(
                        RegExp(r'[^a-z0-9_]'),
                        '',
                      );
                      if (formatted != val) {
                        _unameCtrl.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'lowercase, numbers or _',
                      prefixIcon: Icon(LucideIcons.atSign, size: 18),
                    ),
                  ),
                ],

                // Notice Banner (Account Exists / No Account / Username Taken)
                if (_notice != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _notice!.kind == 'account_exists' ||
                              _notice!.kind == 'no_account'
                          ? Colors.red.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _notice!.kind == 'account_exists' ||
                                _notice!.kind == 'no_account'
                            ? Colors.red.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_notice!.kind == 'account_exists' ||
                            _notice!.kind == 'no_account')
                          const Icon(
                            LucideIcons.alertTriangle,
                            size: 18,
                            color: Colors.red,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _notice!.message,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  _notice!.kind == 'account_exists' ||
                                      _notice!.kind == 'no_account'
                                  ? Colors.red
                                  : (isDark
                                        ? AppColors.foregroundDark
                                        : AppColors.foregroundLight),
                            ),
                          ),
                        ),
                        if (_notice!.kind == 'account_exists')
                          TextButton(
                            onPressed: () => _switchMode(AuthMode.login),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Log In instead',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (_notice!.kind == 'no_account')
                          TextButton(
                            onPressed: () => _switchMode(AuthMode.signup),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Sign Up instead',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : () => _sendCode(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isBusy
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Sending…'),
                            ],
                          )
                        : Text(
                            _mode == AuthMode.signup
                                ? 'Sign Up & Get OTP'
                                : 'Log In with OTP',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _mode == AuthMode.signup
                            ? 'Already have an account? '
                            : 'New to tribeX? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _switchMode(
                          _mode == AuthMode.signup
                              ? AuthMode.login
                              : AuthMode.signup,
                        ),
                        child: Text(
                          _mode == AuthMode.signup
                              ? 'Log In'
                              : 'Create an Account',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              // STEP 2: 6-DIGIT OTP VERIFICATION FORM
              else ...[
                GestureDetector(
                  onTap: _resetTransient,
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.arrowLeft,
                        size: 14,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Change email',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Code sent to ${_emailCtrl.text.trim()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6-Digit OTP Text Input with letter spacing, auto-focus & auto-submit
                TextField(
                  controller: _otpCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: TextStyle(
                      letterSpacing: 10,
                      color: isDark
                          ? AppColors.mutedForegroundDark.withValues(alpha: 0.4)
                          : AppColors.mutedForegroundLight.withValues(
                              alpha: 0.4,
                            ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (val) {
                    final formatted = val.replaceAll(RegExp(r'\D'), '');
                    if (formatted != val) {
                      _otpCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                    if (formatted.length == 6 && !_isBusy) {
                      FocusScope.of(context).unfocus();
                      _verifyCode();
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isBusy
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Verifying…'),
                            ],
                          )
                        : const Text(
                            'Verify & Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Resend code button with 60s cooldown timer
                Center(
                  child: TextButton(
                    onPressed: (_isBusy || _cooldown > 0)
                        ? null
                        : () => _sendCode(isResend: true),
                    child: Text(
                      _cooldown > 0
                          ? 'Resend code in ${_cooldown}s'
                          : 'Resend code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _cooldown > 0
                            ? (isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Terms notice
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsAndPoliciesScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                      children: const [
                        TextSpan(text: 'By continuing you agree to our '),
                        TextSpan(
                          text: 'Terms & Privacy Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

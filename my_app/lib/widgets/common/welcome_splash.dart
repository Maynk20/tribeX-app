import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';

class WelcomeSplash extends StatefulWidget {
  final UserProfile? profile;
  final VoidCallback onComplete;

  const WelcomeSplash({super.key, this.profile, required this.onComplete});

  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = widget.profile?.fullName ?? widget.profile?.username;

    return GestureDetector(
      onTap: widget.onComplete,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: Stack(
          children: [
            // Background Radial Glow
            Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Content
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Animated Logo Container
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color:
                                (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight)
                                    .withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.explore,
                              size: 54,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Text
                      Text(
                        'WELCOME TO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      const SizedBox(height: 6),

                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          children: const [
                            TextSpan(
                              text: 'tribe',
                              style: TextStyle(color: AppColors.primary),
                            ),
                            TextSpan(text: 'X'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (displayName != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Welcome back, ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '!',
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
                      ] else ...[
                        Text(
                          'Find your crew, join the plan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Tap anywhere indicator
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'TAP ANYWHERE TO ENTER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color:
                        (isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight)
                            .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

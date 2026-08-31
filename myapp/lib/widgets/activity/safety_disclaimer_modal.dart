import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SafetyDisclaimerModal extends StatefulWidget {
  final VoidCallback onAgree;

  const SafetyDisclaimerModal({super.key, required this.onAgree});

  static void show(BuildContext context, {required VoidCallback onAgree}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SafetyDisclaimerModal(onAgree: onAgree),
    );
  }

  @override
  State<SafetyDisclaimerModal> createState() => _SafetyDisclaimerModalState();
}

class _SafetyDisclaimerModalState extends State<SafetyDisclaimerModal> {
  int _secondsLeft = 6;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final ready = _secondsLeft == 0;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.destructiveMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.gpp_maybe,
                color: AppColors.destructive,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Safety Warning',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            // Description
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                children: [
                  const TextSpan(
                    text: 'You are joining this activity at your own personal risk. By proceeding, you confirm that you are ',
                  ),
                  TextSpan(
                    text: '18+ years old',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight,
                    ),
                  ),
                  const TextSpan(
                    text: ' and assume full personal responsibility for your safety and conduct.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notice Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.mutedLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Text(
                'Please read the warning carefully. The button will unlock in a few seconds.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: ready
                      ? () {
                          Navigator.of(context).pop();
                          widget.onAgree();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.destructive.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  child: Text(
                    ready
                        ? 'I Understand & Proceed'
                        : 'Proceeding in ${_secondsLeft}s…',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

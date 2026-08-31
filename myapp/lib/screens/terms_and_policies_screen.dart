import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class TermsAndPoliciesScreen extends StatelessWidget {
  const TermsAndPoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Policies',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'tribeX Community Guidelines & Legal Terms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Last updated: October 2025',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 20),

            _SectionCard(
              cardBg: cardBg,
              border: border,
              title: '1. Community Safety & Code of Conduct',
              content: 'tribeX is a platform to discover local leisure and sports activities with real people. Treat everyone with respect, punctuality, and sportsmanship. Harassment, discrimination, fraud, or unsafe behavior will lead to permanent account suspension.',
            ),
            const SizedBox(height: 12),

            _SectionCard(
              cardBg: cardBg,
              border: border,
              title: '2. Plan Hosting & Attendance',
              content: 'Hosts are responsible for coordinating venue arrangements, setting realistic participant limits, and reviewing join requests. Attendees must check in via GPS upon arrival. Unnotified no-shows degrade your public Reliability Score.',
            ),
            const SizedBox(height: 12),

            _SectionCard(
              cardBg: cardBg,
              border: border,
              title: '3. Expense Splitting & Direct UPI Payments',
              content: 'tribeX does not process or hold payments. Expense splitting cards calculate per-head costs and provide direct UPI links for peer-to-peer settlement. tribeX is not responsible for disputes arising from offline financial settlements.',
            ),
            const SizedBox(height: 12),

            _SectionCard(
              cardBg: cardBg,
              border: border,
              title: '4. Privacy & Location Data',
              content: 'Your precise GPS location is only used to compute approximate proximity and verify venue check-ins. Exact venue locations for restricted plans remain shielded from unauthorized users until approved by the host.',
            ),
            const SizedBox(height: 12),

            _SectionCard(
              cardBg: cardBg,
              border: border,
              title: '5. Personal Responsibility & Disclaimer',
              content: 'All activities are undertaken at your own risk. tribeX does not provide insurance or physical safety guarantees for in-person sports, events, or gatherings.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color cardBg;
  final Color border;
  final String title;
  final String content;

  const _SectionCard({
    required this.cardBg,
    required this.border,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ],
      ),
    );
  }
}

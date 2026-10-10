import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';

class TermsAndPoliciesScreen extends StatefulWidget {
  const TermsAndPoliciesScreen({super.key});

  @override
  State<TermsAndPoliciesScreen> createState() => _TermsAndPoliciesScreenState();
}

class _TermsAndPoliciesScreenState extends State<TermsAndPoliciesScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = List.generate(5, (_) => GlobalKey());

  static const List<String> _sectionTitles = [
    'Community Safety',
    'Plan Hosting',
    'Expense Splitting',
    'Privacy & Location',
    'Disclaimer',
  ];

  void _scrollToSection(int index) {
    final context = _sectionKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Policies',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'tribeX Community Guidelines & Legal Terms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              'Version 1.0 · Effective: October 2026',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 16),

            // Quick Jump Table of Contents Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_sectionTitles.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        _sectionTitles[index],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      onPressed: () => _scrollToSection(index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            _SectionCard(
              key: _sectionKeys[0],
              cardBg: cardBg,
              border: border,
              title: '1. Community Safety & Code of Conduct',
              content:
                  'tribeX is a platform to discover local leisure and sports activities with real people. Treat everyone with respect, punctuality, and sportsmanship. Harassment, discrimination, fraud, or unsafe behavior will lead to permanent account suspension.',
            ),
            const SizedBox(height: 12),

            _SectionCard(
              key: _sectionKeys[1],
              cardBg: cardBg,
              border: border,
              title: '2. Plan Hosting & Attendance',
              content:
                  'Hosts are responsible for coordinating venue arrangements, setting realistic participant limits, and reviewing join requests. Attendees must check in upon arrival. Unnotified no-shows degrade your public reliability score.',
            ),
            const SizedBox(height: 12),

            _SectionCard(
              key: _sectionKeys[2],
              cardBg: cardBg,
              border: border,
              title: '3. Expense Splitting & Direct UPI Payments',
              content:
                  'tribeX does not process or hold payments. Expense splitting cards calculate per-head costs and provide direct UPI links for peer-to-peer settlement. tribeX is not responsible for disputes arising from offline financial settlements.',
            ),
            const SizedBox(height: 12),

            _SectionCard(
              key: _sectionKeys[3],
              cardBg: cardBg,
              border: border,
              title: '4. Privacy & Location Data',
              content:
                  'Your precise GPS location is only used to compute approximate proximity and verify venue check-ins. Exact venue locations for restricted plans remain shielded from unauthorized users until approved by the host.',
            ),
            const SizedBox(height: 12),

            _SectionCard(
              key: _sectionKeys[4],
              cardBg: cardBg,
              border: border,
              title: '5. Personal Responsibility & Disclaimer',
              content:
                  'All activities are undertaken at your own risk. tribeX does not provide insurance or physical safety guarantees for in-person sports, events, or gatherings.',
            ),
            const SizedBox(height: 32),
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
    super.key,
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            ),
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

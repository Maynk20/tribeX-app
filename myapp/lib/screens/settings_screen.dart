import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/user_profile.dart';
import '../state/auth_state.dart';
import 'terms_and_policies_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _openFaqIndex;

  static const List<Map<String, String>> faqs = [
    {
      "q": "How do join requests work?",
      "a": "When you tap Request to Join on a plan, the host receives a notification. Once approved by the host, the exact meeting coordinates unlock and you are added to the squad chat.",
    },
    {
      "q": "Is tribeX free to use?",
      "a": "Yes! Discovering plans, hosting activities, and squad chats are 100% free. Any event costs (e.g. turf rental or cafe bill) are settled directly between squad members.",
    },
    {
      "q": "What is the Safety Shield?",
      "a": "Safety Shield hides the exact venue coordinates on public feeds for restricted plans (such as Women-Only or Verified-Only activities) until the host approves your request.",
    },
    {
      "q": "How is Reliability Score calculated?",
      "a": "Your Reliability Score increases when you attend plans and complete venue GPS check-ins on time. Missing events without notice or being marked as a no-show lowers it.",
    },
  ];

  void _openEditProfileModal(BuildContext context, UserProfile user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final unameCtrl = TextEditingController(text: user.username);
    final phoneCtrl = TextEditingController(text: user.phone ?? "");
    final cityCtrl = TextEditingController(text: user.city ?? "");
    final bioCtrl = TextEditingController(text: user.bio ?? "");
    String gender = user.gender ?? "Prefer not to say";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: border),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight)
                                  .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.alternate_email, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          [
                            "Male",
                            "Female",
                            "Other",
                            "Prefer not to say",
                          ].contains(gender)
                          ? gender
                          : "Prefer not to say",
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.transgender, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(
                          value: "Female",
                          child: Text("Female"),
                        ),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                        DropdownMenuItem(
                          value: "Prefer not to say",
                          child: Text("Prefer not to say"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => gender = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City / Neighborhood',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AuthState>().updateProfile(
                            fullName: nameCtrl.text.trim(),
                            username: unameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isNotEmpty
                                ? phoneCtrl.text.trim()
                                : null,
                            gender: gender,
                            city: cityCtrl.text.trim().isNotEmpty
                                ? cityCtrl.text.trim()
                                : null,
                            bio: bioCtrl.text.trim().isNotEmpty
                                ? bioCtrl.text.trim()
                                : null,
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile details updated'),
                            ),
                          );
                        },
                        child: const Text('Save Details'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReportIssueModal(BuildContext context) {
    final textCtrl = TextEditingController();
    String category = "Safety & Conduct";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: border),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report an Issue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Issue Category',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Safety & Conduct",
                        child: Text("Safety & Conduct"),
                      ),
                      DropdownMenuItem(
                        value: "Bug or Technical Glitch",
                        child: Text("Bug or Technical Glitch"),
                      ),
                      DropdownMenuItem(
                        value: "Inappropriate Plan",
                        child: Text("Inappropriate Plan"),
                      ),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => category = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe what happened in detail…',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Report submitted. Our safety team will review it.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFeedbackModal(BuildContext context) {
    int rating = 5;
    final textCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: border),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send App Feedback',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (idx) {
                      final val = idx + 1;
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          size: 32,
                          color: val <= rating
                              ? AppColors.warning
                              : AppColors.mutedForegroundLight,
                        ),
                        onPressed: () => setModalState(() => rating = val),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'What can we improve about tribeX?',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for your feedback!'),
                          ),
                        );
                      },
                      child: const Text('Send Feedback'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Account?',
          style: TextStyle(
            color: AppColors.destructive,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your hosted plans, ratings, and profile data will be permanently deleted.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'Type "DELETE" below to confirm:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(hintText: 'DELETE'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmCtrl.text.trim() == "DELETE") {
                context.read<AuthState>().signOut();
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted')),
                );
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please type DELETE to confirm'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final user = authState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            if (user != null) ...[
              Text(
                'ACCOUNT & PROFILE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.fullName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '@${user.username} · ${user.city ?? "No city set"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      trailing: OutlinedButton(
                        onPressed: () => _openEditProfileModal(context, user),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Preferences
            Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile.adaptive(
                value: authState.pushEnabled,
                activeTrackColor: AppColors.primary,
                title: const Text(
                  'Push Notifications',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Get alerted for join requests and squad messages.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                onChanged: (val) {
                  authState.togglePush(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val
                            ? 'Push notifications enabled'
                            : 'Push notifications disabled',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // FAQs & Support
            Text(
              'HELP & SUPPORT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ...faqs.asMap().entries.map((e) {
                    final idx = e.key;
                    final faq = e.value;
                    final isOpen = _openFaqIndex == idx;

                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            faq["q"]!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            isOpen ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                          ),
                          onTap: () {
                            setState(() {
                              _openFaqIndex = isOpen ? null : idx;
                            });
                          },
                        ),
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: Text(
                              faq["a"]!,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                          ),
                        if (idx < faqs.length - 1)
                          Divider(height: 1, color: border),
                      ],
                    );
                  }),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: const Icon(
                      Icons.report_problem_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Report an Issue',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () => _showReportIssueModal(context),
                  ),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: const Icon(
                      Icons.chat_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Send Feedback',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () => _showFeedbackModal(context),
                  ),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Terms & Privacy Policy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsAndPoliciesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Danger Zone
            Text(
              'DANGER ZONE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppColors.destructive.withValues(alpha: 0.3),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: AppColors.destructive,
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.destructive,
                  ),
                ),
                subtitle: const Text(
                  'Permanently remove all data and activities',
                  style: TextStyle(fontSize: 10),
                ),
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

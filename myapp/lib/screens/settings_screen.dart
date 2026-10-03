import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_toast.dart';
import '../core/utils/location_feedback.dart';
import '../models/user_profile.dart';
import '../services/report_service.dart';
import '../state/activities_state.dart';
import '../state/auth_state.dart';
import '../state/theme_state.dart';
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
    final avatarCtrl = TextEditingController(text: user.avatarUrl ?? "");
    final phoneCtrl = TextEditingController(text: user.phone ?? "");
    final cityCtrl = TextEditingController(text: user.city ?? "");
    final bioCtrl = TextEditingController(text: user.bio ?? "");
    String gender = user.gender ?? "Prefer not to say";
    bool isSaving = false;
    bool fetchingGps = false;

    final presetAvatars = [
      "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80",
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80",
      "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80",
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80",
    ];

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
            final currentAvatar = avatarCtrl.text.trim();
            final initialChar = user.fullName.isNotEmpty
                ? user.fullName[0].toUpperCase()
                : (user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : 'U');

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.pencil,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Update your details & profile avatar',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForegroundLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Avatar Preview & Input
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.primary,
                                backgroundImage: currentAvatar.isNotEmpty
                                    ? NetworkImage(currentAvatar)
                                    : null,
                                child: currentAvatar.isEmpty
                                    ? Text(
                                        initialChar,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.camera,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: presetAvatars.map((url) {
                                final isSelected = avatarCtrl.text == url;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      avatarCtrl.text = url;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(url),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: avatarCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Avatar Image URL',
                        prefixIcon: Icon(LucideIcons.image, size: 18),
                        hintText: 'Paste image link or choose preset above',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(LucideIcons.user, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(LucideIcons.atSign, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(LucideIcons.phone, size: 18),
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
                        prefixIcon: Icon(LucideIcons.users, size: 18),
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
                        prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                      ),
                    ),
                    // TanStack profile.settings.tsx → handleFetchProfileGPS.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: fetchingGps
                            ? null
                            : () async {
                                setModalState(() => fetchingGps = true);
                                final auth = context.read<AuthState>();
                                final err = await auth
                                    .saveVerifiedProfileLocation();
                                if (!ctx.mounted) return;
                                setModalState(() {
                                  fetchingGps = false;
                                  if (err == null) {
                                    cityCtrl.text =
                                        auth.currentUser?.city ?? cityCtrl.text;
                                  }
                                });
                                if (err == null) {
                                  AppToast.show(
                                    ctx,
                                    'Profile location verified',
                                  );
                                } else {
                                  showLocationError(ctx, err);
                                }
                              },
                        icon: fetchingGps
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                LucideIcons.navigation,
                                size: 14,
                                color: AppColors.primary,
                              ),
                        label: Text(
                          fetchingGps
                              ? 'Fetching location…'
                              : 'Use current location',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
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
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final uname = unameCtrl.text.trim();

                                if (name.length < 2) {
                                  AppToast.show(
                                    context,
                                    'Full name must be at least 2 characters',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (uname.length < 3) {
                                  AppToast.show(
                                    context,
                                    'Username must be at least 3 characters',
                                    isError: true,
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                final auth = context.read<AuthState>();
                                final success = await auth.updateProfile(
                                  fullName: name,
                                  username: uname,
                                  avatarUrl: avatarCtrl.text.trim().isNotEmpty
                                      ? avatarCtrl.text.trim()
                                      : null,
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

                                if (!ctx.mounted) return;
                                if (!success) {
                                  setModalState(() => isSaving = false);
                                  AppToast.show(
                                    ctx,
                                    auth.error ?? 'Failed to update profile. Please try again.',
                                    isError: true,
                                  );
                                  return;
                                }

                                Navigator.of(ctx).pop();
                                AppToast.show(
                                  context,
                                  'Profile details updated successfully',
                                );
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Profile Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      unameCtrl.dispose();
      avatarCtrl.dispose();
      phoneCtrl.dispose();
      cityCtrl.dispose();
      bioCtrl.dispose();
    });
  }

  void _showBlockedUsersModal(BuildContext context, AuthState authState) {
    final blockedIds = authState.blockedUserIds.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Blocked Users',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${blockedIds.length} active',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (blockedIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'You haven\'t blocked anyone yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForegroundLight,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: blockedIds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final bId = blockedIds[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.mutedLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.userX,
                            size: 18,
                            color: AppColors.destructive,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Blocked User ID: ${bId.substring(0, bId.length > 8 ? 8 : bId.length)}…',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              authState.unblockUser(bId);
                              Navigator.of(ctx).pop();
                              AppToast.show(context, 'User unblocked');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'Unblock',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showReportIssueModal(BuildContext context) {
    final textCtrl = TextEditingController();
    String category = "Safety & Conduct";
    bool isSubmitting = false;

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
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final notes = textCtrl.text.trim();
                              if (notes.isEmpty) {
                                AppToast.show(
                                  ctx,
                                  'Please describe the issue in detail.',
                                  isError: true,
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              final user = context
                                  .read<AuthState>()
                                  .currentUser;
                              if (user != null) {
                                ReportReason reasonEnum = ReportReason.other;
                                if (category == "Safety & Conduct") {
                                  reasonEnum = ReportReason.unsafeBehavior;
                                } else if (category == "Inappropriate Plan") {
                                  reasonEnum =
                                      ReportReason.inappropriateContent;
                                }
                                await ReportService.submitReport(
                                  reporterId: user.id,
                                  targetType: 'user',
                                  targetId: user.id,
                                  reason: reasonEnum,
                                  notes: notes,
                                );
                              }
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pop();
                              AppToast.show(
                                context,
                                'Report submitted. Safety team will review it.',
                              );
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => textCtrl.dispose());
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
                          LucideIcons.star,
                          size: 28,
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
                        AppToast.show(context, 'Thank you for your feedback!');
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
    ).whenComplete(() => textCtrl.dispose());
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmCtrl = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
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
                enabled: !isDeleting,
                decoration: const InputDecoration(hintText: 'DELETE'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      if (confirmCtrl.text.trim() == "DELETE") {
                        setModalState(() => isDeleting = true);
                        final actState = context.read<ActivitiesState>();
                        final success = await context
                            .read<AuthState>()
                            .deleteAccount();
                        actState.clearLocation();
                        if (!ctx.mounted) return;
                        setModalState(() => isDeleting = false);
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        if (success) {
                          AppToast.show(context, 'Account deleted');
                        } else {
                          AppToast.show(context, 'Account signed out');
                        }
                      } else {
                        AppToast.show(
                          ctx,
                          'Please type DELETE to confirm',
                          isError: true,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    ).whenComplete(() => confirmCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final themeState = context.watch<ThemeState>();
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
          icon: const Icon(LucideIcons.arrowLeft),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: cardBg,
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
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : 'U',
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
                      trailing: ElevatedButton.icon(
                        onPressed: () => _openEditProfileModal(context, user),
                        icon: const Icon(LucideIcons.pencil, size: 13),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMuted,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      themeState.themeMode == ThemeMode.dark
                          ? LucideIcons.moon
                          : (themeState.themeMode == ThemeMode.light
                                ? LucideIcons.sun
                                : LucideIcons.laptop),
                      size: 20,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      themeState.themeMode == ThemeMode.system
                          ? 'System Theme'
                          : (themeState.themeMode == ThemeMode.dark
                                ? 'Dark Theme'
                                : 'Light Theme'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(LucideIcons.laptop, size: 14),
                          tooltip: 'System',
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(LucideIcons.sun, size: 14),
                          tooltip: 'Light',
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(LucideIcons.moon, size: 14),
                          tooltip: 'Dark',
                        ),
                      ],
                      selected: {themeState.themeMode},
                      onSelectionChanged: (selected) {
                        themeState.setThemeMode(selected.first);
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: border),
                  SwitchListTile.adaptive(
                    value: authState.pushEnabled,
                    activeTrackColor: AppColors.primary,
                    title: const Text(
                      'Push Notifications',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
                      AppToast.show(
                        context,
                        val
                            ? 'Push notifications enabled'
                            : 'Push notifications disabled',
                      );
                    },
                  ),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: const Icon(
                      LucideIcons.userX,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Blocked Users',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${authState.blockedUserIds.length} active',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedForegroundLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronRight, size: 14),
                      ],
                    ),
                    onTap: () => _showBlockedUsersModal(context, authState),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FAQs & Support
            Text(
              'HELP & SUPPORT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: cardBg,
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
                            isOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 18,
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
                      LucideIcons.alertTriangle,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Report an Issue',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 14),
                    onTap: () => _showReportIssueModal(context),
                  ),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: const Icon(
                      LucideIcons.messageSquare,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Send Feedback',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 14),
                    onTap: () => _showFeedbackModal(context),
                  ),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: const Icon(
                      LucideIcons.fileText,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Terms & Privacy Policy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 14),
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppColors.destructive.withValues(alpha: 0.3),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
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

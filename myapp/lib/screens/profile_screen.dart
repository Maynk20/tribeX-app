import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../models/activity.dart';
import '../models/join_request.dart';
import '../state/activities_state.dart';
import '../state/auth_state.dart';
import '../widgets/activity/delete_plan_dialog.dart';
import '../widgets/activity/edit_plan_modal.dart';
import '../widgets/activity/manage_requests_modal.dart';
import '../widgets/profile/emergency_sos_modal.dart';
import '../widgets/profile/rate_squad_modal.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _plansTab = "joined"; // 'joined' or 'hosted'

  Future<void> _openDirections(Activity a) async {
    final uri = a.latitude != null && a.longitude != null
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${a.latitude},${a.longitude}',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(a.location)}',
          );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actState = context.watch<ActivitiesState>();
    final authState = context.watch<AuthState>();
    final user = authState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.settings, size: 22),
                      tooltip: 'Settings',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to see your hosted plans, ratings and squad stats.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hostedPlans = actState.activities
        .where((a) => a.hostId == user.id)
        .toList();
    final joinedPlanIds = actState.joinRequests
        .where((r) => r.userId == user.id && r.status == JoinStatus.accepted)
        .map((r) => r.activityId)
        .toSet();

    final joinedPlans = actState.activities
        .where((a) => joinedPlanIds.contains(a.id))
        .toList();

    final displayName = user.fullName.isNotEmpty
        ? user.fullName
        : (user.username.isNotEmpty ? user.username : 'You');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching TanStack: p.uppercase tracking-[0.18em] + h1 text-3xl font-bold
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFILE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.settings,
                            size: 18,
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text('Sign out?'),
                              content: const Text(
                                'Are you sure you want to sign out of tribeX?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    actState.setScope(FeedScope.discover);
                                    actState.clearLocation();
                                    authState.signOut();
                                    Navigator.of(ctx).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.destructive,
                                  ),
                                  child: const Text('Sign out'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.logOut,
                            size: 16,
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile Card: rounded-3xl border border-border/60 bg-card p-5
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: border.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primary,
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            if (user.isVerified)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.badgeCheck,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.foregroundDark
                                            : AppColors.foregroundLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user.isVerified) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryMuted,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.badgeCheck,
                                            size: 10,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'VERIFIED',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (user.city != null &&
                                  user.city!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.mapPin,
                                      size: 12,
                                      color: isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      user.city!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.mutedForegroundDark
                                            : AppColors.mutedForegroundLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.star,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    user.rating.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ' host rating · ${hostedPlans.length} plans',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successMuted,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '⭐ ${user.reliabilityLabel}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Bio
                    Text(
                      user.bio ?? 'Tell your squad about yourself in settings.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Row: rounded-2xl border border-primary/20 bg-primary/10 py-3
                    Row(
                      children: [
                        _StatBox(
                          label: 'HOSTED',
                          value: '${hostedPlans.length}',
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          label: 'JOINED',
                          value: '${joinedPlans.length}',
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          label: 'RATING',
                          value: user.rating.toStringAsFixed(2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // My Plans Section
              Text(
                'MY PLANS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 8),

              // Tabs: rounded-full border border-border/60 bg-card p-1 text-xs
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
                        onTap: () => setState(() => _plansTab = "joined"),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _plansTab == "joined"
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Joined · ${joinedPlans.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _plansTab == "joined"
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
                        onTap: () => setState(() => _plansTab = "hosted"),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _plansTab == "hosted"
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Hosted · ${hostedPlans.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _plansTab == "hosted"
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
              const SizedBox(height: 12),

              // Plans Content
              if (_plansTab == "joined") ...[
                if (joinedPlans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: border.withValues(alpha: 0.6)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "You haven't joined any plans yet. Discover one on the Explore tab.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  )
                else
                  ...joinedPlans.map((p) {
                    final isEnded = p.dateTime.isBefore(DateTime.now());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMuted,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  AppCategories.emojiFor(p.category),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.calendar,
                                          size: 12,
                                          color: isDark
                                              ? AppColors.mutedForegroundDark
                                              : AppColors.mutedForegroundLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${p.dateTime.day}/${p.dateTime.month} · ${p.dateTime.hour}:${p.dateTime.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.mutedForegroundDark
                                                : AppColors
                                                      .mutedForegroundLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(activity: p),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.backgroundLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: border.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.messageCircle,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForegroundLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _openDirections(p),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.backgroundLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: border.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.navigation,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForegroundLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isEnded) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  RateSquadModal.show(context, activity: p);
                                },
                                icon: const Icon(
                                  LucideIcons.sparkles,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Event ended · Rate your squad',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ] else ...[
                if (hostedPlans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: border.withValues(alpha: 0.6)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "You haven't hosted a plan yet. Tap Create to host one.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  )
                else
                  ...hostedPlans.map((p) {
                    final pendingCount = actState.getPendingCountForActivity(
                      p.id,
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryMuted,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppCategories.emojiFor(p.category),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.totalSlots - p.slotsLeft}/${p.totalSlots} joined',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForegroundLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ManageRequestsModal.show(
                                context,
                                activityId: p.id,
                                activityTitle: p.title,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: pendingCount > 0
                                    ? AppColors.primary
                                    : AppColors.primaryMuted,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                pendingCount > 0
                                    ? 'Manage ($pendingCount)'
                                    : 'Manage',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: pendingCount > 0
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              EditPlanModal.show(context, activity: p);
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : AppColors.backgroundLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.pencil,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(activity: p),
                                ),
                              );
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : AppColors.backgroundLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.messageSquare,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              DeletePlanDialog.show(
                                context,
                                activity: p,
                                onConfirmDelete: () {
                                  actState.deleteActivity(p.id);
                                },
                              );
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : AppColors.backgroundLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.trash2,
                                size: 14,
                                color: AppColors.destructive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
              const SizedBox(height: 16),

              // Settings & Emergency SOS Card: rounded-2xl border border-border/60 bg-card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border.withValues(alpha: 0.6)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.userCog,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.foregroundDark
                                      : AppColors.foregroundLight,
                                ),
                              ),
                            ),
                            Text(
                              '→',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: border.withValues(alpha: 0.6)),
                    InkWell(
                      onTap: () {
                        EmergencySosModal.show(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.shieldAlert,
                              size: 18,
                              color: AppColors.destructive,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Emergency SOS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.destructive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Version info
              Center(
                child: Text(
                  'tribeX v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        (isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight)
                            .withValues(alpha: 0.7),
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.mutedForegroundLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

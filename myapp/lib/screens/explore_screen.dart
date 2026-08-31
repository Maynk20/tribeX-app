import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_toast.dart';
import '../state/activities_state.dart';
import '../state/auth_state.dart';
import '../widgets/activity/activity_card.dart';
import '../widgets/activity/delete_plan_dialog.dart';
import '../widgets/activity/edit_plan_modal.dart';
import '../widgets/activity/manage_requests_modal.dart';
import '../widgets/activity/safety_disclaimer_modal.dart';
import '../widgets/common/loaders.dart';
import '../widgets/common/notifications_bell_dialog.dart';
import '../widgets/common/place_search_dialog.dart';
import '../widgets/common/search_filter_sheet.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

class ExploreScreen extends StatelessWidget {
  final VoidCallback? onNavigateToCreate;
  final VoidCallback? onNavigateToProfile;

  const ExploreScreen({
    super.key,
    this.onNavigateToCreate,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final actState = context.watch<ActivitiesState>();
    final authState = context.watch<AuthState>();
    final user = authState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final filteredActivities = actState.getFilteredActivities(
      user?.id,
      authState.blockedUserIds,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await actState.fetchActivities();
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location & Top Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user != null)
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        PlaceSearchDialog.show(
                                          context,
                                          initialValue: actState.location,
                                          onSelect: (p) => actState.setLocation(
                                            '${p.title}, ${p.subtitle.split(",")[0]}',
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.mapPin,
                                            size: 13,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            actState.location,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.foregroundDark
                                                  : AppColors.foregroundLight,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            LucideIcons.chevronDown,
                                            size: 13,
                                            color: isDark
                                                ? AppColors.mutedForegroundDark
                                                : AppColors
                                                      .mutedForegroundLight,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        actState.setLocation(
                                          "Indiranagar, Bengaluru",
                                        );
                                        AppToast.show(
                                          context,
                                          'GPS Location updated',
                                        );
                                      },
                                      child: Icon(
                                        LucideIcons.navigation,
                                        size: 13,
                                        color: isDark
                                            ? AppColors.mutedForegroundDark
                                            : AppColors.mutedForegroundLight,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'DISCOVER PLANS NEARBY',
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
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'tribe',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    TextSpan(text: 'X'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Profile / Sign In + Notifications Bell
                          Row(
                            children: [
                              if (user != null) ...[
                                IconButton(
                                  icon: const Icon(LucideIcons.bell, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: cardBg,
                                    side: BorderSide(
                                      color: border.withValues(alpha: 0.6),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                  ),
                                  onPressed: () {
                                    NotificationsBellDialog.show(
                                      context,
                                      onOpenActivity: (actId) {
                                        try {
                                          final act = actState.activities
                                              .firstWhere((a) => a.id == actId);
                                          ManageRequestsModal.show(
                                            context,
                                            activityId: act.id,
                                            activityTitle: act.title,
                                          );
                                        } catch (_) {
                                          AppToast.show(
                                            context,
                                            'Activity no longer available',
                                            isError: true,
                                          );
                                        }
                                      },
                                      onOpenChat: (actId) {
                                        try {
                                          final act = actState.activities
                                              .firstWhere((a) => a.id == actId);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ChatScreen(activity: act),
                                            ),
                                          );
                                        } catch (_) {
                                          AppToast.show(
                                            context,
                                            'Activity no longer available',
                                            isError: true,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: onNavigateToProfile,
                                  child: CircleAvatar(
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
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ] else
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AuthScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.logIn, size: 14),
                                  label: const Text('Sign in'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search bar & Filter button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: TextField(
                                onChanged: actState.setSearchQuery,
                                decoration: const InputDecoration(
                                  hintText: 'Search plans, sports, spots…',
                                  prefixIcon: Icon(
                                    LucideIcons.search,
                                    size: 18,
                                    color: AppColors.mutedForegroundLight,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    SearchFilterSheet.show(context),
                                icon: const Icon(
                                  LucideIcons.slidersHorizontal,
                                  size: 18,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: cardBg,
                                  side: BorderSide(
                                    color: border.withValues(alpha: 0.6),
                                  ),
                                  minimumSize: const Size(48, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              if (actState.activeFilterCount > 0)
                                Positioned(
                                  top: -3,
                                  right: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${actState.activeFilterCount}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Category Groups Chips
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryChip(
                              label: 'All',
                              isSelected:
                                  actState.selectedGroup == "All" &&
                                  actState.selectedCategory == "All",
                              onTap: () {
                                actState.setGroup("All");
                                actState.setCategory("All");
                              },
                            ),
                            ...AppCategories.groups.map((g) {
                              final isSelected = actState.selectedGroup == g;
                              return _CategoryChip(
                                label: g.toUpperCase(),
                                isSelected: isSelected,
                                onTap: () => actState.setGroup(g),
                              );
                            }),
                          ],
                        ),
                      ),

                      // Sub-category chips (if group selected)
                      if (actState.selectedGroup != "All") ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _SubCategoryChip(
                                label: 'All in group',
                                isSelected: actState.selectedCategory == "All",
                                onTap: () => actState.setCategory("All"),
                              ),
                              ...AppCategories.all
                                  .where(
                                    (c) => c.group == actState.selectedGroup,
                                  )
                                  .map((c) {
                                    final isSelected =
                                        actState.selectedCategory == c.key;
                                    return _SubCategoryChip(
                                      label: c.label,
                                      emoji: c.emoji,
                                      isSelected: isSelected,
                                      onTap: () => actState.setCategory(c.key),
                                    );
                                  }),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Mode Filter (All / In-Person / Virtual)
                      Container(
                        height: 38,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            _ModeTab(
                              label: 'All',
                              isSelected: actState.modeFilter == ModeFilter.all,
                              onTap: () =>
                                  actState.setModeFilter(ModeFilter.all),
                            ),
                            _ModeTab(
                              label: 'In-Person',
                              icon: LucideIcons.mapPin,
                              isSelected:
                                  actState.modeFilter == ModeFilter.inPerson,
                              onTap: () =>
                                  actState.setModeFilter(ModeFilter.inPerson),
                            ),
                            _ModeTab(
                              label: 'Virtual',
                              icon: LucideIcons.monitor,
                              isSelected:
                                  actState.modeFilter == ModeFilter.online,
                              onTap: () =>
                                  actState.setModeFilter(ModeFilter.online),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Scopes Switch (Discover / Joined / Hosting) (If signed in)
                      if (user != null)
                        Container(
                          height: 36,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              _ScopeTab(
                                label: 'Discover',
                                isSelected:
                                    actState.scope == FeedScope.discover,
                                onTap: () =>
                                    actState.setScope(FeedScope.discover),
                              ),
                              _ScopeTab(
                                label: 'Joined',
                                isSelected: actState.scope == FeedScope.joined,
                                onTap: () =>
                                    actState.setScope(FeedScope.joined),
                              ),
                              _ScopeTab(
                                label: 'Hosting',
                                isSelected: actState.scope == FeedScope.hosting,
                                onTap: () =>
                                    actState.setScope(FeedScope.hosting),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Section Title
                      Text(
                        user == null || actState.scope == FeedScope.discover
                            ? 'Happening nearby'
                            : actState.scope == FeedScope.joined
                            ? "Plans you've joined"
                            : "Plans you're hosting",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Activity Cards List
              if (actState.isLoading && filteredActivities.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: ListSkeleton(count: 3),
                  ),
                )
              else if (actState.error != null && filteredActivities.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            size: 36,
                            color: AppColors.destructive,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Couldn't load plans right now.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => actState.fetchActivities(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (filteredActivities.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.compass,
                            size: 36,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            actState.scope == FeedScope.hosting
                                ? "You haven't hosted any plans yet."
                                : actState.scope == FeedScope.joined
                                ? "You haven't joined any plans yet."
                                : "No plans match your filters right now.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap the Create tab below to post one.',
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
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, idx) {
                      final act = filteredActivities[idx];
                      final isHost = user != null && act.hostId == user.id;
                      final myReq = user != null
                          ? actState.getMyRequest(act.id, user.id)
                          : null;
                      final pendingCount = actState.getPendingCountForActivity(
                        act.id,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ActivityCard(
                          activity: act,
                          isHost: isHost,
                          myStatus: myReq?.status,
                          pendingCount: pendingCount,
                          onJoin: () {
                            if (user == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthScreen(),
                                ),
                              );
                              return;
                            }
                            SafetyDisclaimerModal.show(
                              context,
                              onAgree: () {
                                actState.requestToJoin(act.id, user);
                                AppToast.show(context, 'Request sent to host!');
                              },
                            );
                          },
                          onChat: () {
                            if (user == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthScreen(),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(activity: act),
                              ),
                            );
                          },
                          onManage: () {
                            ManageRequestsModal.show(
                              context,
                              activityId: act.id,
                              activityTitle: act.title,
                            );
                          },
                          onToggleUrgent: () {
                            actState.toggleUrgent(act.id);
                            AppToast.show(
                              context,
                              act.isUrgentActive
                                  ? 'Urgent mode cleared'
                                  : '⚡ Urgent alert sent to nearby players',
                            );
                          },
                          onEdit: () {
                            EditPlanModal.show(context, activity: act);
                          },
                          onDelete: () {
                            DeletePlanDialog.show(
                              context,
                              activity: act,
                              onConfirmDelete: () {
                                actState.deleteActivity(act.id);
                                AppToast.show(context, 'Plan deleted');
                              },
                            );
                          },
                        ),
                      );
                    }, childCount: filteredActivities.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.cardDark : AppColors.cardLight),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight)
                        .withValues(alpha: 0.6),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubCategoryChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubCategoryChip({
    required this.label,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? AppColors.cardDark : AppColors.cardLight),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight)
                        .withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScopeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight),
            ),
          ),
        ),
      ),
    );
  }
}

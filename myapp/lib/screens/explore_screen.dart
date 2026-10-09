import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_toast.dart';
import '../core/utils/location_feedback.dart';
import '../services/location_service.dart';
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
import '../widgets/common/report_modal.dart';
import '../widgets/common/search_filter_sheet.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

class ExploreScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCreate;
  final VoidCallback? onNavigateToProfile;

  const ExploreScreen({
    super.key,
    this.onNavigateToCreate,
    this.onNavigateToProfile,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;
  Timer? _searchDebounceTimer;
  bool _showScrollToTop = false;
  bool _hasSearchText = false;
  bool _isGettingLocation = false;

  @override
  bool get wantKeepAlive => true;

  /// TanStack `handleUseGPS` → `requestBrowserLocation`.
  Future<void> _fetchGpsLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    final lookup = await LocationService.resolveCurrentPlace();

    if (!mounted) return;
    setState(() => _isGettingLocation = false);

    final place = lookup.place;
    if (place != null) {
      context.read<ActivitiesState>().setPlace(place);
      AppToast.show(context, 'Showing plans within 15 km of your location');
    } else {
      showLocationError(
        context,
        lookup.result.error ?? "Couldn't get your location",
      );
    }
  }

  Future<void> _checkInitialLocation() async {
    // 1. If user is signed in with GPS coords on profile, use that as initial center if no place set
    final user = context.read<AuthState>().currentUser;
    if (user != null && user.latitude != null && user.longitude != null) {
      if (!mounted) return;
      final actState = context.read<ActivitiesState>();
      if (actState.place == null) {
        actState.setPlace(
          SavedPlace(
            displayName: user.city ?? 'Current Location',
            short: user.city ?? 'Current Location',
            lat: user.latitude!,
            lon: user.longitude!,
          ),
        );
        return;
      }
    }

    // 2. Otherwise, check if GPS permission is already granted silently
    try {
      final hasPerm = await LocationService.hasLocationPermission();
      if (hasPerm && mounted) {
        await _fetchGpsLocation();
      }
    } catch (_) {}
  }

  /// TanStack onJoin guard: toast when the profile lacks a verified location.
  void _showAddGpsLocationPrompt() {
    AppToast.show(
      context,
      'Add your GPS profile location first — open Settings → Edit Profile → Use current location.',
      isError: true,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _scrollCtrl = ScrollController();

    _searchCtrl.addListener(() {
      final hasText = _searchCtrl.text.isNotEmpty;
      if (hasText != _hasSearchText) {
        setState(() => _hasSearchText = hasText);
      }
    });

    _scrollCtrl.addListener(() {
      final shouldShow = _scrollCtrl.hasClients && _scrollCtrl.offset > 240;
      if (shouldShow != _showScrollToTop) {
        setState(() => _showScrollToTop = shouldShow);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final act = context.read<ActivitiesState>();
      if (act.place == null) {
        _checkInitialLocation();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onSearchChanged(String val) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ActivitiesState>().setSearchQuery(val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(LucideIcons.arrowUp, size: 18),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await actState.fetchActivities();
          },
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                                          onSelect: (p) {
                                            // TanStack toPlace(): short = title.
                                            actState.setPlace(
                                              SavedPlace(
                                                displayName: [
                                                  p.title,
                                                  if (p.subtitle.isNotEmpty)
                                                    p.subtitle,
                                                ].join(', '),
                                                short: p.title,
                                                lat: p.lat,
                                                lon: p.lon,
                                              ),
                                            );
                                            AppToast.show(
                                              context,
                                              'Showing plans within 15 km of ${p.title}',
                                            );
                                          },
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
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
                                      onTap: _isGettingLocation
                                          ? null
                                          : _fetchGpsLocation,
                                      child: _isGettingLocation
                                          ? const SizedBox(
                                              width: 13,
                                              height: 13,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : Icon(
                                              LucideIcons.navigation,
                                              size: 13,
                                              color: isDark
                                                  ? AppColors
                                                        .mutedForegroundDark
                                                  : AppColors
                                                        .mutedForegroundLight,
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
                                  onTap: widget.onNavigateToProfile,
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
                                controller: _searchCtrl,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'Search plans, sports, spots…',
                                  prefixIcon: const Icon(
                                    LucideIcons.search,
                                    size: 18,
                                    color: AppColors.mutedForegroundLight,
                                  ),
                                  suffixIcon: _hasSearchText
                                      ? IconButton(
                                          icon: const Icon(
                                            LucideIcons.x,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            context
                                                .read<ActivitiesState>()
                                                .setSearchQuery('');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
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

                      // Section Title & 15 km Radius Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user == null ||
                                          actState.scope == FeedScope.discover
                                      ? (actState.place != null
                                            ? 'Plans within 15 km'
                                            : 'Nearby plans')
                                      : actState.scope == FeedScope.joined
                                      ? "Plans you've joined"
                                      : "Plans you're hosting",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.25,
                                  ),
                                ),
                                if (actState.scope == FeedScope.discover &&
                                    actState.place != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Showing activities around ${actState.place!.short.isNotEmpty ? actState.place!.short : actState.location}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (actState.scope == FeedScope.discover &&
                              actState.place != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.compass,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '15 km radius',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Location unavailable banner when discovering plans without coordinates
                      if (actState.scope == FeedScope.discover &&
                          actState.place == null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: border.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.mapPinOff,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location unavailable',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.foregroundDark
                                            : AppColors.foregroundLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Enable GPS or select your city to filter plans within 15 km of you.',
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
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isGettingLocation
                                    ? null
                                    : _fetchGpsLocation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isGettingLocation
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Use GPS',
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
              else if (actState.error != null &&
                  filteredActivities.isEmpty &&
                  !actState.isLoading)
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
                            LucideIcons.wifiOff,
                            size: 36,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user == null
                                ? 'Sign in to Discover Local Fun!'
                                : 'Could not load plans',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user == null
                                ? 'Log in to browse plans, join activities, and connect with people nearby.'
                                : 'Check your connection and try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (user == null)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AuthScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(LucideIcons.logIn, size: 16),
                              label: const Text('Sign In'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: () => actState.fetchActivities(),
                              icon: const Icon(LucideIcons.rotateCcw, size: 14),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
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
                                : (actState.activeFilterCount > 0 ||
                                      actState.searchQuery.isNotEmpty)
                                ? "No plans match your active filters."
                                : "No plans happening nearby right now.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            actState.scope == FeedScope.hosting
                                ? 'Tap Create below to host a hangout or game.'
                                : actState.scope == FeedScope.joined
                                ? 'Explore local plans and request to join.'
                                : (actState.activeFilterCount > 0 ||
                                      actState.searchQuery.isNotEmpty)
                                ? 'Try clearing filters or search terms.'
                                : 'Be the first to post a box cricket, trek, or hangout!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                          if (actState.activeFilterCount > 0 ||
                              actState.searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: () {
                                actState.resetFilters();
                                actState.setSearchQuery('');
                                _searchCtrl.clear();
                              },
                              icon: const Icon(LucideIcons.rotateCcw, size: 14),
                              label: const Text('Reset All Filters'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
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
                      final distanceKm =
                          actState.place != null &&
                              act.latitude != null &&
                              act.longitude != null
                          ? LocationService.haversineKm(
                              actState.place!.lat,
                              actState.place!.lon,
                              act.latitude!,
                              act.longitude!,
                            )
                          : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ActivityCard(
                          key: ValueKey(act.id),
                          activity: act,
                          distanceKm: distanceKm,
                          isHost: isHost,
                          myStatus: myReq?.status,
                          pendingCount: pendingCount,
                          hasProfileGpsLocation:
                              authState.hasProfileGpsLocation,
                          onAddGpsLocation: _showAddGpsLocationPrompt,
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
                            if (!authState.hasProfileGpsLocation) {
                              _showAddGpsLocationPrompt();
                              return;
                            }
                            SafetyDisclaimerModal.show(
                              context,
                              onAgree: () async {
                                final err = await actState.requestToJoin(
                                  act.id,
                                  user,
                                );
                                if (!context.mounted) return;
                                if (err == null) {
                                  AppToast.show(
                                    context,
                                    'Request sent to host',
                                  );
                                } else {
                                  AppToast.show(context, err, isError: true);
                                }
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
                          onReport: () {
                            ReportModal.show(
                              context,
                              targetType: 'activity',
                              targetId: act.id,
                              targetTitle: act.title,
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

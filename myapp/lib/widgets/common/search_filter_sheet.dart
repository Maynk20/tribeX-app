import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/activities_state.dart';

class SearchFilterSheet extends StatelessWidget {
  const SearchFilterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const SearchFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActivitiesState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                    .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SORT & FILTER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              if (state.activeFilterCount > 0 || state.sortKey != SortKey.date)
                GestureDetector(
                  onTap: state.resetFilters,
                  child: const Text(
                    'RESET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Sort by
          Text(
            'SORT BY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SortButton(
                label: 'Date',
                isSelected: state.sortKey == SortKey.date,
                onTap: () => state.setSortKey(SortKey.date),
              ),
              const SizedBox(width: 8),
              _SortButton(
                label: 'Distance',
                isSelected: state.sortKey == SortKey.distance,
                onTap: () => state.setSortKey(SortKey.distance),
              ),
              const SizedBox(width: 8),
              _SortButton(
                label: 'Popularity',
                isSelected: state.sortKey == SortKey.popularity,
                onTap: () => state.setSortKey(SortKey.popularity),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick filters
          Text(
            'QUICK FILTERS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 8),
          _QuickFilterTile(
            label: 'Free entry',
            icon: Icons.currency_rupee,
            isSelected: state.freeOnly,
            onTap: state.toggleFreeOnly,
          ),
          const SizedBox(height: 6),
          _QuickFilterTile(
            label: 'Has open spots',
            icon: Icons.group_outlined,
            isSelected: state.spotsOnly,
            onTap: state.toggleSpotsOnly,
          ),
          const SizedBox(height: 6),
          _QuickFilterTile(
            label: 'Today only',
            icon: Icons.access_time,
            isSelected: state.todayOnly,
            onTap: state.toggleTodayOnly,
          ),
          const SizedBox(height: 6),
          _QuickFilterTile(
            label: 'This weekend',
            icon: Icons.calendar_month_outlined,
            isSelected: state.weekendOnly,
            onTap: state.toggleWeekendOnly,
          ),
          const SizedBox(height: 6),
          _QuickFilterTile(
            label: 'Verified hosts only',
            icon: Icons.verified_outlined,
            isSelected: state.verifiedHostsOnly,
            onTap: state.toggleVerifiedHostsOnly,
          ),
          const SizedBox(height: 20),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortButton({
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.primary
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

class _QuickFilterTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickFilterTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight),
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

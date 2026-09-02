import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/activity.dart';
import '../../models/join_request.dart';

/// ActivityCard matching the TanStack/React index.tsx ActivityCard component exactly.
///
/// Layout:
/// - rounded-3xl (28px) border border-border/60 bg-card p-4
/// - Cover image: -mx-4 -mt-4 mb-3 h-36 full-bleed
/// - Emoji box: h-12 w-12 rounded-2xl (48×48, 16px radius) bg-primary/15 text-primary
/// - Category badge: text-[10px] font-semibold uppercase tracking-wider
/// - Title: text-base font-semibold tracking-tight (16px, w600)
/// - Location/Time: text-xs text-muted-foreground with h-3 w-3 icons (12px)
/// - Divider: border-t border-border/60 pt-3
/// - Stats: Users h-3.5w-3.5, Star fill-current text-primary h-3.5 w-3.5
/// - Host avatar: h-4 w-4 (16px circle)
/// - Action buttons: h-9 w-9 rounded-full (36px circles)
/// - Join/Manage buttons: rounded-full
class ActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isHost;
  final JoinStatus? myStatus;
  final int pendingCount;
  final VoidCallback onJoin;
  final VoidCallback onChat;
  final VoidCallback? onManage;
  final VoidCallback? onToggleUrgent;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final bool isFemale;
  final bool isVerified;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.isHost,
    this.myStatus,
    this.pendingCount = 0,
    required this.onJoin,
    required this.onChat,
    this.onManage,
    this.onToggleUrgent,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.isFemale = true,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final host = activity.host;
    final hostName = host?.fullName ?? host?.username ?? 'Host';
    final isUrgentSlots = activity.slotsLeft <= 3 && activity.slotsLeft > 0;
    final urgentActive = activity.isUrgentActive;

    // Safety Gate
    final blockedByWomen = activity.womenOnly && !isFemale;
    final blockedByVerified = activity.verifiedOnly && !isVerified;
    String? safetyBlock;
    if (blockedByWomen) {
      safetyBlock = 'Women Only Plan';
    } else if (blockedByVerified) {
      safetyBlock = 'Verification Required';
    }

    // Shield label
    String? shieldLabel;
    if (activity.hasSafetyShield) {
      if (activity.womenOnly && activity.verifiedOnly) {
        shieldLabel = 'Women & verified only';
      } else if (activity.womenOnly) {
        shieldLabel = 'Women only';
      } else if (activity.verifiedOnly) {
        shieldLabel = 'Verified only';
      }
    }

    // accent color: bg-primary/15 text-primary
    const accentBg = AppColors.primaryMuted; // ~15% opacity primary

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        // rounded-3xl = 28px radius
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Main content column
          Padding(
            padding: const EdgeInsets.all(16), // p-4
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Photo: -mx-4 -mt-4 mb-3 h-36 — bleed to edges
                if (activity.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left:
                          -0, // covered by negative margin trick via transform
                      bottom: 12, // mb-3
                    ),
                    child: _CoverImage(
                      imageUrl: activity.imageUrl!,
                      urgentActive: urgentActive,
                    ),
                  ),

                // Top row: Emoji + Badges + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji box: h-12 w-12 rounded-2xl (48x48, 16px radius) bg-primary/15
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppCategories.emojiFor(activity.category),
                        // text-2xl leading-none
                        style: const TextStyle(fontSize: 22, height: 1),
                      ),
                    ),
                    const SizedBox(width: 12), // gap-3
                    // Badges + Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges row: flex flex-wrap items-center gap-1.5
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Category badge: rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider
                              _Badge(
                                text: activity.category.toUpperCase(),
                                bgColor: accentBg,
                                textColor: AppColors.primary,
                              ),
                              // Virtual badge
                              if (activity.isOnline)
                                _Badge(
                                  icon: LucideIcons.globe,
                                  text: 'VIRTUAL',
                                  bgColor: AppColors.successMuted,
                                  textColor: isDark
                                      ? const Color(0xFF34D399)
                                      : AppColors.success,
                                ),
                              // Status badges
                              if (myStatus == JoinStatus.accepted)
                                _Badge(
                                  text: 'CONFIRMED',
                                  bgColor: const Color(0x2622C55E),
                                  textColor: isDark
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF16A34A),
                                )
                              else if (myStatus == JoinStatus.pending)
                                _Badge(
                                  text: 'AWAITING APPROVAL',
                                  bgColor: AppColors.warningMuted,
                                  textColor: isDark
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFFD97706),
                                ),
                              if (isHost)
                                const _Badge(
                                  text: 'HOSTING',
                                  bgColor: AppColors.primaryMuted,
                                  textColor: AppColors.primary,
                                ),
                              // Shield badge
                              if (activity.hasSafetyShield &&
                                  shieldLabel != null)
                                _Badge(
                                  icon: LucideIcons.shield,
                                  text: shieldLabel,
                                  bgColor: AppColors.primaryMuted,
                                  textColor: AppColors.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6), // mt-1.5
                          // Title: text-base font-semibold tracking-tight (16px, w600)
                          Text(
                            activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.25, // tracking-tight
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8), // mt-0.5 equiv on children
                // Location: flex items-center gap-1 text-xs text-muted-foreground
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 12, // h-3 w-3
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12, // text-xs
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Time: flex items-center gap-1 text-xs text-muted-foreground
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12, // h-3 w-3
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatWhen(activity.dateTime),
                      style: TextStyle(
                        fontSize: 12, // text-xs
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ),

                // Amenities / Tags (if any)
                if (activity.amenities.isNotEmpty ||
                    activity.topicTags.isNotEmpty) ...[
                  const SizedBox(height: 8), // mt-2
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Amenities: rounded-full bg-secondary text-[10px] font-medium
                      ...activity.amenities.take(4).map((k) {
                        final a = AppCategories.amenityMap[k];
                        if (a == null) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.mutedDark
                                : AppColors.mutedLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            a.badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.foregroundDark.withValues(
                                      alpha: 0.8,
                                    )
                                  : AppColors.foregroundLight.withValues(
                                      alpha: 0.8,
                                    ),
                            ),
                          ),
                        );
                      }),
                      // Topic tags: #tag with border
                      ...activity.topicTags
                          .take(3)
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.hash,
                                    size: 10,
                                    color: isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForegroundLight,
                                  ),
                                  Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ],

                // Divider + stats + actions: mt-auto flex flex-col gap-3 border-t border-border/60 pt-3
                const SizedBox(height: 12),
                Divider(height: 1, color: border.withValues(alpha: 0.6)),
                const SizedBox(height: 12), // pt-3
                // Stats row: flex items-center gap-x-2 text-xs
                Row(
                  children: [
                    // Slots: Users icon h-3.5 w-3.5
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 14, // h-3.5 w-3.5
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.slotsLeft}/${activity.totalSlots}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUrgentSlots
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isUrgentSlots
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForegroundLight),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // Rating: Star fill-current text-primary h-3.5 w-3.5
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.star,
                          size: 14, // h-3.5 w-3.5
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (host?.rating ?? 5.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ),

                    // Separator + Host
                    const SizedBox(width: 4),
                    Text(
                      '·',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Host avatar (h-4 w-4 = 16px circle)
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: AppColors.primaryMuted,
                      backgroundImage: host?.avatarUrl != null
                          ? NetworkImage(host!.avatarUrl!)
                          : null,
                      child: host?.avatarUrl == null
                          ? Text(
                              (hostName.isNotEmpty ? hostName[0] : 'H')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ),
                    if (host?.isVerified ?? false)
                      const Icon(
                        LucideIcons.badgeCheck,
                        size: 12,
                        color: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons row: flex flex-wrap items-center gap-1.5
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (isHost) ...[
                      // Urgent toggle: h-9 w-9 rounded-full
                      if (activity.slotsLeft > 0)
                        _CircleIconButton(
                          icon: LucideIcons.zap,
                          size: 14,
                          onTap: onToggleUrgent ?? () {},
                          backgroundColor: urgentActive
                              ? const Color(0xFFEF4444)
                              : const Color(0x26F59E0B),
                          iconColor: urgentActive
                              ? Colors.white
                              : const Color(0xFFD97706),
                          tooltip: urgentActive
                              ? 'Cancel urgent alert'
                              : 'Send urgent spot alert',
                        ),

                      // Manage button: rounded-full border border-primary/40 bg-primary/10 px-3 py-2
                      _ActionButton(
                        label: 'Manage',
                        onTap: onManage ?? () {},
                        bgColor: AppColors.primaryMuted,
                        textColor: AppColors.primary,
                        borderColor: AppColors.primary.withValues(alpha: 0.4),
                        flex: true,
                      ),

                      // Chat icon button: h-9 w-9 rounded-full border
                      _CircleIconButton(
                        icon: LucideIcons.messageCircle,
                        size: 14,
                        onTap: onChat,
                        backgroundColor: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        iconColor: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                        borderColor: border.withValues(alpha: 0.6),
                      ),

                      // Edit icon button
                      _CircleIconButton(
                        icon: LucideIcons.pencil,
                        size: 14,
                        onTap: onEdit ?? () {},
                        backgroundColor: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        iconColor: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                        borderColor: border.withValues(alpha: 0.6),
                      ),

                      // Delete icon button
                      _CircleIconButton(
                        icon: LucideIcons.trash2,
                        size: 14,
                        onTap: onDelete ?? () {},
                        backgroundColor: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        iconColor: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                        borderColor: border.withValues(alpha: 0.6),
                      ),
                    ] else ...[
                      // Chat icon button (guest)
                      _CircleIconButton(
                        icon: LucideIcons.messageCircle,
                        size: 14,
                        onTap: onChat,
                        backgroundColor: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        iconColor: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                        borderColor: border.withValues(alpha: 0.6),
                      ),

                      // Report flag button (guest)
                      if (onReport != null)
                        _CircleIconButton(
                          icon: LucideIcons.flag,
                          size: 14,
                          onTap: onReport!,
                          backgroundColor: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          iconColor: AppColors.destructive,
                          borderColor: border.withValues(alpha: 0.6),
                          tooltip: 'Report concern',
                        ),

                      // Join / status button
                      if (myStatus == JoinStatus.pending)
                        Expanded(
                          child: _ActionButton(
                            icon: LucideIcons.hourglass,
                            label: 'Request Pending',
                            onTap: null,
                            bgColor: isDark
                                ? AppColors.mutedDark
                                : AppColors.mutedLight,
                            textColor: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                            borderColor: border.withValues(alpha: 0.6),
                          ),
                        )
                      else if (myStatus == JoinStatus.accepted)
                        Expanded(
                          child: _ActionButton(
                            icon: LucideIcons.check,
                            label: 'Joined',
                            onTap: onChat,
                            bgColor: const Color(0x2622C55E),
                            textColor: isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF16A34A),
                          ),
                        )
                      else if (safetyBlock != null)
                        Expanded(
                          child: _ActionButton(
                            icon: LucideIcons.shield,
                            label: safetyBlock,
                            onTap: null,
                            bgColor: isDark
                                ? AppColors.mutedDark
                                : AppColors.mutedLight,
                            textColor: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                            borderColor: border.withValues(alpha: 0.6),
                          ),
                        )
                      else
                        Expanded(
                          child: _ActionButton(
                            label: activity.slotsLeft <= 0
                                ? 'Full'
                                : 'Request to Join',
                            onTap: activity.slotsLeft <= 0 ? null : onJoin,
                            bgColor: AppColors.primary,
                            textColor: Colors.white,
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Pending count overlay badge (absolute top-right)
          if (isHost && pendingCount > 0)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onManage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.bell,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$pendingCount pending',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cover image: -mx-4 -mt-4 mb-3 h-36 full-bleed
class _CoverImage extends StatelessWidget {
  final String imageUrl;
  final bool urgentActive;

  const _CoverImage({required this.imageUrl, required this.urgentActive});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bleedWidth = constraints.maxWidth + 32;
        return Transform.translate(
          offset: const Offset(-16, -16),
          child: SizedBox(
            height: 144, // h-36
            width: bleedWidth,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 800,
                  cacheHeight: 400,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.primaryMuted,
                    child: const Center(
                      child: Icon(LucideIcons.image, color: AppColors.primary),
                    ),
                  ),
                ),
            // Urgent overlay badge on cover image
            if (urgentActive)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.zap, size: 12, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'URGENT · SPOT NEEDED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  },
);
  }
}

/// Badge pill matching: rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider
class _Badge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;

  const _Badge({
    required this.text,
    required this.bgColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8, // tracking-wider
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular icon button: h-9 w-9 (36px) rounded-full
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;
  final String? tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.borderColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Center(
          child: Icon(icon, size: size, color: iconColor),
        ),
      ),
    );
  }
}

/// Action button matching rounded-full px-3 py-2 text-xs font-semibold
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final IconData? icon;
  final bool flex;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    this.icon,
    this.flex = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ), // px-3 py-2
      child: Row(
        mainAxisSize: flex ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12, // text-xs
              fontWeight: FontWeight.w600, // font-semibold
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: onTap == null ? bgColor.withValues(alpha: 0.7) : bgColor,
          borderRadius: BorderRadius.circular(999), // rounded-full
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: child,
      ),
    );
  }
}

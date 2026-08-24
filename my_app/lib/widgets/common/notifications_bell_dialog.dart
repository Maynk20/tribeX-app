import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/notification_item.dart';
import '../../state/notifications_state.dart';

class NotificationsBellDialog extends StatelessWidget {
  final Function(String activityId)? onOpenActivity;
  final Function(String activityId)? onOpenChat;

  const NotificationsBellDialog({
    super.key,
    this.onOpenActivity,
    this.onOpenChat,
  });

  static void show(
    BuildContext context, {
    Function(String activityId)? onOpenActivity,
    Function(String activityId)? onOpenChat,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => NotificationsBellDialog(
        onOpenActivity: onOpenActivity,
        onOpenChat: onOpenChat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifsState = context.watch<NotificationsState>();
    final notifs = notifsState.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (notifsState.unreadCount > 0)
                    GestureDetector(
                      onTap: notifsState.markAllAsRead,
                      child: const Row(
                        children: [
                          Icon(Icons.check, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Mark all read',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // List
            Flexible(
              child: notifs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Text(
                        "You're all caught up.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: notifs.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: border.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (ctx, idx) {
                        final n = notifs[idx];
                        return _NotificationTile(
                          item: n,
                          onTap: () {
                            notifsState.markAsRead(n.id);
                            Navigator.of(context).pop();
                            if (n.activityId != null) {
                              if (n.type == NotificationType.joinRequest) {
                                onOpenActivity?.call(n.activityId!);
                              } else {
                                onOpenChat?.call(n.activityId!);
                              }
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: item.isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: item.isRead
                          ? FontWeight.w600
                          : FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  DateFormatter.timeAgo(item.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ),
            if (item.body != null) ...[
              const SizedBox(height: 3),
              Text(
                item.body!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

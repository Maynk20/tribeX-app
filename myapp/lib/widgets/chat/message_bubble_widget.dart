import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/message.dart';
import '../../services/supabase_service.dart';
import '../../state/chat_state.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool showSenderInfo;
  final VoidCallback? onReport;
  final VoidCallback? onRetry;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isMine,
    this.showSenderInfo = true,
    this.onReport,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    // 1. System Events: Centered subtle event badge/pill
    if (message.isSystemEvent) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.mutedDark.withValues(alpha: 0.6)
                : AppColors.mutedLight.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: border.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message.systemDisplayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Regular Message Bubbles (Outgoing vs Incoming)
    ChatState? chatState;
    try {
      chatState = Provider.of<ChatState>(context);
    } catch (_) {
      chatState = null;
    }
    final cachedProfile = chatState?.getCachedProfile(message.senderId);
    final squadMembers = chatState?.getSquadMembers(message.activityId);
    final squadMember = squadMembers
        ?.where((m) => m.userId == message.senderId)
        .firstOrNull;

    String senderName = '';
    if (message.sender?.fullName.isNotEmpty == true &&
        message.sender!.fullName != 'Squad Member' &&
        message.sender!.fullName != 'User') {
      senderName = message.sender!.fullName;
    } else if (cachedProfile?.fullName.isNotEmpty == true &&
        cachedProfile!.fullName != 'Squad Member' &&
        cachedProfile.fullName != 'User') {
      senderName = cachedProfile.fullName;
    } else if (squadMember?.name.isNotEmpty == true &&
        squadMember!.name != 'Squad Member') {
      senderName = squadMember.name;
    } else if (message.sender?.username.isNotEmpty == true) {
      senderName = message.sender!.username;
    } else if (cachedProfile?.username.isNotEmpty == true) {
      senderName = cachedProfile!.username;
    } else {
      final currentUserId = SupabaseService.client?.auth.currentUser?.id;
      if (currentUserId != null && message.senderId == currentUserId) {
        senderName = 'You';
      } else {
        senderName = 'Member';
      }
    }

    final senderAvatar = message.sender?.avatarUrl ??
        cachedProfile?.avatarUrl ??
        squadMember?.avatarUrl;
    final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'M';

    return Padding(
      padding: EdgeInsets.only(top: showSenderInfo ? 6 : 2, bottom: 2),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Incoming sender avatar on first in group
          if (!isMine) ...[
            if (showSenderInfo)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryMuted,
                  border: Border.all(
                    color: border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: senderAvatar != null && senderAvatar.isNotEmpty
                    ? Image.network(
                        senderAvatar,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
              )
            else
              const SizedBox(
                width: 36,
              ), // Alignment indent when avatar is hidden
          ],

          // Bubble Container
          Flexible(
            child: GestureDetector(
              onLongPress: !isMine ? onReport : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isMine
                      ? (message.isFailed
                            ? Colors.red.shade700
                            : AppColors.primary)
                      : otherBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  border: isMine
                      ? (message.isFailed
                            ? Border.all(color: Colors.red.shade300)
                            : null)
                      : Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.03,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender Name (only on incoming first message of group)
                    if (!isMine && showSenderInfo) ...[
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],

                    // Message text
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isMine
                            ? Colors.white
                            : (isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Timestamp & Status row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormatter.formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMine
                                ? Colors.white.withValues(alpha: 0.7)
                                : (isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForegroundLight),
                          ),
                        ),
                        if (isMine && message.isSending) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        if (isMine && message.isFailed) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: message.isSending ? null : onRetry,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.refresh,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.95),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
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

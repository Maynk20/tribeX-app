import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/message.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isMine;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : otherBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine && message.sender != null) ...[
              Text(
                message.sender!.fullName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
            ],
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
            const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/chat_state.dart';

class PollCardWidget extends StatefulWidget {
  final String pollId;
  final String? currentUserId;

  const PollCardWidget({super.key, required this.pollId, this.currentUserId});

  @override
  State<PollCardWidget> createState() => _PollCardWidgetState();
}

class _PollCardWidgetState extends State<PollCardWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatState>().fetchPollIfNeeded(widget.pollId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PollCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pollId != oldWidget.pollId) {
      context.read<ChatState>().fetchPollIfNeeded(widget.pollId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatState>();
    final poll = chatState.getPoll(widget.pollId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (poll == null) return const SizedBox.shrink();

    final totalVotes = poll.totalVotes;
    final userVotedOptId = widget.currentUserId != null
        ? poll.userVotedOptionId(widget.currentUserId!)
        : null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalVotes ${totalVotes == 1 ? "vote" : "votes"} total',
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
            ],
          ),
          const SizedBox(height: 14),

          // Options
          ...poll.options.map((opt) {
            final isSelected = opt.id == userVotedOptId;
            final pct = totalVotes > 0 ? (opt.votes / totalVotes) : 0.0;

            return GestureDetector(
              onTap: () {
                if (widget.currentUserId != null) {
                  chatState.votePoll(poll.id, opt.id, widget.currentUserId!);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Progress fill
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark
                                  ? AppColors.mutedDark
                                  : AppColors.mutedLight),
                      ),
                    ),

                    // Label & percentage
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.mutedForegroundLight,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                opt.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(pct * 100).round()}% (${opt.votes})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

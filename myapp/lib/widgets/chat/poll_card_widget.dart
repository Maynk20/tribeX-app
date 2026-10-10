import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_toast.dart';
import '../../services/supabase_service.dart';
import '../../state/auth_state.dart';
import '../../state/chat_state.dart';

class PollCardWidget extends StatefulWidget {
  final String pollId;
  final String? currentUserId;

  const PollCardWidget({super.key, required this.pollId, this.currentUserId});

  @override
  State<PollCardWidget> createState() => _PollCardWidgetState();
}

class _PollCardWidgetState extends State<PollCardWidget> {
  String? _votingOptionId;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatState>().fetchPoll(widget.pollId);
      }
    });

    // Periodic sync only when no option is in-flight
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _votingOptionId == null) {
        context.read<ChatState>().fetchPoll(widget.pollId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PollCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pollId != oldWidget.pollId) {
      context.read<ChatState>().fetchPoll(widget.pollId);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String? _resolveUserId([AuthState? authState]) {
    final clientUid = SupabaseService.client?.auth.currentUser?.id;
    if (clientUid != null && clientUid.trim().isNotEmpty) {
      return clientUid.trim().toLowerCase();
    }
    if (widget.currentUserId != null &&
        widget.currentUserId!.trim().isNotEmpty) {
      return widget.currentUserId!.trim().toLowerCase();
    }
    final authUser = authState?.currentUser;
    if (authUser != null && authUser.id.trim().isNotEmpty) {
      return authUser.id.trim().toLowerCase();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatState>();
    AuthState? authState;
    try {
      authState = Provider.of<AuthState>(context);
    } catch (_) {
      authState = null;
    }
    final poll = chatState.getPoll(widget.pollId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (poll == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading poll details…',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<ChatState>().fetchPoll(widget.pollId);
              },
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final totalVotes = poll.totalVotes;
    final effectiveUserId = _resolveUserId(authState);
    final userVotedOptId = effectiveUserId != null
        ? poll.userVotedOptionId(effectiveUserId)
        : null;
    final isClosed = poll.isClosed;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    Row(
                      children: [
                        const Text(
                          'GROUP POLL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                        if (isClosed) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Closed',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      poll.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
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

            final isThisOptionVoting = _votingOptionId == opt.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    if (isClosed) {
                      AppToast.show(context, 'This poll is closed');
                      return;
                    }
                    if (effectiveUserId == null) {
                      AppToast.show(
                        context,
                        'Please sign in to vote on this poll',
                        isError: true,
                      );
                      return;
                    }
                    if (isSelected) {
                      // Already picked this option; maintain vote
                      return;
                    }

                    unawaited(HapticFeedback.selectionClick());
                    setState(() {
                      _votingOptionId = opt.id;
                    });
                    try {
                      final ok = await chatState.votePoll(
                        poll.id,
                        opt.id,
                        effectiveUserId,
                      );
                      if (!context.mounted) return;
                      if (!ok) {
                        AppToast.show(
                          context,
                          'Could not record vote. Please retry.',
                          isError: true,
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      AppToast.show(
                        context,
                        'Error updating vote',
                        isError: true,
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _votingOptionId = null;
                        });
                      }
                    }
                  },
                  child: Container(
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
                        // Animated progress fill
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            color: isSelected
                                ? AppColors.primary.withValues(
                                    alpha: isDark ? 0.25 : 0.16,
                                  )
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
                                if (isThisOptionVoting)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                else
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.mutedForegroundDark
                                              : AppColors.mutedForegroundLight),
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
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.white
                                                : AppColors.primary)
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(pct * 100).round()}% (${opt.votes})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
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
                ),
              ),
            );
          }),

          // Footer (matches TanStack: `{total} votes · tap to change pick`)
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$totalVotes ${totalVotes == 1 ? "vote" : "votes"} · tap option to vote or switch',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              if (_votingOptionId != null) ...[
                const Spacer(),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

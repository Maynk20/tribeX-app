import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/join_request.dart';
import '../../state/activities_state.dart';

class ManageRequestsModal extends StatelessWidget {
  final String activityId;
  final String activityTitle;

  const ManageRequestsModal({
    super.key,
    required this.activityId,
    required this.activityTitle,
  });

  static void show(
    BuildContext context, {
    required String activityId,
    required String activityTitle,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => ManageRequestsModal(
        activityId: activityId,
        activityTitle: activityTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActivitiesState>();
    final requests = state.getRequestsForActivity(activityId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final pendingCount = requests
        .where((r) => r.status == JoinStatus.pending)
        .length;
    final acceptedCount = requests
        .where((r) => r.status == JoinStatus.accepted)
        .length;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage joiners',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activityTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$pendingCount pending · $acceptedCount joined',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Request List
            Flexible(
              child: requests.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No join requests or attendees yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final req = requests[idx];
                        return _AttendeeRow(req: req);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendeeRow extends StatefulWidget {
  final JoinRequest req;

  const _AttendeeRow({required this.req});

  @override
  State<_AttendeeRow> createState() => _AttendeeRowState();
}

class _AttendeeRowState extends State<_AttendeeRow> {
  bool _isProcessing = false;
  String? _processingAction; // 'accept', 'decline', 'remove'

  Future<void> _handleAction(String action, Future<bool> Function() actionFn) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _processingAction = action;
    });

    try {
      await actionFn();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingAction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<ActivitiesState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.backgroundDark : AppColors.mutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final user = widget.req.user;
    final name = user?.fullName ?? user?.username ?? "Squad Mate";
    final isAccepted = widget.req.status == JoinStatus.accepted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryMuted,
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user?.isVerified ?? false) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 11,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${user?.rating.toStringAsFixed(1) ?? '5.0'} rating',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '⭐ ${user?.reliabilityLabel ?? '100% Reliable'}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user?.city != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.mutedForegroundLight,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              user!.city!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? AppColors.successMuted
                      : AppColors.warningMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAccepted ? 'JOINED' : 'PENDING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isAccepted ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isAccepted) ...[
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleAction(
                            'decline',
                            () => state.respondToRequest(
                              widget.req.id,
                              JoinStatus.rejected,
                            ),
                          ),
                  icon: _isProcessing && _processingAction == 'decline'
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.destructive,
                          ),
                        )
                      : const Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.destructive,
                        ),
                  label: const Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.destructive,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.destructive.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleAction(
                            'accept',
                            () => state.respondToRequest(
                              widget.req.id,
                              JoinStatus.accepted,
                            ),
                          ),
                  icon: _isProcessing && _processingAction == 'accept'
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 14),
                  label: const Text('Accept', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleAction(
                            'remove',
                            () => state.removeAttendee(widget.req.id),
                          ),
                  icon: _isProcessing && _processingAction == 'remove'
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.destructive,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: AppColors.destructive,
                        ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.destructive,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.destructive.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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

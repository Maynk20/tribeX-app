import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/activity.dart';
import '../../models/join_request.dart';
import '../../services/location_service.dart';
import '../../state/activities_state.dart';

class CheckInPanel extends StatefulWidget {
  final Activity activity;
  final bool isHost;
  final JoinRequest? myRequest;

  const CheckInPanel({
    super.key,
    required this.activity,
    required this.isHost,
    this.myRequest,
  });

  @override
  State<CheckInPanel> createState() => _CheckInPanelState();
}

class _CheckInPanelState extends State<CheckInPanel> {
  bool _isCheckingIn = false;

  Future<void> _performCheckIn() async {
    if (_isCheckingIn) return;
    setState(() => _isCheckingIn = true);

    // 1. Get real GPS coordinates
    final locResult = await LocationService.getCurrentPosition();

    if (!mounted) return;

    if (!locResult.isSuccess) {
      setState(() => _isCheckingIn = false);
      if (!mounted) return;
      AppToast.show(
        context,
        locResult.error ?? 'Could not get your location.',
        isError: true,
      );
      return;
    }

    // 2. Call the RPC with real coordinates
    final state = context.read<ActivitiesState>();
    final result = await state.checkInAtVenue(
      activityId: widget.activity.id,
      lat: locResult.latitude!,
      lon: locResult.longitude!,
    );

    if (!mounted) return;
    setState(() => _isCheckingIn = false);

    if (!mounted) return;

    // 3. Show result based on backend response
    if (result.isSuccess) {
      AppToast.show(context, '✅ Checked in · Verified present at venue');
    } else if (result.isAlready) {
      AppToast.show(context, 'You have already checked in.');
    } else if (result.isTooFar) {
      final dist = result.distanceM?.round() ?? 0;
      AppToast.show(
        context,
        'You are ${dist}m away — must be within 150m of the venue.',
        isError: true,
      );
    } else {
      // Error from backend
      final msg = result.errorMessage ?? 'Check-in failed. Please try again.';
      // Extract user-friendly message from Supabase exception
      final friendly = _extractFriendlyMessage(msg);
      AppToast.show(context, friendly, isError: true);
    }
  }

  String _extractFriendlyMessage(String raw) {
    // Supabase exceptions often wrap the PG error as:
    // "PostgrestException(message: ..., ...)"
    final match = RegExp(r'message:\s*(.+?)(?:,|\))').firstMatch(raw);
    if (match != null) {
      return match.group(1)!.trim();
    }
    // Or "Exception: <message>"
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return 'Check-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActivitiesState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final attendees = state.getRequestsForActivity(widget.activity.id);

    if (widget.activity.isOnline) {
      return _buildVirtualMeetingPanel(
        context,
        attendees,
        isDark,
        cardBg,
        border,
      );
    }

    final isCheckedIn = widget.myRequest?.isCheckedIn ?? false;
    final hasPin =
        widget.activity.latitude != null && widget.activity.longitude != null;

    if (!hasPin && !widget.isHost) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'VENUE CHECK-IN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      !hasPin
                          ? "Host hasn't pinned the venue coordinates yet."
                          : isCheckedIn
                          ? "You're verified as present. Enjoy the plan!"
                          : "Tap check-in when you arrive (must be within 150m).",
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
              if (!widget.isHost &&
                  widget.myRequest != null &&
                  !isCheckedIn &&
                  hasPin)
                ElevatedButton.icon(
                  onPressed: _isCheckingIn ? null : _performCheckIn,
                  icon: _isCheckingIn
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.pin_drop, size: 14),
                  label: Text(
                    _isCheckingIn ? 'Verifying…' : 'Check in',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                )
              else if (!widget.isHost && isCheckedIn)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Host Roster List
          if (widget.isHost && attendees.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: border),
            const SizedBox(height: 8),
            Text(
              'ATTENDEE ROSTER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 6),
            ...attendees.map((req) {
              final user = req.user;
              final name = user?.fullName ?? user?.username ?? "Player";
              final verified = req.isCheckedIn;
              final noShow = req.noShow;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.mutedLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primaryMuted,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 10,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (noShow)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.destructiveMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No-show',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.destructive,
                          ),
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.mutedDark : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          state.markAttendeeNoShow(req.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.destructive.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'No-show',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.destructive,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildVirtualMeetingPanel(
    BuildContext context,
    List<JoinRequest> attendees,
    bool isDark,
    Color cardBg,
    Color border,
  ) {
    final state = context.read<ActivitiesState>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.successMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.video,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VIRTUAL MEETING HUB',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.activity.location.trim().isNotEmpty &&
                              widget.activity.location.trim() != 'Online'
                          ? widget.activity.location.trim()
                          : 'Online Video Call',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ONLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Join Meeting & Copy Link Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final link = widget.activity.meetingLink?.trim().isNotEmpty ==
                              true
                          ? widget.activity.meetingLink!.trim()
                          : await state.fetchMeetingLink(widget.activity.id);

                      if (link != null && link.isNotEmpty) {
                        final uri = Uri.tryParse(link);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          return;
                        }
                        await Clipboard.setData(ClipboardData(text: link));
                        if (context.mounted) {
                          AppToast.show(
                            context,
                            'Meeting link copied to clipboard: $link',
                          );
                        }
                      } else {
                        if (context.mounted) {
                          AppToast.show(
                            context,
                            'Meeting link will be shared by host shortly.',
                            isError: true,
                          );
                        }
                      }
                    } catch (_) {
                      if (context.mounted) {
                        AppToast.show(
                          context,
                          'Could not open meeting link',
                          isError: true,
                        );
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.video, size: 14),
                  label: const Text(
                    'Join Meeting',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final link = widget.activity.meetingLink?.trim().isNotEmpty ==
                            true
                        ? widget.activity.meetingLink!.trim()
                        : await state.fetchMeetingLink(widget.activity.id);
                    if (link != null && link.isNotEmpty) {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (context.mounted) {
                        AppToast.show(context, 'Link copied to clipboard!');
                      }
                    } else if (context.mounted) {
                      AppToast.show(
                        context,
                        'No meeting link available yet',
                        isError: true,
                      );
                    }
                  } catch (_) {}
                },
                icon: const Icon(LucideIcons.copy, size: 13),
                label: const Text('Copy', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Attendees in Virtual Squad
          Row(
            children: [
              Icon(
                LucideIcons.users,
                size: 12,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              const SizedBox(width: 4),
              Text(
                'Squad Members (${attendees.where((r) => r.status.name == 'accepted').length + 1})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

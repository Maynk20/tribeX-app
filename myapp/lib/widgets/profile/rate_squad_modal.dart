import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/activity.dart';
import '../../models/rating_item.dart';
import '../../models/user_profile.dart';
import '../../state/activities_state.dart';
import '../../state/auth_state.dart';
import '../../state/chat_state.dart';

class RateSquadModal extends StatefulWidget {
  final Activity activity;

  const RateSquadModal({super.key, required this.activity});

  static void show(BuildContext context, {required Activity activity}) {
    showDialog(
      context: context,
      builder: (ctx) => RateSquadModal(activity: activity),
    );
  }

  @override
  State<RateSquadModal> createState() => _RateSquadModalState();
}

class _RateSquadModalState extends State<RateSquadModal> {
  final Map<String, int> _ratings = {};
  final Map<String, List<String>> _badges = {};
  final Map<String, TextEditingController> _comments = {};

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actState = context.watch<ActivitiesState>();
    final authState = context.watch<AuthState>();
    final chatState = context.watch<ChatState>();
    final me = authState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Collect rateable people: host (if not me) + accepted attendees (if not me)
    final people = <UserProfile>[];
    if (widget.activity.host != null && widget.activity.host!.id != me?.id) {
      people.add(widget.activity.host!);
    }

    final requests = actState.getRequestsForActivity(widget.activity.id);
    for (final req in requests) {
      if (req.user != null &&
          req.user!.id != me?.id &&
          req.status.name == 'accepted') {
        if (!people.any((p) => p.id == req.user!.id)) {
          people.add(req.user!);
        }
      }
    }

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rate your squad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.activity.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // People List
            Flexible(
              child: people.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'No other participants to rate for this plan.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: people.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (ctx, idx) {
                        final person = people[idx];
                        final isHost = person.id == widget.activity.hostId;
                        final currentRating = _ratings[person.id] ?? 0;
                        final currentBadges = _badges[person.id] ?? [];
                        final commentCtrl = _comments.putIfAbsent(
                          person.id,
                          () => TextEditingController(),
                        );
                        final existing = me != null
                            ? chatState.getMyRating(
                                widget.activity.id,
                                me.id,
                                person.id,
                              )
                            : null;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : AppColors.mutedLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primaryMuted,
                                    backgroundImage: person.avatarUrl != null
                                        ? NetworkImage(person.avatarUrl!)
                                        : null,
                                    child: person.avatarUrl == null
                                        ? Text(
                                            person.fullName.isNotEmpty
                                                ? person.fullName[0]
                                                      .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          person.fullName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          isHost ? 'Host' : 'Attendee',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.mutedForegroundDark
                                                : AppColors
                                                      .mutedForegroundLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (existing != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successMuted,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check,
                                            size: 10,
                                            color: AppColors.success,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Submitted',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Stars
                              Row(
                                children: List.generate(5, (starIdx) {
                                  final starVal = starIdx + 1;
                                  final isFilled =
                                      starVal <=
                                      (currentRating > 0
                                          ? currentRating
                                          : (existing?.rating ?? 0));
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _ratings[person.id] = starVal;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.star,
                                        size: 26,
                                        color: isFilled
                                            ? AppColors.warning
                                            : AppColors.mutedForegroundLight
                                                  .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 10),

                              // Badges
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: RatingBadges.all.map((b) {
                                  final isSelected = currentBadges.contains(
                                    b.key,
                                  );
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        final list = List<String>.from(
                                          currentBadges,
                                        );
                                        if (isSelected) {
                                          list.remove(b.key);
                                        } else {
                                          list.add(b.key);
                                        }
                                        _badges[person.id] = list;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryMuted
                                            : (isDark
                                                  ? AppColors.cardDark
                                                  : Colors.white),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            b.emoji,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            b.label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : (isDark
                                                        ? AppColors
                                                              .foregroundDark
                                                        : AppColors
                                                              .foregroundLight),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),

                              // Comment
                              TextField(
                                controller: commentCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Optional note (private to them)…',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 10),

                              // Submit single button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      (currentRating > 0 ||
                                          (existing != null &&
                                              currentRating > 0))
                                      ? () {
                                          if (me != null) {
                                            chatState.submitRating(
                                              RatingItem(
                                                id: "rat_${DateTime.now().millisecondsSinceEpoch}",
                                                planId: widget.activity.id,
                                                reviewerId: me.id,
                                                revieweeId: person.id,
                                                rating: currentRating > 0
                                                    ? currentRating
                                                    : (existing?.rating ?? 5),
                                                badges: currentBadges,
                                                comment: commentCtrl.text
                                                    .trim(),
                                                createdAt: DateTime.now(),
                                              ),
                                            );
                                            AppToast.show(
                                              context,
                                              'Rating saved for ${person.fullName}!',
                                            );
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    existing != null
                                        ? 'Update Rating'
                                        : 'Submit Rating',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../models/activity.dart';
import '../models/join_request.dart';
import '../state/activities_state.dart';
import '../state/auth_state.dart';
import '../state/chat_state.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _query = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChats();
    });
  }

  Future<void> _loadChats() async {
    final authState = context.read<AuthState>();
    final user = authState.currentUser;
    if (user != null) {
      await context.read<ChatState>().fetchUserChats(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actState = context.watch<ActivitiesState>();
    final authState = context.watch<AuthState>();
    final chatState = context.watch<ChatState>();
    final user = authState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Your squad chats',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to see messages from plans you host or joined.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User's active chats (plans hosted or joined across all locations)
    final chatStateChats = chatState.userChats;
    final Set<String> knownIds = chatStateChats.map((a) => a.id).toSet();

    final myJoinedIds = actState.joinRequests
        .where((r) => r.userId == user.id && r.status == JoinStatus.accepted)
        .map((r) => r.activityId)
        .toSet();

    final allUserActivities = <Activity>[...chatStateChats];
    for (final a in actState.activities) {
      if (!knownIds.contains(a.id) &&
          (a.hostId == user.id || myJoinedIds.contains(a.id))) {
        allUserActivities.add(a);
        knownIds.add(a.id);
      }
    }

    final q = _query.trim().toLowerCase();
    final myChats = allUserActivities.where((a) {
      if (q.isEmpty) return true;
      return a.title.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q) ||
          a.category.toLowerCase().contains(q);
    }).toList();

    // Sort by latest message timestamp (or event dateTime fallback) descending
    myChats.sort((a, b) {
      final msgsA = chatState.getMessagesForActivity(a.id);
      final msgsB = chatState.getMessagesForActivity(b.id);
      final timeA = msgsA.isNotEmpty ? msgsA.last.createdAt : a.dateTime;
      final timeB = msgsB.isNotEmpty ? msgsB.last.createdAt : b.dateTime;
      return timeB.compareTo(timeA);
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching TanStack: p.uppercase tracking-[0.18em] + h1 text-3xl font-bold
              Text(
                'INBOX',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Messages',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
              const SizedBox(height: 16),

              // Search bar: rounded-2xl border border-border/60 bg-card px-4 py-3
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border.withValues(alpha: 0.6)),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _query = val),
                  decoration: const InputDecoration(
                    hintText: 'Search chats',
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.mutedForegroundLight,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chat List: flat list with border-b separator as in TanStack
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadChats,
                  color: AppColors.primary,
                  child: chatState.isLoadingUserChats && myChats.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : myChats.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: cardBg.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: border.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.messageCircle,
                                      size: 36,
                                      color: isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No chats yet.\nJoin or host a plan to start a squad chat.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
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
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: myChats.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: border.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (ctx, idx) {
                            final chat = myChats[idx];
                            final msgs = chatState.getMessagesForActivity(
                              chat.id,
                            );
                            final hasMsgs = msgs.isNotEmpty;
                            final lastMsg = hasMsgs ? msgs.last : null;

                            String subtitleText = chat.isVirtual
                                ? '🌐 Virtual Event'
                                : '📍 ${chat.location}';
                            DateTime displayTime = chat.dateTime;

                            if (lastMsg != null) {
                              displayTime = lastMsg.createdAt;
                              if (lastMsg.isSystemEvent) {
                                subtitleText =
                                    '📢 ${lastMsg.systemDisplayText}';
                              } else if (lastMsg.expenseId != null ||
                                  lastMsg.text.startsWith('EXPENSE:')) {
                                subtitleText = '💰 Split expense request';
                              } else if (lastMsg.pollId != null ||
                                  lastMsg.text.startsWith('POLL:')) {
                                subtitleText = '📊 Group poll created';
                              } else {
                                final senderName =
                                    lastMsg.sender?.fullName.isNotEmpty == true
                                    ? lastMsg.sender!.fullName
                                    : (lastMsg.sender?.username.isNotEmpty ==
                                              true
                                          ? lastMsg.sender!.username
                                          : 'Squad Member');
                                if (lastMsg.senderId == user.id) {
                                  subtitleText = 'You: ${lastMsg.text}';
                                } else {
                                  subtitleText = '$senderName: ${lastMsg.text}';
                                }
                              }
                            }

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(activity: chat),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.mutedDark
                                            : AppColors.mutedLight,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        AppCategories.emojiFor(chat.category),
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        chat.title,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? AppColors
                                                                    .foregroundDark
                                                              : AppColors
                                                                    .foregroundLight,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4.5,
                                                            vertical: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: chat.isVirtual
                                                            ? AppColors
                                                                  .primaryMuted
                                                            : (isDark
                                                                  ? AppColors
                                                                        .mutedDark
                                                                  : AppColors
                                                                        .mutedLight),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        chat.isVirtual
                                                            ? 'Virtual'
                                                            : 'In-Person',
                                                        style: TextStyle(
                                                          fontSize: 8.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: chat.isVirtual
                                                              ? AppColors
                                                                    .primary
                                                              : (isDark
                                                                    ? AppColors
                                                                          .mutedForegroundDark
                                                                    : AppColors
                                                                          .mutedForegroundLight),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                DateFormatter.formatChatDate(
                                                  displayTime,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? AppColors
                                                            .mutedForegroundDark
                                                      : AppColors
                                                            .mutedForegroundLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitleText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: hasMsgs
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                              color: isDark
                                                  ? (hasMsgs
                                                        ? AppColors
                                                              .foregroundDark
                                                              .withValues(
                                                                alpha: 0.85,
                                                              )
                                                        : AppColors
                                                              .mutedForegroundDark)
                                                  : (hasMsgs
                                                        ? AppColors
                                                              .foregroundLight
                                                              .withValues(
                                                                alpha: 0.85,
                                                              )
                                                        : AppColors
                                                              .mutedForegroundLight),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

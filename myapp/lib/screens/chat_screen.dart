import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_toast.dart';
import '../core/utils/date_formatter.dart';
import '../models/activity.dart';
import '../state/activities_state.dart';
import '../state/auth_state.dart';
import '../state/chat_state.dart';
import '../widgets/chat/check_in_panel.dart';
import '../widgets/chat/create_poll_modal.dart';
import '../widgets/chat/expense_card_widget.dart';
import '../widgets/chat/memory_banner_widget.dart';
import '../widgets/chat/message_bubble_widget.dart';
import '../widgets/chat/poll_card_widget.dart';
import '../widgets/chat/split_expense_modal.dart';
import '../widgets/common/report_modal.dart';

class ChatScreen extends StatefulWidget {
  final Activity activity;

  const ChatScreen({super.key, required this.activity});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _attachMenuOpen = false;

  late ChatState _chatState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatState>().fetchMessagesForActivity(widget.activity.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatState = context.read<ChatState>();
  }

  @override
  void dispose() {
    _chatState.unsubscribeFromActivityChat(widget.activity.id);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthState>();
    final me = authState.currentUser;

    if (me != null) {
      context.read<ChatState>().sendMessage(
        activityId: widget.activity.id,
        senderId: me.id,
        text: text,
        sender: me,
      );
      _msgCtrl.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actState = context.watch<ActivitiesState>();
    final authState = context.watch<AuthState>();
    final chatState = context.watch<ChatState>();
    final me = authState.currentUser;
    final messages = chatState.getMessagesForActivity(widget.activity.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final isHost = me != null && widget.activity.hostId == me.id;
    final myReq = me != null
        ? actState.getMyRequest(widget.activity.id, me.id)
        : null;
    final host = widget.activity.host;
    final hostName = host?.fullName ?? host?.username ?? "Host";

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                AppCategories.emojiFor(widget.activity.category),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activity.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Host · $hostName · ${DateFormatter.formatTime(widget.activity.dateTime)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isHost && host != null)
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, size: 20),
              tooltip: 'Block host',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Block $hostName?'),
                    content: const Text(
                      "You won't see their events anymore in your feed.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          authState.blockUser(host.id);
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                          AppToast.show(context, 'Host blocked');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.destructive,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Block'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: border),
        ),
      ),
      body: Column(
        children: [
          // Messages and Panels List
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CheckInPanel(
                    activity: widget.activity,
                    isHost: isHost,
                    myRequest: myReq,
                  );
                }
                if (index == 1) {
                  return MemoryBannerWidget(
                    activity: widget.activity,
                    canUpload: isHost || myReq?.status.name == 'accepted',
                  );
                }

                final m = messages[index - 2];
                final expId = m.expenseId;
                if (expId != null) {
                  return RepaintBoundary(
                    key: ValueKey('exp_$expId'),
                    child: ExpenseCardWidget(
                      expenseId: expId,
                      currentUserId: me?.id,
                    ),
                  );
                }

                final pollId = m.pollId;
                if (pollId != null) {
                  return RepaintBoundary(
                    key: ValueKey('poll_$pollId'),
                    child: PollCardWidget(
                      pollId: pollId,
                      currentUserId: me?.id,
                    ),
                  );
                }

                final isMine = me != null && m.senderId == me.id;
                return RepaintBoundary(
                  key: ValueKey('msg_${m.id}'),
                  child: MessageBubbleWidget(
                    message: m,
                    isMine: isMine,
                    onReport: () {
                      ReportModal.show(
                        context,
                        targetType: 'chat_message',
                        targetId: m.id,
                        targetTitle:
                            'Message from ${m.sender?.fullName ?? "user"}',
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Attachments Popover Menu (if open)
          if (_attachMenuOpen)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _attachMenuOpen = false);
                        SplitExpenseModal.show(
                          context,
                          activityId: widget.activity.id,
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.successMuted,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.currency_rupee,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Split expense',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'UPI bill split',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mutedForegroundLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: border),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _attachMenuOpen = false);
                        CreatePollModal.show(
                          context,
                          activityId: widget.activity.id,
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
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
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create poll',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Group decision',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mutedForegroundLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              border: Border(top: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _attachMenuOpen ? Icons.close : Icons.add,
                    size: 22,
                    color: _attachMenuOpen ? AppColors.primary : null,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: cardBg,
                    side: BorderSide(color: border),
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () {
                    setState(() => _attachMenuOpen = !_attachMenuOpen);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: border),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message $hostName…',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, size: 18, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_toast.dart';
import '../core/utils/date_formatter.dart';
import '../models/activity.dart';
import '../state/auth_state.dart';
import '../state/chat_state.dart';
import '../state/notifications_state.dart';
import '../widgets/chat/create_poll_modal.dart';
import '../widgets/chat/expense_card_widget.dart';
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
  late NotificationsState _notificationsState;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chatState = context.read<ChatState>();
        chatState.setActiveChat(widget.activity.id);
        context
            .read<NotificationsState>()
            .setActiveChatActivityId(widget.activity.id);
        chatState.fetchMessagesForActivity(widget.activity.id);
        chatState.fetchSquadMembers(widget.activity.id);
      }
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels <= 80) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    final chatState = context.read<ChatState>();
    if (!chatState.hasMoreOlderMessages(widget.activity.id) ||
        chatState.isLoadingOlder(widget.activity.id)) {
      return;
    }

    final oldMaxScroll = _scrollCtrl.position.maxScrollExtent;
    final oldPixels = _scrollCtrl.position.pixels;

    await chatState.fetchOlderMessagesForActivity(widget.activity.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final newMaxScroll = _scrollCtrl.position.maxScrollExtent;
        final delta = newMaxScroll - oldMaxScroll;
        if (delta > 0) {
          _scrollCtrl.jumpTo(oldPixels + delta);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatState = context.read<ChatState>();
    _notificationsState = context.read<NotificationsState>();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _chatState.setActiveChat(null);
    _notificationsState.setActiveChatActivityId(null);
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

  void _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthState>();
    final me = authState.currentUser;

    if (me != null) {
      _msgCtrl.clear();
      _scrollToBottom();
      final success = await context.read<ChatState>().sendMessage(
        activityId: widget.activity.id,
        senderId: me.id,
        text: text,
        sender: me,
      );
      if (!success && mounted) {
        AppToast.show(
          context,
          'Failed to send message. Please retry.',
          isError: true,
        );
      }
    }
  }

  void _showVirtualMeetingDetails(BuildContext context, String hostName) {
    final link = widget.activity.meetingLink?.trim();
    final hasLink = link != null && link.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Virtual Meeting Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Host: $hostName · Online Event',
                        style: TextStyle(
                          fontSize: 12,
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
            const SizedBox(height: 16),
            if (hasLink) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.mutedLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: SelectableText(
                  link,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Meeting Link'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    Navigator.of(ctx).pop();
                    AppToast.show(context, 'Meeting link copied to clipboard!');
                  },
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.mutedLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'The host has not posted the meeting link yet.\nYou can ask them directly in this squad chat!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final chatState = context.watch<ChatState>();
    final me = authState.currentUser;
    final messages = chatState.getMessagesForActivity(widget.activity.id);
    final hasMore = chatState.hasMoreOlderMessages(widget.activity.id);
    final isLoadingOlder = chatState.isLoadingOlder(widget.activity.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final isHost = me != null && widget.activity.hostId == me.id;
    final host = widget.activity.host;
    final hostName = host?.fullName ?? host?.username ?? "Host";

    final isVirtual = widget.activity.isVirtual;

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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.activity.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isVirtual
                              ? AppColors.primaryMuted
                              : (isDark
                                    ? AppColors.mutedDark
                                    : AppColors.mutedLight),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isVirtual ? '🌐 Virtual' : '📍 In-Person',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isVirtual
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForegroundLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isVirtual
                        ? 'Host · $hostName · ${DateFormatter.formatTime(widget.activity.dateTime)}'
                        : '${widget.activity.location} · Host: $hostName',
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
          if (isVirtual)
            IconButton(
              icon: const Icon(
                Icons.videocam_outlined,
                size: 22,
                color: AppColors.primary,
              ),
              tooltip: 'Meeting details',
              onPressed: () => _showVirtualMeetingDetails(context, hostName),
            ),
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
              itemCount:
                  messages.isEmpty ? 1 : messages.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (messages.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 32,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to say hi to the squad!',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (hasMore && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: isLoadingOlder
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : TextButton.icon(
                              onPressed: _loadOlderMessages,
                              icon: const Icon(Icons.arrow_upward, size: 14),
                              label: const Text(
                                'Load earlier messages',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  );
                }

                final msgIndex = hasMore ? index - 1 : index;
                final m = messages[msgIndex];

                final isFirstMsgOfDay =
                    msgIndex == 0 ||
                    !DateFormatter.isSameDay(
                      messages[msgIndex - 1].createdAt,
                      m.createdAt,
                    );

                final showSenderInfo =
                    msgIndex == 0 ||
                    messages[msgIndex - 1].senderId != m.senderId ||
                    isFirstMsgOfDay ||
                    messages[msgIndex - 1].isSystemEvent ||
                    messages[msgIndex - 1].expenseId != null ||
                    messages[msgIndex - 1].pollId != null;

                final expId = m.expenseId;
                final pollId = m.pollId;
                final isMine = me != null && m.senderId == me.id;

                Widget contentWidget;
                if (expId != null) {
                  contentWidget = RepaintBoundary(
                    key: ValueKey('exp_$expId'),
                    child: ExpenseCardWidget(
                      expenseId: expId,
                      currentUserId: me?.id,
                    ),
                  );
                } else if (pollId != null) {
                  contentWidget = RepaintBoundary(
                    key: ValueKey('poll_$pollId'),
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        PollCardWidget(
                          pollId: pollId,
                          currentUserId: me?.id,
                        ),
                        if (m.isFailed)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4,
                              right: 8,
                              bottom: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: AppColors.destructive,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Poll message failed to post · ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.destructive,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => chatState.retrySendMessage(m),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  contentWidget = RepaintBoundary(
                    key: ValueKey('msg_${m.id}'),
                    child: MessageBubbleWidget(
                      message: m,
                      isMine: isMine,
                      showSenderInfo: showSenderInfo,
                      onReport: () {
                        ReportModal.show(
                          context,
                          targetType: 'chat_message',
                          targetId: m.id,
                          targetTitle:
                              'Message from ${m.sender?.fullName ?? "user"}',
                        );
                      },
                      onRetry: () async {
                        final success = await context
                            .read<ChatState>()
                            .retrySendMessage(m);
                        if (!success && context.mounted) {
                          AppToast.show(
                            context,
                            'Failed to resend message. Check your connection.',
                            isError: true,
                          );
                        }
                      },
                    ),
                  );
                }

                if (isFirstMsgOfDay) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.mutedDark.withValues(alpha: 0.8)
                                  : AppColors.mutedLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: border.withValues(alpha: 0.6),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              DateFormatter.formatDateSeparator(m.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      contentWidget,
                    ],
                  );
                }

                return contentWidget;
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

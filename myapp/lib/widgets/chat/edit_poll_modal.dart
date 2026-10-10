import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/poll.dart';
import '../../state/chat_state.dart';

class EditPollModal extends StatefulWidget {
  final Poll poll;
  final String? currentUserId;

  const EditPollModal({super.key, required this.poll, this.currentUserId});

  static void show(
    BuildContext context, {
    required Poll poll,
    String? currentUserId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditPollModal(poll: poll, currentUserId: currentUserId),
    );
  }

  @override
  State<EditPollModal> createState() => _EditPollModalState();
}

class _EditPollModalState extends State<EditPollModal> {
  late final TextEditingController _questionCtrl;
  late final List<TextEditingController> _optionCtrls;
  late bool _isClosed;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.poll.question);
    _optionCtrls = widget.poll.options
        .map((opt) => TextEditingController(text: opt.text))
        .toList();
    _isClosed = widget.poll.isClosed;
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasVotes => widget.poll.totalVotes > 0;

  void _addOption() {
    if (_optionCtrls.length < 8 && !_hasVotes) {
      setState(() {
        _optionCtrls.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionCtrls.length > 2 && !_hasVotes) {
      setState(() {
        final c = _optionCtrls.removeAt(index);
        c.dispose();
      });
    }
  }

  Future<void> _submitSave() async {
    if (_isSubmitting) return;

    final q = _questionCtrl.text.trim();
    if (q.length < 2) {
      AppToast.show(context, 'Question must be at least 2 characters', isError: true);
      return;
    }

    final opts = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (opts.length < 2) {
      AppToast.show(context, 'Poll requires at least 2 options', isError: true);
      return;
    }

    final uniqueOpts = <String>{};
    for (final opt in opts) {
      if (!uniqueOpts.add(opt.toLowerCase())) {
        AppToast.show(context, 'Poll options must be distinct', isError: true);
        return;
      }
    }

    final chatState = context.read<ChatState>();
    final creatorId = widget.currentUserId ?? widget.poll.creatorId;

    setState(() => _isSubmitting = true);

    try {
      // 1. Update question & options
      final updateSuccess = await chatState.updatePoll(
        pollId: widget.poll.id,
        creatorId: creatorId,
        question: q,
        optionTexts: _hasVotes ? null : opts,
      );

      // 2. Update closed status if toggled
      if (widget.poll.isClosed != _isClosed) {
        await chatState.togglePollClosed(
          pollId: widget.poll.id,
          creatorId: creatorId,
          close: _isClosed,
        );
      }

      if (!mounted) return;
      if (updateSuccess) {
        Navigator.of(context).pop();
        AppToast.show(context, 'Poll updated successfully');
      } else {
        AppToast.show(context, 'Failed to update poll. Please retry.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Error updating poll', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Poll?'),
        content: const Text(
          'Are you sure you want to delete this poll? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final chatState = context.read<ChatState>();
    final creatorId = widget.currentUserId ?? widget.poll.creatorId;

    setState(() => _isSubmitting = true);
    try {
      final success = await chatState.deletePoll(
        pollId: widget.poll.id,
        creatorId: creatorId,
        activityId: widget.poll.activityId,
      );

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
        AppToast.show(context, 'Poll deleted');
      } else {
        AppToast.show(context, 'Failed to delete poll', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: border),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Manage Poll',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
                  tooltip: 'Delete Poll',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question field
            TextField(
              controller: _questionCtrl,
              decoration: const InputDecoration(
                labelText: 'Poll Question',
                prefixIcon: Icon(Icons.edit_note, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Voting status toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
              child: Row(
                children: [
                  Icon(
                    _isClosed ? Icons.lock : Icons.lock_open,
                    size: 18,
                    color: _isClosed ? AppColors.warning : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isClosed ? 'Poll is Closed' : 'Poll is Open for Voting',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _isClosed
                              ? 'Participants cannot cast or change votes'
                              : 'Participants can freely cast and switch votes',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: !_isClosed,
                    onChanged: (open) {
                      setState(() => _isClosed = !open);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Options Header
            Row(
              children: [
                Text(
                  'OPTIONS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                if (_hasVotes) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.poll.totalVotes} votes cast',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_hasVotes)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Votes have already been cast. Option order is locked to preserve member votes.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              )
            else
              const SizedBox(height: 8),

            ..._optionCtrls.asMap().entries.map((e) {
              final idx = e.key;
              final ctrl = e.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        readOnly: _hasVotes,
                        decoration: InputDecoration(
                          hintText: 'Option ${idx + 1}',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    if (!_hasVotes && _optionCtrls.length > 2) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => _removeOption(idx),
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          side: BorderSide(color: border),
                          padding: const EdgeInsets.all(6),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            if (!_hasVotes && _optionCtrls.length < 8)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add option'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Save changes button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSave,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

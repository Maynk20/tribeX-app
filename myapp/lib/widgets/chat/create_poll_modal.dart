import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/auth_state.dart';
import '../../state/chat_state.dart';

class CreatePollModal extends StatefulWidget {
  final String activityId;

  const CreatePollModal({super.key, required this.activityId});

  static void show(BuildContext context, {required String activityId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreatePollModal(activityId: activityId),
    );
  }

  @override
  State<CreatePollModal> createState() => _CreatePollModalState();
}

class _CreatePollModalState extends State<CreatePollModal> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length < 6) {
      setState(() {
        _optionCtrls.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionCtrls.length > 2) {
      setState(() {
        final c = _optionCtrls.removeAt(index);
        c.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final me = authState.currentUser;
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
            const Text(
              'Create a group poll',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Question
            TextField(
              controller: _questionCtrl,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'Preferred match time?',
                prefixIcon: Icon(Icons.help_outline, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Options List
            Text(
              'OPTIONS (2–6)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
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
                        decoration: InputDecoration(
                          hintText: 'Option ${idx + 1}',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    if (_optionCtrls.length > 2) ...[
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

            if (_optionCtrls.length < 6)
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

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final q = _questionCtrl.text.trim();
                  final opts = _optionCtrls
                      .map((c) => c.text.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  if (q.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a question')),
                    );
                    return;
                  }
                  if (opts.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add at least 2 options')),
                    );
                    return;
                  }

                  context.read<ChatState>().createPoll(
                    activityId: widget.activityId,
                    creatorId: me?.id ?? "host",
                    question: q,
                    optionTexts: opts,
                    creator: me,
                  );

                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Post poll'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

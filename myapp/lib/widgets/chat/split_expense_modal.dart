import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/expense.dart';
import '../../models/user_profile.dart';
import '../../state/activities_state.dart';
import '../../state/auth_state.dart';
import '../../state/chat_state.dart';

class SplitExpenseModal extends StatefulWidget {
  final String activityId;

  const SplitExpenseModal({super.key, required this.activityId});

  static void show(BuildContext context, {required String activityId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SplitExpenseModal(activityId: activityId),
    );
  }

  @override
  State<SplitExpenseModal> createState() => _SplitExpenseModalState();
}

class _SplitExpenseModalState extends State<SplitExpenseModal> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  String _splitType = "equal"; // 'equal' or 'specific'
  final Set<String> _selectedUserIds = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(
    List<ExpenseMember> effectiveMembers,
    double perHead,
    double total,
    UserProfile? me,
  ) async {
    if (_isSubmitting) return;

    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      AppToast.show(context, 'Please enter a description', isError: true);
      return;
    }
    if (total <= 0) {
      AppToast.show(context, 'Please enter a valid amount', isError: true);
      return;
    }
    if (effectiveMembers.isEmpty) {
      AppToast.show(
        context,
        'Please select at least one member',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final membersWithShare = effectiveMembers
          .map((m) => m.copyWith(amount: perHead))
          .toList();

      await context.read<ChatState>().createExpense(
        activityId: widget.activityId,
        creatorId: me?.id ?? "host",
        creatorName: me?.fullName ?? "Host",
        description: desc,
        totalAmount: total,
        upiId: _upiCtrl.text.trim().isNotEmpty ? _upiCtrl.text.trim() : null,
        members: membersWithShare,
        creator: me,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Failed to split expense', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actState = context.watch<ActivitiesState>();
    final authState = context.watch<AuthState>();
    final me = authState.currentUser;
    final requests = actState.getRequestsForActivity(widget.activityId);
    final confirmedRequests = requests
        .where((r) => r.status.name == 'accepted')
        .toList();

    // Include attendees and myself/host
    final allParticipants = <ExpenseMember>[];
    if (me != null) {
      allParticipants.add(
        ExpenseMember(
          userId: me.id,
          name: me.fullName,
          avatarUrl: me.avatarUrl,
          amount: 0,
          isPaid: true,
        ),
      );
    }
    for (final req in confirmedRequests) {
      if (req.user != null && req.user!.id != me?.id) {
        allParticipants.add(
          ExpenseMember(
            userId: req.user!.id,
            name: req.user!.fullName,
            avatarUrl: req.user!.avatarUrl,
            amount: 0,
            isPaid: false,
          ),
        );
      }
    }

    final total = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final effectiveMembers = _splitType == "equal"
        ? allParticipants
        : allParticipants
              .where((m) => _selectedUserIds.contains(m.userId))
              .toList();

    final perHead = effectiveMembers.isEmpty
        ? 0.0
        : total / effectiveMembers.length;

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
              'Split an expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Turf rent, Food & drinks…',
                prefixIcon: Icon(Icons.description_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Amount & UPI ID
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Total amount',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.currency_rupee, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _upiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID (optional)',
                      hintText: 'name@upi',
                      prefixIcon: Icon(Icons.qr_code, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Split Mode Toggle
            Row(
              children: [
                Expanded(
                  child: _SplitTypeButton(
                    label: 'Split equally',
                    isSelected: _splitType == "equal",
                    onTap: () => setState(() => _splitType = "equal"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SplitTypeButton(
                    label: 'Select members',
                    isSelected: _splitType == "specific",
                    onTap: () => setState(() => _splitType = "specific"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Member list container
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Members (${effectiveMembers.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                        if (perHead > 0)
                          Text(
                            '₹${perHead.toStringAsFixed(0)} / person',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: border),
                  ...allParticipants.map((m) {
                    final isChecked =
                        _splitType == "equal" ||
                        _selectedUserIds.contains(m.userId);
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: _splitType == "equal"
                          ? null
                          : (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUserIds.add(m.userId);
                                } else {
                                  _selectedUserIds.remove(m.userId);
                                }
                              });
                            },
                      title: Text(
                        m.userId == me?.id ? '${m.name} (you)' : m.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      secondary: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primaryMuted,
                        backgroundImage: m.avatarUrl != null
                            ? NetworkImage(m.avatarUrl!)
                            : null,
                        child: m.avatarUrl == null
                            ? Text(
                                m.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _submit(effectiveMembers, perHead, total, me),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Posting expense…'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 16),
                          SizedBox(width: 8),
                          Text('Post to chat'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SplitTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.backgroundDark : AppColors.mutedLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/expense.dart';
import '../../models/user_profile.dart';
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
  String? _payerId;
  List<ExpenseMember> _squadMembers = [];
  bool _isLoadingMembers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSquadMembers();
    });
  }

  Future<void> _loadSquadMembers() async {
    final chatState = context.read<ChatState>();
    final authState = context.read<AuthState>();
    final me = authState.currentUser;

    if (me != null && _payerId == null) {
      _payerId = me.id;
    }

    final cached = chatState.getSquadMembers(widget.activityId);
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _squadMembers = cached;
        _isLoadingMembers = false;
        if (_selectedUserIds.isEmpty) {
          _selectedUserIds.addAll(cached.map((m) => m.userId));
        }
      });
      return;
    }

    try {
      final members = await chatState.fetchSquadMembers(widget.activityId);
      if (mounted) {
        setState(() {
          _squadMembers = members;
          _isLoadingMembers = false;
          if (_selectedUserIds.isEmpty) {
            _selectedUserIds.addAll(members.map((m) => m.userId));
          }
          if (_payerId == null && members.isNotEmpty) {
            _payerId = me?.id ?? members.first.userId;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(
    List<ExpenseMember> calculatedShares,
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
    if (calculatedShares.isEmpty) {
      AppToast.show(
        context,
        'Please select at least one member',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await context.read<ChatState>().createExpense(
        activityId: widget.activityId,
        creatorId: _payerId ?? me?.id ?? "host",
        creatorName: me?.fullName ?? "Host",
        description: desc,
        totalAmount: total,
        upiId: _upiCtrl.text.trim().isNotEmpty ? _upiCtrl.text.trim() : null,
        members: calculatedShares,
        creator: me,
      );

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
      } else {
        AppToast.show(
          context,
          'Failed to split expense. Please try again.',
          isError: true,
        );
      }
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
    final authState = context.watch<AuthState>();
    final me = authState.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Filter participants based on equal or selective mode
    final participants = _splitType == "equal"
        ? _squadMembers
        : _squadMembers
              .where((m) => _selectedUserIds.contains(m.userId))
              .toList();

    final total = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final calculatedShares = Expense.calculateEqualSplit(
      participants: participants,
      totalAmount: total,
      payerId: _payerId ?? me?.id,
    );

    final perHead = participants.isEmpty ? 0.0 : total / participants.length;

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
                          'Squad Members (${participants.length}/${_squadMembers.length})',
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
                            '≈ ₹${perHead.toStringAsFixed(2)} / head',
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
                  if (_isLoadingMembers)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_squadMembers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No other squad members yet. You will be assigned the full amount.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _squadMembers.length,
                        itemBuilder: (ctx, idx) {
                          final m = _squadMembers[idx];
                          final isSelected =
                              _splitType == "equal" ||
                              _selectedUserIds.contains(m.userId);
                          final isPayer = m.userId == _payerId;

                          // Find calculated share if selected
                          final share = calculatedShares
                              .where((s) => s.userId == m.userId)
                              .firstOrNull;

                          return CheckboxListTile(
                            value: isSelected,
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
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.userId == me?.id
                                        ? '${m.name} (you)'
                                        : m.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isPayer
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPayer)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryMuted,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Payer',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: share != null && total > 0
                                ? Text(
                                    'Share: ₹${share.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                            secondary: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryMuted,
                              backgroundImage: m.avatarUrl != null
                                  ? NetworkImage(m.avatarUrl!)
                                  : null,
                              child: m.avatarUrl == null
                                  ? Text(
                                      m.name.isNotEmpty
                                          ? m.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          );
                        },
                      ),
                    ),
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
                    : () => _submit(calculatedShares, total, me),
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

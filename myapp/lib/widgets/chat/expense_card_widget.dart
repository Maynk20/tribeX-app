import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../state/chat_state.dart';

class ExpenseCardWidget extends StatefulWidget {
  final String expenseId;
  final String? currentUserId;

  const ExpenseCardWidget({
    super.key,
    required this.expenseId,
    this.currentUserId,
  });

  @override
  State<ExpenseCardWidget> createState() => _ExpenseCardWidgetState();
}

class _ExpenseCardWidgetState extends State<ExpenseCardWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatState>().fetchExpenseIfNeeded(widget.expenseId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ExpenseCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expenseId != oldWidget.expenseId) {
      context.read<ChatState>().fetchExpenseIfNeeded(widget.expenseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatState>();
    final expense = chatState.getExpense(widget.expenseId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (expense == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading expense details…',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<ChatState>().fetchExpense(widget.expenseId);
              },
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final paidCount = expense.paidCount;
    final totalCount = expense.members.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Created by ${expense.creatorName}',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paidCount == totalCount
                        ? AppColors.successMuted
                        : AppColors.warningMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$paidCount/$totalCount PAID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: paidCount == totalCount
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Participants Banner showing all names together ("saath saath mein")
          if (expense.members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.primaryMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Split between: ${expense.members.map((m) => m.userId == widget.currentUserId ? "${m.name} (you)" : m.name).join(" · ")}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Amount Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.mutedLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Bill',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${expense.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Per Person',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${expense.perHead.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Member List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROSTER (${expense.members.length})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(height: 6),
                ...expense.members.map((m) {
                  final isMe = m.userId == widget.currentUserId;
                  final isCreator = widget.currentUserId == expense.creatorId;
                  final isPayer = m.userId == expense.creatorId;
                  final canToggle = isCreator || isMe;

                  return InkWell(
                    onTap: () async {
                      if (!canToggle) {
                        AppToast.show(
                          context,
                          'Only the expense creator or this member can update payment status',
                        );
                        return;
                      }

                      final success = await chatState.toggleMemberPaid(
                        expense.id,
                        m.userId,
                      );
                      if (!success && context.mounted) {
                        AppToast.show(
                          context,
                          'Failed to update payment status. Please try again.',
                          isError: true,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
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
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isMe ? '${m.name} (you)' : m.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isMe || isPayer
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isPayer)
                                      Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryMuted,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'Payer',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  '₹${m.amount.toStringAsFixed(2)}',
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
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: m.isPaid
                                  ? AppColors.successMuted
                                  : (isDark
                                        ? AppColors.mutedDark
                                        : AppColors.mutedLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  m.isPaid
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 12,
                                  color: m.isPaid
                                      ? AppColors.success
                                      : AppColors.mutedForegroundLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  m.isPaid ? 'Paid' : 'Unpaid',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: m.isPaid
                                        ? AppColors.success
                                        : AppColors.mutedForegroundLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // UPI Pay button (if upi id present)
          if (expense.upiId != null) ...[
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Builder(
                builder: (ctx) {
                  final myShare = expense.members
                      .where((m) => m.userId == widget.currentUserId)
                      .firstOrNull;
                  final isAlreadyPaid = myShare?.isPaid ?? false;
                  final shareAmount = myShare != null
                      ? myShare.amount
                      : expense.perHead;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isAlreadyPaid
                          ? null
                          : () {
                              AppToast.show(
                                ctx,
                                'Opening UPI payment to ${expense.upiId} for ₹${shareAmount.toStringAsFixed(2)}',
                              );
                            },
                      icon: Icon(
                        isAlreadyPaid ? Icons.check : Icons.payment,
                        size: 16,
                      ),
                      label: Text(
                        isAlreadyPaid
                            ? 'Payment Completed (₹${shareAmount.toStringAsFixed(2)})'
                            : 'Pay ₹${shareAmount.toStringAsFixed(2)} via UPI (${expense.upiId})',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAlreadyPaid
                            ? AppColors.successMuted
                            : AppColors.success,
                        foregroundColor: isAlreadyPaid
                            ? AppColors.success
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

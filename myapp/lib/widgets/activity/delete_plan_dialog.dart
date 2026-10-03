import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/activity.dart';

class DeletePlanDialog extends StatefulWidget {
  final Activity activity;
  final VoidCallback onConfirmDelete;

  const DeletePlanDialog({
    super.key,
    required this.activity,
    required this.onConfirmDelete,
  });

  static void show(
    BuildContext context, {
    required Activity activity,
    required VoidCallback onConfirmDelete,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => DeletePlanDialog(
        activity: activity,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  State<DeletePlanDialog> createState() => _DeletePlanDialogState();
}

class _DeletePlanDialogState extends State<DeletePlanDialog> {
  bool _isDeleting = false;

  void _handleDelete() {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    Navigator.of(context).pop();
    widget.onConfirmDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delete this plan?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.activity.title}" will be removed for everyone. This can\'t be undone.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isDeleting ? null : _handleDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, size: 16),
                            SizedBox(width: 6),
                            Text('Delete'),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

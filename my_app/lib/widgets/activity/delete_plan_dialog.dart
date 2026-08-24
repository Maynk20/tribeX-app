import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/activity.dart';

class DeletePlanDialog extends StatelessWidget {
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
              '"${activity.title}" will be removed for everyone. This can\'t be undone.',
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirmDelete();
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
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

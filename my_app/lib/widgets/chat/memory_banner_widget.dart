import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/activity.dart';
import '../../state/activities_state.dart';

class MemoryBannerWidget extends StatelessWidget {
  final Activity activity;
  final bool canUpload;

  const MemoryBannerWidget({
    super.key,
    required this.activity,
    this.canUpload = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final memories = activity.photoMemories;

    if (memories.isEmpty && !canUpload) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'SQUAD MEMORIES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (canUpload)
                GestureDetector(
                  onTap: () {
                    // Simulate adding photo memory
                    context.read<ActivitiesState>().addMemoryPhoto(
                      activity.id,
                      "https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=600&auto=format&fit=crop&q=80",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Photo added to squad memories!'),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal list of memories
          if (memories.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: memories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final url = memories[idx];
                  return GestureDetector(
                    onTap: () {
                      _showPhoto(context, url);
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.image,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Text(
              'No squad photos uploaded yet. Capture memories after the plan!',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
        ],
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Container(
          color: Colors.black87,
          child: Center(child: Image.network(url, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

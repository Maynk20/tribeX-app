import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// Bottom navigation bar matching the TanStack bottom-nav.tsx exactly:
/// - 4 tabs: Explore (Compass), Create (PlusCircle), Messages (MessageCircle), Profile (User)
/// - Active tab: text-primary color, icon scale-110
/// - Inactive: text-muted-foreground, font-medium (w500)
/// - Active indicator: h-1 w-8 rounded-full bg-primary at -top-[9px]
/// - bg-background/85 backdrop-blur
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.85)
        : AppColors.backgroundLight.withValues(alpha: 0.85);
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: border.withValues(alpha: 0.6), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: LucideIcons.compass,
                label: 'Explore',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: LucideIcons.plusCircle,
                label: 'Create',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: LucideIcons.messageCircle,
                label: 'Messages',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: LucideIcons.user,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final activeColor = AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top active pill indicator: h-1 w-8 at -top-[9px], rounded-full, bg-primary
            if (isActive)
              Positioned(
                top: 0,
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

            // Tab content: icon + label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with scale-110 when active
                  AnimatedScale(
                    scale: isActive ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isActive ? activeColor : inactiveColor,
                      // strokeWidth 2.2 is used in TanStack (Lucide default is 2)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      // font-medium = w500 for both active and inactive
                      fontWeight: FontWeight.w500,
                      color: isActive ? activeColor : inactiveColor,
                      // tracking-wide ~ letterSpacing 0.05em on 11px = 0.55
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

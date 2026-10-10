import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Standardized, accessible avatar for TribeX.
/// Eliminates bare `NetworkImage` failures by providing robust loading,
/// error handling, and initials fallbacks with deterministic palette.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;
  final bool showOnlineIndicator;
  final bool isOnline;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    double? radius,
    double? size,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.backgroundColor,
  }) : radius = radius ?? (size != null ? size / 2 : 20.0);

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Color _resolveFallbackColor() {
    if (backgroundColor != null) return backgroundColor!;
    // Deterministic pleasant palette based on name hash code
    final colors = [
      AppColors.primary,
      const Color(0xFF4F46E5), // Indigo dark
      const Color(0xFF0D9488), // Teal
      const Color(0xFF059669), // Emerald
      const Color(0xFFD97706), // Amber
      const Color(0xFFDB2777), // Pink
      const Color(0xFF7C3AED), // Violet
      const Color(0xFF2563EB), // Blue
    ];
    final hash = name.trim().toLowerCase().codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final fallbackColor = _resolveFallbackColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.trim().isNotEmpty
          ? Image.network(
              imageUrl!.trim(),
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: radius,
                    height: radius,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildInitials(size);
              },
            )
          : _buildInitials(size),
    );

    if (showOnlineIndicator) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.65,
              height: radius * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppColors.secondary : Colors.grey,
                border: Border.all(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  width: 2.0,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return Semantics(
        button: true,
        label: '$name profile avatar',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: avatarWidget,
          ),
        ),
      );
    }

    return avatarWidget;
  }

  Widget _buildInitials(double size) {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

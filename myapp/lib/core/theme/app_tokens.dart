import 'package:flutter/material.dart';

/// Centralized layout, spacing, corner radius and touch-target tokens for TribeX.
/// Establishes intentional visual rhythm and removes arbitrary magic numbers.
class AppSpacing {
  AppSpacing._();

  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Insets shortcuts
  static const EdgeInsets edgeXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeMd = EdgeInsets.all(md);
  static const EdgeInsets edgeLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  // Screen horizontal padding standard
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0);
}

class AppRadius {
  AppRadius._();

  static const double none = 0.0;
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 22.0;
  static const double full = 999.0;

  static final BorderRadius rXs = BorderRadius.circular(xs);
  static final BorderRadius rSm = BorderRadius.circular(sm);
  static final BorderRadius rMd = BorderRadius.circular(md);
  static final BorderRadius rLg = BorderRadius.circular(lg);
  static final BorderRadius rXl = BorderRadius.circular(xl);
  static final BorderRadius rFull = BorderRadius.circular(full);
}

class AppTouchTarget {
  AppTouchTarget._();

  /// Recommended minimum interactive target size per accessibility guidelines (WCAG / Apple / Material).
  static const double minSize = 44.0;
  static const BoxConstraints minConstraints = BoxConstraints(
    minWidth: minSize,
    minHeight: minSize,
  );
}

import 'package:flutter/material.dart';

/// Responsive breakpoints following Material Design guidelines
class ResponsiveBreakpoints {
  /// Mobile phones: < 600px
  static const double mobile = 600;

  /// Tablets: 600px - 840px
  static const double tablet = 840;

  /// Desktop/Large tablets: > 840px
  static const double desktop = 1200;

  /// Maximum content width for tablets/desktop to prevent over-stretching
  static const double maxContentWidth = 1200;
}

/// Responsive utility class
class ResponsiveUtils {
  /// Check if screen is mobile size
  /// Uses the smaller dimension to avoid false positives in landscape
  static bool isMobile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.width < size.height ? size.width : size.height;
    return shortestSide < ResponsiveBreakpoints.mobile;
  }

  /// Check if screen is tablet size
  /// Uses the smaller dimension to properly detect tablets in any orientation
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.width < size.height ? size.width : size.height;
    return shortestSide >= ResponsiveBreakpoints.mobile &&
        shortestSide < ResponsiveBreakpoints.desktop;
  }

  /// Check if screen is desktop/large tablet size
  /// Uses the smaller dimension to properly detect large tablets
  static bool isDesktop(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.width < size.height ? size.width : size.height;
    return shortestSide >= ResponsiveBreakpoints.desktop;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  /// Get responsive spacing between elements
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 16;
    } else if (isTablet(context)) {
      return 24;
    } else {
      return 32;
    }
  }

  /// Get responsive grid cross axis count
  /// Returns 2 for mobile, 3 for tablet, 4 for desktop
  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get responsive card grid cross axis count for home page
  /// Returns 2 for mobile, 3 for tablet, 4 for desktop
  static int getCardGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) {
      return 2;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Constrain content width for tablets/desktop
  /// Centers content and applies max width
  static Widget constrainWidth(BuildContext context, Widget child) {
    if (isMobile(context)) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ResponsiveBreakpoints.maxContentWidth,
        ),
        child: child,
      ),
    );
  }

  /// Get responsive card aspect ratio
  static double getCardAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }
}


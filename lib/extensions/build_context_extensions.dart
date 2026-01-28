import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

/// Extension methods for BuildContext
extension BuildContextX on BuildContext {
  /// Get AppColors theme extension
  AppColors get appColors {
    final colors = Theme.of(this).extension<AppColors>();
    if (colors == null) {
      throw Exception('AppColors not found in theme');
    }
    return colors;
  }

  /// Get PersonCardStyles theme extension
  PersonCardStyles get personCardStyles {
    final styles = Theme.of(this).extension<PersonCardStyles>();
    if (styles == null) {
      throw Exception('PersonCardStyles not found in theme');
    }
    return styles;
  }

  /// Get CardTextStyles theme extension
  CardTextStyles get cardTextStyles {
    final styles = Theme.of(this).extension<CardTextStyles>();
    if (styles == null) {
      throw Exception('CardTextStyles not found in theme');
    }
    return styles;
  }

  /// Get DetailScreenStyles theme extension
  DetailScreenStyles get detailScreenStyles {
    final styles = Theme.of(this).extension<DetailScreenStyles>();
    if (styles == null) {
      throw Exception('DetailScreenStyles not found in theme');
    }
    return styles;
  }

  /// Get FooterStyles theme extension
  FooterStyles get footerStyles {
    final styles = Theme.of(this).extension<FooterStyles>();
    if (styles == null) {
      throw Exception('FooterStyles not found in theme');
    }
    return styles;
  }

  /// Show a snackbar with a message
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show an error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(this).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show a success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: appColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is in portrait mode
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Check if device is in landscape mode
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// Check if screen is mobile size
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Check if screen is tablet size
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Check if screen is desktop/large tablet size
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding => ResponsiveUtils.getPadding(this);

  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding =>
      ResponsiveUtils.getHorizontalPadding(this);

  /// Get responsive spacing between elements
  double get responsiveSpacing => ResponsiveUtils.getSpacing(this);

  /// Get responsive grid cross axis count
  int get gridCrossAxisCount => ResponsiveUtils.getGridCrossAxisCount(this);

  /// Get responsive card grid cross axis count
  int get cardGridCrossAxisCount =>
      ResponsiveUtils.getCardGridCrossAxisCount(this);
}


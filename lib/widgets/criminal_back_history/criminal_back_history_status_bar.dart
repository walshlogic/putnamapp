import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';

/// Status bar showing viewing count and total count for criminal back history cases
class CriminalBackHistoryStatusBar extends StatelessWidget {
  const CriminalBackHistoryStatusBar({
    required this.displayCount,
    required this.totalCount,
    required this.timeFilter,
    super.key,
  });

  final int displayCount;
  final int totalCount;
  final String timeFilter;

  /// Format number with comma separators
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Get display title for time filter
  String _getFilterTitle(String filter) {
    switch (filter) {
      case '1 YEAR':
        return 'CASES: THIS YEAR';
      case '5 YEARS':
        return 'CASES: PAST 5 YEARS';
      case 'ALL':
        return 'CASES: ALL DATES';
      default:
        return 'CASES';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Title row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: appColors.accentOrange,
            border: Border(
              bottom: BorderSide(color: appColors.border, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _getFilterTitle(timeFilter),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: appColors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Status row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: appColors.lightPurple,
            border: Border(
              bottom: BorderSide(color: appColors.border, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'VIEWING 1-${_formatNumber(displayCount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: appColors.accentOrange,
                ),
              ),
              Text(
                '${_formatNumber(totalCount)} TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: appColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


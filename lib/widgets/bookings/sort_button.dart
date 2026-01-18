import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/booking_filters.dart';

/// Icon-based sort button with three states: off, ascending, descending
class SortButton extends StatelessWidget {
  const SortButton({
    required this.label,
    required this.field,
    required this.currentSortField,
    required this.currentSortDirection,
    required this.onSortChanged,
    super.key,
  });

  final String label;
  final SortField field;
  final SortField currentSortField;
  final SortDirection currentSortDirection;
  final void Function(SortField field, SortDirection direction) onSortChanged;

  bool get _isActive => currentSortField == field;
  bool get _isAscending =>
      _isActive && currentSortDirection == SortDirection.ascending;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Material(
      color: _isActive ? appColors.primaryPurple : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _handleTap(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isActive
                  ? appColors.primaryPurple
                  : appColors.textLight.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              // Arrow icon (only show when active)
              if (_isActive) ...<Widget>[
                Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              // Label
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isActive ? Colors.white : appColors.textLight,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (!_isActive) {
      // First tap: activate with ascending
      onSortChanged(field, SortDirection.ascending);
    } else if (_isAscending) {
      // Second tap: switch to descending
      onSortChanged(field, SortDirection.descending);
    } else {
      // Third tap: turn off sorting
      onSortChanged(SortField.none, SortDirection.ascending);
    }
  }
}


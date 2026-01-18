import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/place_filters.dart';

/// Sort button for places
class PlaceSortButton extends StatelessWidget {
  const PlaceSortButton({
    required this.label,
    required this.field,
    required this.currentSortField,
    required this.currentSortDirection,
    required this.onSortChanged,
    super.key,
  });

  final String label;
  final PlaceSortField field;
  final PlaceSortField currentSortField;
  final PlaceSortDirection currentSortDirection;
  final void Function(PlaceSortField field, PlaceSortDirection direction)
      onSortChanged;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final bool isActive = currentSortField == field;
    final bool isAscending =
        currentSortDirection == PlaceSortDirection.ascending;

    return Material(
      color: isActive ? appColors.primaryPurple : appColors.scaffoldBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          if (isActive) {
            // Toggle direction if already selected
            onSortChanged(
              field,
              isAscending
                  ? PlaceSortDirection.descending
                  : PlaceSortDirection.ascending,
            );
          } else {
            // Select this field with default direction
            onSortChanged(field, PlaceSortDirection.descending);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? appColors.white : appColors.textDark,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: appColors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


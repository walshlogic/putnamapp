import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';

/// Custom filter chip widget for consistent styling
class FilterChipWidget extends StatelessWidget {
  const FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return SizedBox(
      width: double.infinity,
      child: FilterChip(
        label: Center(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? appColors.white : appColors.primaryPurple,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        selected: isSelected,
        selectedColor: appColors.primaryPurple,
        backgroundColor: appColors.white,
        checkmarkColor: appColors.white,
        side: BorderSide(
          color: appColors.primaryPurple,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        labelPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onSelected: onSelected,
      ),
    );
  }
}


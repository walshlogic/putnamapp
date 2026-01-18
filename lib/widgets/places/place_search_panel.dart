import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/place_filters.dart';
import '../bookings/filter_chip_widget.dart';
import 'place_sort_button.dart';

/// Search and filter panel for places screen
class PlaceSearchPanel extends StatelessWidget {
  const PlaceSearchPanel({
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.currentFilters,
    required this.onFiltersChanged,
    required this.availableSubcategories,
    required this.onSortChanged,
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final PlaceFilters currentFilters;
  final ValueChanged<PlaceFilters> onFiltersChanged;
  final List<String> availableSubcategories;
  final void Function(PlaceSortField field, PlaceSortDirection direction)
      onSortChanged;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      color: appColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Search field
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name or description...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: appColors.textLight,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: appColors.primaryPurple,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: onSearchCleared,
                    )
                  : null,
              filled: true,
              fillColor: appColors.scaffoldBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          
          // Subcategory filter (if available)
          if (availableSubcategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubcategoryFilters(context, appColors),
          ],

          // Price range filter
          const SizedBox(height: 12),
          _buildPriceRangeFilters(context, appColors),

          // Sort buttons
          const SizedBox(height: 12),
          _buildSortButtons(context, appColors),
        ],
      ),
    );
  }

  Widget _buildSubcategoryFilters(BuildContext context, dynamic appColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'TYPE:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: appColors.textLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableSubcategories.map((subcategory) {
            final isSelected =
                currentFilters.subcategories.contains(subcategory);
            return FilterChipWidget(
              label: subcategory.toUpperCase().replaceAll('-', ' '),
              isSelected: isSelected,
              onSelected: (_) {
                final List<String> newSubcategories =
                    List<String>.from(currentFilters.subcategories);
                if (isSelected) {
                  newSubcategories.remove(subcategory);
                } else {
                  newSubcategories.add(subcategory);
                }
                onFiltersChanged(
                  currentFilters.copyWith(subcategories: newSubcategories),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilters(BuildContext context, dynamic appColors) {
    const List<String> priceRanges = <String>['\$', '\$\$', '\$\$\$'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'PRICE RANGE:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: appColors.textLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Row(
          children: priceRanges.map((priceRange) {
            final isSelected =
                currentFilters.priceRanges.contains(priceRange);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChipWidget(
                  label: priceRange,
                  isSelected: isSelected,
                  onSelected: (_) {
                    final List<String> newPriceRanges =
                        List<String>.from(currentFilters.priceRanges);
                    if (isSelected) {
                      newPriceRanges.remove(priceRange);
                    } else {
                      newPriceRanges.add(priceRange);
                    }
                    onFiltersChanged(
                      currentFilters.copyWith(priceRanges: newPriceRanges),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortButtons(BuildContext context, dynamic appColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'SORT BY:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: appColors.textLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: PlaceSortButton(
                label: PlaceSortField.rating.label,
                field: PlaceSortField.rating,
                currentSortField: currentFilters.sortBy,
                currentSortDirection: currentFilters.sortDirection,
                onSortChanged: onSortChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PlaceSortButton(
                label: PlaceSortField.name.label,
                field: PlaceSortField.name,
                currentSortField: currentFilters.sortBy,
                currentSortDirection: currentFilters.sortDirection,
                onSortChanged: onSortChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PlaceSortButton(
                label: PlaceSortField.reviewCount.label,
                field: PlaceSortField.reviewCount,
                currentSortField: currentFilters.sortBy,
                currentSortDirection: currentFilters.sortDirection,
                onSortChanged: onSortChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


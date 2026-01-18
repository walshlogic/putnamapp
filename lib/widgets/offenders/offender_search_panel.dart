import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/sex_offender_filters.dart';
import '../bookings/filter_chip_widget.dart';
import 'offender_sort_button.dart';

/// Search and filter panel for sex offenders screen
class OffenderSearchPanel extends StatelessWidget {
  const OffenderSearchPanel({
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.selectedCity,
    required this.onCityChanged,
    required this.currentSortField,
    required this.currentSortDirection,
    required this.onSortChanged,
    required this.onClose,
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final String? selectedCity;
  final ValueChanged<String?> onCityChanged;
  final SortField currentSortField;
  final SortDirection currentSortDirection;
  final void Function(SortField field, SortDirection direction) onSortChanged;
  final VoidCallback onClose;

  // Common cities in Putnam County
  static const List<String> cities = <String>[
    'ALL CITIES',
    'PALATKA',
    'CRESCENT CITY',
    'INTERLACHEN',
    'WELAKA',
    'EAST PALATKA',
    'POMONA PARK',
    'SAN MATEO',
  ];

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      color: appColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: <Widget>[
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'SEARCH & FILTERS',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: appColors.primaryPurple,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: appColors.primaryPurple,
                  size: 20,
                ),
                onPressed: onClose,
                tooltip: 'Close panel',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search field
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name, city, or address...',
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
          const SizedBox(height: 12),

          // City Filter chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'CITY:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.textLight,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cities.map((String city) {
                  final bool isAllCities = city == 'ALL CITIES';
                  final bool isSelected = isAllCities
                      ? selectedCity == null
                      : selectedCity == city;

                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 48) / 2 - 4,
                    child: FilterChipWidget(
                      label: city,
                      isSelected: isSelected,
                      onSelected: (_) {
                        onCityChanged(isAllCities ? null : city);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sort buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'SORT:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.textLight,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OffenderSortButton(
                      label: 'NAME',
                      field: SortField.name,
                      currentSortField: currentSortField,
                      currentSortDirection: currentSortDirection,
                      onSortChanged: onSortChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OffenderSortButton(
                      label: 'CITY',
                      field: SortField.city,
                      currentSortField: currentSortField,
                      currentSortDirection: currentSortDirection,
                      onSortChanged: onSortChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OffenderSortButton(
                      label: 'AGE',
                      field: SortField.age,
                      currentSortField: currentSortField,
                      currentSortDirection: currentSortDirection,
                      onSortChanged: onSortChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


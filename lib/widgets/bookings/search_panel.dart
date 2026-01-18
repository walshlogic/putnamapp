import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../extensions/build_context_extensions.dart';
import '../../models/booking_filters.dart';
import 'filter_chip_widget.dart';
import 'sort_button.dart';

/// Search and filter panel for bookings screen
class SearchPanel extends StatelessWidget {
  const SearchPanel({
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.selectedTimeFilter,
    required this.onTimeFilterChanged,
    required this.selectedStatusFilter,
    required this.onStatusFilterChanged,
    required this.currentSortField,
    required this.currentSortDirection,
    required this.onSortChanged,
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final String selectedTimeFilter;
  final ValueChanged<String> onTimeFilterChanged;
  final String selectedStatusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final SortField currentSortField;
  final SortDirection currentSortDirection;
  final void Function(SortField field, SortDirection direction) onSortChanged;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      color: appColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: <Widget>[
          // Search field
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name, booking #, or charge...',
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
          const SizedBox(height: 8),

          // Time Filter chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'TIME PERIOD:',
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
                    child: FilterChipWidget(
                      label: AppConfig.timeRange24Hours,
                      isSelected:
                          selectedTimeFilter == AppConfig.timeRange24Hours,
                      onSelected: (_) =>
                          onTimeFilterChanged(AppConfig.timeRange24Hours),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChipWidget(
                      label: AppConfig.timeRangeThisYear,
                      isSelected:
                          selectedTimeFilter == AppConfig.timeRangeThisYear,
                      onSelected: (_) =>
                          onTimeFilterChanged(AppConfig.timeRangeThisYear),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChipWidget(
                      label: AppConfig.timeRange5Years,
                      isSelected:
                          selectedTimeFilter == AppConfig.timeRange5Years,
                      onSelected: (_) =>
                          onTimeFilterChanged(AppConfig.timeRange5Years),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChipWidget(
                      label: AppConfig.timeRangeAll,
                      isSelected: selectedTimeFilter == AppConfig.timeRangeAll,
                      onSelected: (_) =>
                          onTimeFilterChanged(AppConfig.timeRangeAll),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status Filter chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'STATUS:',
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
                    child: FilterChipWidget(
                      label: AppConfig.statusAll,
                      isSelected: selectedStatusFilter == AppConfig.statusAll,
                      onSelected: (_) =>
                          onStatusFilterChanged(AppConfig.statusAll),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChipWidget(
                      label: AppConfig.statusInJail,
                      isSelected: selectedStatusFilter == AppConfig.statusInJail,
                      onSelected: (_) =>
                          onStatusFilterChanged(AppConfig.statusInJail),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChipWidget(
                      label: AppConfig.statusReleased,
                      isSelected:
                          selectedStatusFilter == AppConfig.statusReleased,
                      onSelected: (_) =>
                          onStatusFilterChanged(AppConfig.statusReleased),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

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
                    child: SortButton(
                      label: 'DATE',
                      field: SortField.date,
                      currentSortField: currentSortField,
                      currentSortDirection: currentSortDirection,
                      onSortChanged: onSortChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SortButton(
                      label: 'NAME',
                      field: SortField.name,
                      currentSortField: currentSortField,
                      currentSortDirection: currentSortDirection,
                      onSortChanged: onSortChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SortButton(
                      label: '#CHARGES',
                      field: SortField.charges,
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


import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../extensions/build_context_extensions.dart';
import '../../widgets/bookings/filter_chip_widget.dart';

/// Search and filter panel for criminal back history screen
class CriminalBackHistorySearchPanel extends StatelessWidget {
  const CriminalBackHistorySearchPanel({
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.selectedTimeFilter,
    required this.onTimeFilterChanged,
    required this.sortBy,
    required this.sortOrder,
    required this.nameSortBy,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
    required this.onNameSortByChanged,
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final String selectedTimeFilter;
  final ValueChanged<String> onTimeFilterChanged;
  final String sortBy;
  final String sortOrder;
  final String nameSortBy;
  final ValueChanged<String> onSortByChanged;
  final ValueChanged<String> onSortOrderChanged;
  final ValueChanged<String> onNameSortByChanged;

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
              hintText: 'Search by name (lastname, firstname) or case number...',
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          // Sort Options
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'SORT BY:',
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
                      label: 'DATE',
                      isSelected: sortBy == AppConfig.sortByDate,
                      onSelected: (_) => onSortByChanged(AppConfig.sortByDate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChipWidget(
                      label: 'NAME',
                      isSelected: sortBy == AppConfig.sortByName,
                      onSelected: (_) => onSortByChanged(AppConfig.sortByName),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (sortBy == AppConfig.sortByDate) ...[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilterChipWidget(
                    label: 'NEWEST',
                    isSelected: sortOrder == AppConfig.sortOrderDesc,
                    onSelected: (_) => onSortOrderChanged(AppConfig.sortOrderDesc),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChipWidget(
                    label: 'OLDEST',
                    isSelected: sortOrder == AppConfig.sortOrderAsc,
                    onSelected: (_) => onSortOrderChanged(AppConfig.sortOrderAsc),
                  ),
                ),
              ],
            ),
          ],
          if (sortBy == AppConfig.sortByName) ...[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilterChipWidget(
                    label: 'LAST NAME',
                    isSelected: nameSortBy == AppConfig.nameSortByLastName,
                    onSelected: (_) => onNameSortByChanged(AppConfig.nameSortByLastName),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChipWidget(
                    label: 'FIRST NAME',
                    isSelected: nameSortBy == AppConfig.nameSortByFirstName,
                    onSelected: (_) => onNameSortByChanged(AppConfig.nameSortByFirstName),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilterChipWidget(
                    label: 'A-Z',
                    isSelected: sortOrder == AppConfig.sortOrderAsc,
                    onSelected: (_) => onSortOrderChanged(AppConfig.sortOrderAsc),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChipWidget(
                    label: 'Z-A',
                    isSelected: sortOrder == AppConfig.sortOrderDesc,
                    onSelected: (_) => onSortOrderChanged(AppConfig.sortOrderDesc),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


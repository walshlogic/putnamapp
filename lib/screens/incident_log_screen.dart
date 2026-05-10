import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/incident.dart';
import '../providers/incident_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class IncidentLogScreen extends ConsumerWidget {
  const IncidentLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final AsyncValue<List<Incident>> incidentsAsync =
        ref.watch(incidentsProvider);
    final AsyncValue<bool> canEditAsync =
        ref.watch(canEditIncidentsProvider);
    final IncidentFilters filters = ref.watch(incidentFiltersProvider);

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      floatingActionButton: canEditAsync.maybeWhen(
        data: (canEdit) => canEdit
            ? FloatingActionButton.extended(
                backgroundColor: appColors.primaryPurple,
                foregroundColor: appColors.white,
                onPressed: () => context.push(RoutePaths.incidentEdit),
                icon: const Icon(Icons.add),
                label: const Text('NEW'),
              )
            : null,
        orElse: () => null,
      ),
      body: Column(
        children: <Widget>[
          _Header(appColors: appColors),
          _FilterBar(filters: filters, appColors: appColors),
          Expanded(
            child: incidentsAsync.when(
              data: (List<Incident> items) {
                if (items.isEmpty) {
                  return _EmptyState(filters: filters, appColors: appColors);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(incidentsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int i) =>
                        _IncidentCard(incident: items[i], appColors: appColors),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load incidents:\n$e',
                      textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.appColors});
  final dynamic appColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[appColors.primaryPurple, appColors.darkPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.report, color: appColors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('INCIDENT LOG',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: appColors.white)),
                const SizedBox(height: 4),
                Text('Documented public safety events',
                    style: TextStyle(
                        fontSize: 13,
                        color: appColors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filters, required this.appColors});
  final IncidentFilters filters;
  final dynamic appColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateFormat fmt = DateFormat.yMMMd();
    final String fromLabel =
        filters.from != null ? fmt.format(filters.from!) : 'From';
    final String toLabel =
        filters.to != null ? fmt.format(filters.to!) : 'To';
    final String categoryLabel = filters.category != null
        ? IncidentCategory.label(filters.category!)
        : 'All categories';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: <Widget>[
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search title, description, location',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: filters.search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => ref
                          .read(incidentFiltersProvider.notifier)
                          .update((f) => f.copyWith(search: '')),
                    ),
            ),
            controller: TextEditingController(text: filters.search)
              ..selection = TextSelection.fromPosition(
                  TextPosition(offset: filters.search.length)),
            onSubmitted: (String v) => ref
                .read(incidentFiltersProvider.notifier)
                .update((f) => f.copyWith(search: v)),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(fromLabel, overflow: TextOverflow.ellipsis),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: filters.from ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      ref.read(incidentFiltersProvider.notifier).update(
                          (f) => f.copyWith(from: picked));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event_available, size: 18),
                  label: Text(toLabel, overflow: TextOverflow.ellipsis),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: filters.to ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      ref.read(incidentFiltersProvider.notifier).update(
                          (f) => f.copyWith(to: picked));
                    }
                  },
                ),
              ),
              if (filters.from != null || filters.to != null) ...<Widget>[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear dates',
                  onPressed: () => ref
                      .read(incidentFiltersProvider.notifier)
                      .update((f) =>
                          f.copyWith(from: null, to: null)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: filters.category,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  hint: Text(categoryLabel, overflow: TextOverflow.ellipsis),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...IncidentCategory.all.map(
                      (String c) => DropdownMenuItem<String?>(
                        value: c,
                        child: Text(IncidentCategory.label(c)),
                      ),
                    ),
                  ],
                  onChanged: (String? v) => ref
                      .read(incidentFiltersProvider.notifier)
                      .update((f) => f.copyWith(category: v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.appColors});
  final Incident incident;
  final dynamic appColors;

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat.yMMMd();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(RoutePaths.incidentDetail,
            extra: incident.id),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.report,
                        color: appColors.primaryPurple, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        incident.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  fmt.format(incident.occurredAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Icon(Icons.place,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident.locationText,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  incident.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
                if (incident.category != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          IncidentCategory.label(incident.category!),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: appColors.primaryPurple
                            .withValues(alpha: 0.10),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filters, required this.appColors});
  final IncidentFilters filters;
  final dynamic appColors;

  @override
  Widget build(BuildContext context) {
    final bool isFiltered = filters.search.isNotEmpty ||
        filters.category != null ||
        filters.from != null ||
        filters.to != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              isFiltered
                  ? 'No incidents match these filters.'
                  : 'No incidents have been logged yet.',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

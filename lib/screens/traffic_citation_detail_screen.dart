import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/traffic_citation.dart';
import '../providers/traffic_citation_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class TrafficCitationDetailScreen extends ConsumerWidget {
  const TrafficCitationDetailScreen({
    required this.citation,
    super.key,
  });

  final TrafficCitation citation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    
    // Only fetch if we have date of birth
    final citationsAsync = citation.dateOfBirth != null
        ? ref.watch(
            trafficCitationsByPersonProvider((
              lastName: citation.lastName,
              firstName: citation.firstName,
              dateOfBirth: citation.dateOfBirth!,
            )),
          )
        : ref.watch(trafficCitationsByNameProvider(citation.fullName));

    final styles = context.detailScreenStyles;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Personal Info Card
                _buildSectionCard(
                  context,
                  icon: Icons.person,
                  title: 'PERSONAL INFORMATION',
                  children: <Widget>[
                    // Name - centered, full width
                    Center(
                      child: Text(
                        citation.fullName.toUpperCase(),
                        style: TextStyle(
                          fontSize: styles.personNameSize,
                          fontWeight: FontWeight.bold,
                          color: appColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (citation.dateOfBirth != null ||
                        citation.gender != null ||
                        citation.address != null) ...<Widget>[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                    ],
                    if (citation.dateOfBirth != null) ...<Widget>[
                      _buildInfoRow(
                        context,
                        'Date of Birth',
                        citation.dateOfBirthString ?? '',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (citation.gender != null && citation.gender!.isNotEmpty) ...<Widget>[
                      _buildInfoRow(
                        context,
                        'Gender',
                        citation.gender!.toUpperCase(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (citation.licenseNumber != null && citation.licenseNumber!.isNotEmpty) ...<Widget>[
                      _buildInfoRow(
                        context,
                        'License Number',
                        citation.licenseNumber!.toUpperCase(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Address Card
                if (citation.address != null && citation.address!.isNotEmpty)
                  _buildSectionCard(
                    context,
                    icon: Icons.home_outlined,
                    title: 'ADDRESS',
                    children: <Widget>[
                      Text(
                        citation.fullAddress.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                if (citation.address != null && citation.address!.isNotEmpty) const SizedBox(height: 12),

                // Citation Details Card
                _buildSectionCard(
                  context,
                  icon: Icons.description_outlined,
                  title: 'CITATION DETAILS',
                  children: <Widget>[
                    _buildInfoRow(
                      context,
                      'Case Number',
                      citation.fullCaseNumber.toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Citation Date',
                      citation.citationDateString.toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Violation',
                      citation.violationDescription.toUpperCase(),
                    ),
                    if (citation.licensePlate != null && citation.licensePlate!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'License Plate',
                        citation.licensePlate!.toUpperCase(),
                      ),
                    ],
                    if (citation.dispositionDate != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Disposition Date',
                        citation.dispositionDateString?.toUpperCase() ?? '',
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Citation History Summary Card & Other Citations
                citationsAsync.when(
                  data: (List<TrafficCitation> allCitationsList) {
                    final List<TrafficCitation> otherCitations = allCitationsList
                        .where(
                          (TrafficCitation c) => c.id != citation.id,
                        )
                        .toList();

                    if (otherCitations.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final int totalCitations = allCitationsList.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Statistics Card
                        _buildSectionCard(
                          context,
                          icon: Icons.history,
                          title: 'CITATION HISTORY',
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        'TOTAL CITATIONS',
                                        style: TextStyle(
                                          fontSize: styles.statisticLabelSize,
                                          color: appColors.textLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        totalCitations.toString(),
                                        style: TextStyle(
                                          fontSize: styles.statisticNumberSize,
                                          fontWeight: FontWeight.bold,
                                          color: appColors.primaryPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Other citation cards
                        ...otherCitations.map((TrafficCitation c) {
                          return GestureDetector(
                            onTap: () => context.push(
                              RoutePaths.trafficCitationDetail,
                              extra: c,
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: appColors.lightPurple,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.traffic,
                                    color: appColors.primaryPurple,
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  c.citationDateString,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: context.appColors.primaryPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                subtitle: Text(
                                  c.violationDescription.toUpperCase(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: context.appColors.divider,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (Object e, StackTrace st) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final styles = context.detailScreenStyles;
    final appColors = context.appColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appColors.lightPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: appColors.primaryPurple,
                    size: styles.sectionIconSize,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: styles.sectionTitleSize,
                    fontWeight: FontWeight.w600,
                    color: appColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final styles = context.detailScreenStyles;
    final appColors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: styles.infoLabelSize,
              color: appColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: styles.infoValueSize,
              fontWeight: FontWeight.w600,
              color: appColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}



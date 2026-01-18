import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/criminal_back_history.dart';
import '../providers/criminal_back_history_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class CriminalBackHistoryDetailScreen extends ConsumerWidget {
  const CriminalBackHistoryDetailScreen({
    required this.caseRecord,
    super.key,
  });

  final CriminalBackHistory caseRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    
    // Only fetch if we have date of birth
    final casesAsync = caseRecord.dateOfBirth != null
        ? ref.watch(
            criminalBackHistoryByPersonProvider((
              lastName: caseRecord.defendantLastName,
              firstName: caseRecord.defendantFirstName,
              dateOfBirth: caseRecord.dateOfBirth!,
            )),
          )
        : ref.watch(criminalBackHistoryByNameProvider(caseRecord.fullName));

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
                        caseRecord.fullName.toUpperCase(),
                        style: TextStyle(
                          fontSize: styles.personNameSize,
                          fontWeight: FontWeight.bold,
                          color: appColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (caseRecord.dateOfBirth != null ||
                        caseRecord.addressLine1 != null) ...<Widget>[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                    ],
                    if (caseRecord.dateOfBirth != null) ...<Widget>[
                      _buildInfoRow(
                        context,
                        'Date of Birth',
                        caseRecord.dateOfBirthString ?? '',
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Address Card
                if (caseRecord.addressLine1 != null && caseRecord.addressLine1!.isNotEmpty)
                  _buildSectionCard(
                    context,
                    icon: Icons.home_outlined,
                    title: 'ADDRESS',
                    children: <Widget>[
                      Text(
                        caseRecord.fullAddress.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                if (caseRecord.addressLine1 != null && caseRecord.addressLine1!.isNotEmpty) const SizedBox(height: 12),

                // Case Details Card
                _buildSectionCard(
                  context,
                  icon: Icons.gavel,
                  title: 'CASE DETAILS',
                  children: <Widget>[
                    _buildInfoRow(
                      context,
                      'Case Number',
                      caseRecord.caseNumber.toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Uniform Case Number',
                      caseRecord.uniformCaseNumber.toUpperCase(),
                    ),
                    if (caseRecord.clerkFileDate != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Clerk File Date',
                        caseRecord.clerkFileDateString?.toUpperCase() ?? '',
                      ),
                    ],
                    if (caseRecord.statuteDescription != null && caseRecord.statuteDescription!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Statute Description',
                        caseRecord.statuteDescription!.toUpperCase(),
                      ),
                    ],
                    if (caseRecord.courtActionDescription != null && caseRecord.courtActionDescription!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Court Action',
                        caseRecord.courtActionDescription!.toUpperCase(),
                      ),
                    ],
                    if (caseRecord.prosecutorActionDescription != null && caseRecord.prosecutorActionDescription!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Prosecutor Action',
                        caseRecord.prosecutorActionDescription!.toUpperCase(),
                      ),
                    ],
                    if (caseRecord.courtDecisionDate != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Court Decision Date',
                        caseRecord.courtDecisionDateString?.toUpperCase() ?? '',
                      ),
                    ],
                    if (caseRecord.prosDecisionDate != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Prosecutor Decision Date',
                        caseRecord.prosDecisionDate != null
                            ? '${caseRecord.prosDecisionDate!.month}/${caseRecord.prosDecisionDate!.day}/${caseRecord.prosDecisionDate!.year}'
                            : '',
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Case History Summary Card & Other Cases
                casesAsync.when(
                  data: (List<CriminalBackHistory> allCasesList) {
                    final List<CriminalBackHistory> otherCases = allCasesList
                        .where(
                          (CriminalBackHistory c) => c.id != caseRecord.id,
                        )
                        .toList();

                    if (otherCases.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final int totalCases = allCasesList.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Statistics Card
                        _buildSectionCard(
                          context,
                          icon: Icons.history,
                          title: 'CASE HISTORY',
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        'TOTAL CASES',
                                        style: TextStyle(
                                          fontSize: styles.statisticLabelSize,
                                          color: appColors.textLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        totalCases.toString(),
                                        style: TextStyle(
                                          fontSize: styles.statisticNumberSize,
                                          fontWeight: FontWeight.bold,
                                          color: appColors.accentOrange,
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
                        // Other case cards
                        ...otherCases.map((CriminalBackHistory c) {
                          return GestureDetector(
                            onTap: () => context.push(
                              RoutePaths.criminalBackHistoryDetail,
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
                                    Icons.gavel,
                                    color: appColors.accentOrange,
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  c.clerkFileDateString ?? 'NO DATE',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: context.appColors.accentOrange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                subtitle: Text(
                                  c.statuteDescriptionShort.toUpperCase(),
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
                    color: appColors.accentOrange,
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



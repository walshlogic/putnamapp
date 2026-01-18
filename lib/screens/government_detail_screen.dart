import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../extensions/build_context_extensions.dart';
import '../models/government_entity.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/settings_drawer.dart';

class GovernmentDetailScreen extends ConsumerWidget {
  const GovernmentDetailScreen({
    super.key,
    required this.governmentName,
  });

  final String governmentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final entity = GovernmentData.getByName(governmentName);
    
    if (entity == null) {
      return Scaffold(
        appBar: const PutnamAppBar(showBackButton: true),
        drawer: const AppDrawer(),
        endDrawer: const SettingsDrawer(),
        body: Center(
          child: Text('Government entity not found: $governmentName'),
        ),
      );
    }

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
                // Header
                Center(
                  child: Text(
                    entity.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: styles.personNameSize,
                      fontWeight: FontWeight.bold,
                      color: appColors.primaryPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    entity.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      color: appColors.textMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main Contact Information Card
                if (entity.mainAddress != null || entity.mainPhone != null || entity.mainEmail != null)
                  _buildSectionCard(
                    context,
                    icon: Icons.info_outline,
                    title: 'CONTACT INFORMATION',
                    children: <Widget>[
                      if (entity.mainAddress != null) ...<Widget>[
                        _buildInfoRow(
                          context,
                          'Address',
                          entity.mainAddress!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (entity.mainPhone != null) ...<Widget>[
                        _buildClickableRow(
                          context,
                          'Phone',
                          entity.mainPhone!,
                          onTap: () => _makePhoneCall(entity.mainPhone!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (entity.mainEmail != null) ...<Widget>[
                        _buildClickableRow(
                          context,
                          'Email',
                          entity.mainEmail!,
                          onTap: () => _sendEmail(entity.mainEmail!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (entity.website != null) ...<Widget>[
                        _buildClickableRow(
                          context,
                          'Website',
                          entity.website!,
                          onTap: () => _openWebsite(entity.website!),
                        ),
                      ],
                    ],
                  ),

                if (entity.mainAddress != null || entity.mainPhone != null || entity.mainEmail != null)
                  const SizedBox(height: 12),

                // Departments Card
                if (entity.departments.isNotEmpty)
                  _buildSectionCard(
                    context,
                    icon: Icons.business,
                    title: 'DEPARTMENTS',
                    children: <Widget>[
                      ...entity.departments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dept = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (index > 0) ...<Widget>[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              dept.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: styles.sectionTitleSize - 2,
                                fontWeight: FontWeight.bold,
                                color: appColors.primaryPurple,
                              ),
                            ),
                            if (dept.directorName != null) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                'Director: ${dept.directorName}',
                                style: TextStyle(
                                  fontSize: styles.infoValueSize,
                                  color: appColors.textDark,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            if (dept.address != null) ...<Widget>[
                              _buildInfoRow(
                                context,
                                'Address',
                                dept.address!,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (dept.phone != null) ...<Widget>[
                              _buildClickableRow(
                                context,
                                'Phone',
                                dept.phone!,
                                onTap: () => _makePhoneCall(dept.phone!),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (dept.email != null) ...<Widget>[
                              _buildClickableRow(
                                context,
                                'Email',
                                dept.email!,
                                onTap: () => _sendEmail(dept.email!),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (dept.fax != null) ...<Widget>[
                              _buildInfoRow(
                                context,
                                'Fax',
                                dept.fax!,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (dept.officeHours != null) ...<Widget>[
                              _buildInfoRow(
                                context,
                                'Office Hours',
                                dept.officeHours!,
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),

                if (entity.departments.isNotEmpty) const SizedBox(height: 12),

                // Officials Card
                if (entity.officials.isNotEmpty)
                  _buildSectionCard(
                    context,
                    icon: Icons.people,
                    title: 'ELECTED OFFICIALS & LEADERSHIP',
                    children: <Widget>[
                      ...entity.officials.asMap().entries.map((entry) {
                        final index = entry.key;
                        final official = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (index > 0) ...<Widget>[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              official.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: styles.sectionTitleSize - 2,
                                fontWeight: FontWeight.bold,
                                color: appColors.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              official.position,
                              style: TextStyle(
                                fontSize: styles.infoValueSize,
                                color: appColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (official.phone != null) ...<Widget>[
                              _buildClickableRow(
                                context,
                                'Phone',
                                official.phone!,
                                onTap: () => _makePhoneCall(official.phone!),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (official.cellPhone != null) ...<Widget>[
                              _buildClickableRow(
                                context,
                                'Cell',
                                official.cellPhone!,
                                onTap: () => _makePhoneCall(official.cellPhone!),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (official.email != null) ...<Widget>[
                              _buildClickableRow(
                                context,
                                'Email',
                                official.email!,
                                onTap: () => _sendEmail(official.email!),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (official.address != null) ...<Widget>[
                              _buildInfoRow(
                                context,
                                'Address',
                                official.address!,
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),

                if (entity.officials.isNotEmpty) const SizedBox(height: 12),

                // Locations Card
                if (entity.locations.isNotEmpty)
                  _buildSectionCard(
                    context,
                    icon: Icons.location_on,
                    title: 'ADDITIONAL LOCATIONS',
                    children: <Widget>[
                      ...entity.locations.map((location) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: styles.infoValueSize,
                              color: appColors.textDark,
                            ),
                          ),
                        );
                      }),
                    ],
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: styles.sectionTitleSize,
                      fontWeight: FontWeight.w600,
                      color: appColors.textDark,
                    ),
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
        SizedBox(
          width: 100,
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
          child: Text(
            value,
            style: TextStyle(
              fontSize: styles.infoValueSize,
              fontWeight: FontWeight.w500,
              color: appColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClickableRow(
    BuildContext context,
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    final styles = context.detailScreenStyles;
    final appColors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
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
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: styles.infoValueSize,
                      fontWeight: FontWeight.w500,
                      color: appColors.primaryPurple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: appColors.primaryPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite(String website) async {
    String url = website;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}


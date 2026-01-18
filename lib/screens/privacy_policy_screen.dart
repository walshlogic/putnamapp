import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/settings_drawer.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    
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
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appColors.lightPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.privacy_tip_outlined,
                        color: appColors.primaryPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PRIVACY POLICY',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Last Updated
                Text(
                  'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: appColors.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),

                // Privacy Policy Content
                _buildSection(
                  context,
                  appColors,
                  '1. INTRODUCTION',
                  'Putnam.app ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the "App"). Please read this Privacy Policy carefully. If you do not agree with the terms of this Privacy Policy, please do not access the App.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '2. INFORMATION WE COLLECT',
                  'We may collect information about you in various ways. The information we may collect via the App includes:\n\n'
                  '• Personal Data: Name, email address, and other personally identifiable information that you voluntarily give to us when you register with the App or when you choose to participate in various activities related to the App.\n\n'
                  '• Public Records Data: We display publicly available information from government sources including but not limited to jail logs, traffic citations, criminal history records, sex offender registries, and other public records from Putnam County, Florida.\n\n'
                  '• Device Information: We may collect information about your device including device type, operating system, unique device identifiers, and mobile network information.\n\n'
                  '• Usage Data: We may collect information about how you access and use the App, including your IP address, browser type, pages viewed, and the time and date of your visits.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '3. HOW WE USE YOUR INFORMATION',
                  'We use the information we collect to:\n\n'
                  '• Provide, maintain, and improve our services\n'
                  '• Process your transactions and send you related information\n'
                  '• Send you technical notices, updates, security alerts, and support messages\n'
                  '• Respond to your comments, questions, and requests\n'
                  '• Monitor and analyze trends, usage, and activities\n'
                  '• Personalize and improve the App experience\n'
                  '• Detect, prevent, and address technical issues',
                ),

                _buildSection(
                  context,
                  appColors,
                  '4. PUBLIC RECORDS DISCLOSURE',
                  'The App displays information from public records maintained by government agencies in Putnam County, Florida. This information is publicly available and is not considered private or confidential under Florida law. We aggregate and present this public information for your convenience, but we do not create, modify, or control the underlying public records data.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '5. DATA STORAGE AND SECURITY',
                  'We implement appropriate technical and organizational security measures to protect your personal information. However, no method of transmission over the Internet or electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your information, we cannot guarantee absolute security.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '6. THIRD-PARTY SERVICES',
                  'The App may contain links to third-party websites or services that are not owned or controlled by us. We have no control over, and assume no responsibility for, the content, privacy policies, or practices of any third-party websites or services. We encourage you to review the privacy policies of any third-party services you access.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '7. CHILDREN\'S PRIVACY',
                  'The App is not intended for children under the age of 13. We do not knowingly collect personally identifiable information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '8. YOUR PRIVACY RIGHTS',
                  'Depending on your location, you may have certain rights regarding your personal information, including:\n\n'
                  '• The right to access – You have the right to request copies of your personal data\n'
                  '• The right to rectification – You have the right to request correction of inaccurate data\n'
                  '• The right to erasure – You have the right to request deletion of your data\n'
                  '• The right to restrict processing – You have the right to request restriction of processing\n'
                  '• The right to data portability – You have the right to request transfer of your data\n\n'
                  'To exercise these rights, please contact us using the contact information provided below.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '9. CALIFORNIA PRIVACY RIGHTS',
                  'If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA), including the right to know what personal information we collect, the right to delete personal information, and the right to opt-out of the sale of personal information. We do not sell your personal information.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '10. CHANGES TO THIS PRIVACY POLICY',
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '11. CONTACT US',
                  'If you have any questions about this Privacy Policy, please contact us:\n\n'
                  'Email: privacy@putnam.app\n'
                  'Address: 104 Pine Ave, Georgetown, FL 32139\n\n'
                  'We will respond to your inquiry within a reasonable timeframe.',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    AppColors appColors,
    String title,
    String content,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: appColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


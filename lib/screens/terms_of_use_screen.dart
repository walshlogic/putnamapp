import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/settings_drawer.dart';

class TermsOfUseScreen extends ConsumerWidget {
  const TermsOfUseScreen({super.key});

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
                        Icons.description_outlined,
                        color: appColors.primaryPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'TERMS OF USE',
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

                // Terms of Use Content
                _buildSection(
                  context,
                  appColors,
                  '1. AGREEMENT TO TERMS',
                  'By downloading, installing, accessing, or using Putnam.app (the "App"), you agree to be bound by these Terms of Use ("Terms"). If you do not agree to these Terms, do not use the App. We may modify these Terms at any time, and such modifications shall be effective immediately upon posting.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '2. DESCRIPTION OF SERVICE',
                  'Putnam.app provides access to public records and information from Putnam County, Florida, including but not limited to:\n\n'
                  '• Jail bookings and arrest records\n'
                  '• Traffic citations\n'
                  '• Criminal history records\n'
                  '• Sex offender registry information\n'
                  '• Government and court records\n'
                  '• Local directory and business information\n'
                  '• News and weather information\n\n'
                  'All information displayed in the App is derived from publicly available sources maintained by government agencies.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '3. SUBSCRIPTION SERVICES',
                  'The App offers subscription services ("Subscriptions") that provide access to premium features. By purchasing a Subscription, you agree to:\n\n'
                  '• Pay the subscription fee displayed at the time of purchase\n'
                  '• Automatic renewal of your Subscription unless cancelled at least 24 hours before the end of the current period\n'
                  '• Payment will be charged to your Apple ID account at confirmation of purchase\n'
                  '• Your Subscription will automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period\n'
                  '• You can manage your Subscriptions and turn off auto-renewal in your Account Settings in the App Store\n'
                  '• Any unused portion of a free trial period will be forfeited when you purchase a Subscription\n'
                  '• Subscriptions may be cancelled at any time through your Apple ID account settings',
                ),

                _buildSection(
                  context,
                  appColors,
                  '4. USER ACCOUNTS',
                  'To access certain features of the App, you may be required to create an account. You agree to:\n\n'
                  '• Provide accurate, current, and complete information\n'
                  '• Maintain and update your account information\n'
                  '• Maintain the security of your account credentials\n'
                  '• Accept responsibility for all activities under your account\n'
                  '• Notify us immediately of any unauthorized use of your account',
                ),

                _buildSection(
                  context,
                  appColors,
                  '5. ACCEPTABLE USE',
                  'You agree not to:\n\n'
                  '• Use the App for any illegal purpose or in violation of any laws\n'
                  '• Harass, abuse, or harm other users\n'
                  '• Transmit any viruses, malware, or harmful code\n'
                  '• Attempt to gain unauthorized access to the App or its systems\n'
                  '• Use automated systems to access the App without permission\n'
                  '• Copy, modify, or distribute the App or its content without authorization\n'
                  '• Use the App to violate the privacy rights of others',
                ),

                _buildSection(
                  context,
                  appColors,
                  '6. PUBLIC RECORDS DISCLAIMER',
                  'The information displayed in the App is derived from public records maintained by government agencies. We do not:\n\n'
                  '• Create, modify, or control the underlying public records data\n'
                  '• Guarantee the accuracy, completeness, or timeliness of the information\n'
                  '• Endorse or verify the information displayed\n'
                  '• Assume liability for errors or omissions in public records\n\n'
                  'Users are responsible for verifying information obtained through the App before making decisions based on such information.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '7. INTELLECTUAL PROPERTY',
                  'The App and its original content, features, and functionality are owned by Putnam.app and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws. You may not reproduce, distribute, modify, create derivative works of, publicly display, or otherwise exploit the App or its content without our express written permission.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '8. DISCLAIMER OF WARRANTIES',
                  'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, SECURE, OR ERROR-FREE.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '9. LIMITATION OF LIABILITY',
                  'TO THE MAXIMUM EXTENT PERMITTED BY LAW, PUTNAM.APP SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES, WHETHER INCURRED DIRECTLY OR INDIRECTLY, OR ANY LOSS OF DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM YOUR USE OF THE APP.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '10. INDEMNIFICATION',
                  'You agree to indemnify, defend, and hold harmless Putnam.app, its officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, and expenses, including reasonable attorneys\' fees, arising out of or in any way connected with your access to or use of the App or violation of these Terms.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '11. TERMINATION',
                  'We may terminate or suspend your account and access to the App immediately, without prior notice or liability, for any reason, including if you breach these Terms. Upon termination, your right to use the App will cease immediately.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '12. GOVERNING LAW',
                  'These Terms shall be governed by and construed in accordance with the laws of the State of Florida, United States, without regard to its conflict of law provisions. Any disputes arising under or in connection with these Terms shall be subject to the exclusive jurisdiction of the courts located in Putnam County, Florida.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '13. CHANGES TO TERMS',
                  'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion. Your continued use of the App after any changes constitutes acceptance of the new Terms.',
                ),

                _buildSection(
                  context,
                  appColors,
                  '14. CONTACT INFORMATION',
                  'If you have any questions about these Terms of Use, please contact us:\n\n'
                  'Email: support@putnam.app\n'
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


import 'package:flutter/material.dart';

import '../extensions/build_context_extensions.dart';
import '../models/sex_offender.dart';
import '../widgets/putnam_app_bar.dart';

class SexOffenderDetailScreen extends StatelessWidget {
  const SexOffenderDetailScreen({
    required this.offender,
    super.key,
  });

  final SexOffender offender;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final styles = context.personCardStyles;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Photo or placeholder (tappable to enlarge if photo exists)
            Center(
              child: GestureDetector(
                onTap: offender.imageUrl != null &&
                        offender.imageUrl!.isNotEmpty
                    ? () {
                        // Show enlarged photo in dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            // Use a square container based on the smaller screen dimension
                            final double screenWidth = MediaQuery.of(dialogContext).size.width;
                            final double screenHeight = MediaQuery.of(dialogContext).size.height;
                            final double size = (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.85;
                            
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                children: <Widget>[
                                  // Enlarged photo
                                  Center(
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(dialogContext).pop(),
                                      child: Container(
                                        width: size,
                                        height: size,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 30,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: Image.network(
                                            offender.imageUrl!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: appColors.lightPurple,
                                              child: Icon(
                                                Icons.person_outline,
                                                size: 64,
                                                color: appColors.primaryPurple,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Close button
                                  Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    : null,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: appColors.lightPurple,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: appColors.primaryPurple,
                      width: 2,
                    ),
                  ),
                  child: offender.imageUrl != null &&
                          offender.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            offender.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person_outline,
                              size: 64,
                              color: appColors.primaryPurple,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person_outline,
                          size: 64,
                          color: appColors.primaryPurple,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            Center(
              child: Text(
                offender.name.toUpperCase(),
                style: styles.nameStyle.copyWith(
                  color: appColors.textDark,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // Status badge if available
            if (offender.status != null && offender.status!.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.accentOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offender.status!.toUpperCase(),
                    style: TextStyle(
                      color: appColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Age
                    if (offender.birthDate != null) ...<Widget>[
                      _buildDetailRow(
                        context,
                        'AGE',
                        offender.age,
                        Icons.cake,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // City
                    _buildDetailRow(
                      context,
                      'CITY',
                      offender.city.toUpperCase(),
                      Icons.location_city,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    _buildDetailRow(
                      context,
                      'ADDRESS',
                      offender.address.toUpperCase(),
                      Icons.home,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final appColors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: 20,
          color: appColors.primaryPurple,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: appColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: appColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


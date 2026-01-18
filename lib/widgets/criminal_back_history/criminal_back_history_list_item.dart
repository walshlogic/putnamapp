import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/criminal_back_history.dart';

/// List item widget for displaying a criminal back history case
class CriminalBackHistoryListItem extends StatelessWidget {
  const CriminalBackHistoryListItem({
    required this.caseRecord,
    required this.onTap,
    super.key,
  });

  final CriminalBackHistory caseRecord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final styles = context.personCardStyles;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Icon placeholder (criminal cases don't have photos)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: appColors.lightPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.gavel,
                  color: appColors.accentOrange,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Case details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      caseRecord.clerkFileDateString ?? 'NO DATE',
                      style: styles.subtitleStyle.copyWith(
                        color: appColors.accentOrange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caseRecord.fullName,
                      style: styles.nameStyle.copyWith(
                        color: appColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      caseRecord.statuteDescriptionShort.toUpperCase(),
                      style: styles.detailStyle.copyWith(
                        color: appColors.textMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (caseRecord.city != null && caseRecord.city!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        caseRecord.city!.toUpperCase(),
                        style: styles.detailStyle.copyWith(
                          color: appColors.textMedium,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron icon
              Icon(
                Icons.chevron_right,
                color: appColors.divider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


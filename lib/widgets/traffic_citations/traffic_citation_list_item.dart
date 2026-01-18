import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/traffic_citation.dart';

/// List item widget for displaying a traffic citation
class TrafficCitationListItem extends StatelessWidget {
  const TrafficCitationListItem({
    required this.citation,
    required this.onTap,
    super.key,
  });

  final TrafficCitation citation;
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
              // Icon placeholder (traffic citations don't have photos)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: appColors.lightPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.traffic,
                  color: appColors.primaryPurple,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Citation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      citation.citationDateString,
                      style: styles.subtitleStyle.copyWith(
                        color: appColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      citation.fullName,
                      style: styles.nameStyle.copyWith(
                        color: appColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      citation.violationDescription.toUpperCase(),
                      style: styles.detailStyle.copyWith(
                        color: appColors.textMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (citation.city != null && citation.city!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        citation.city!.toUpperCase(),
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


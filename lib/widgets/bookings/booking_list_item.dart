import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/booking.dart';

/// List item widget for displaying a booking
class BookingListItem extends StatelessWidget {
  const BookingListItem({
    required this.booking,
    required this.onTap,
    super.key,
  });

  final JailBooking booking;
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
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  booking.photoUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  cacheWidth: 120, // Cache at 2x for retina, but limit memory
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: context.appColors.lightPurple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.person,
                        color: context.appColors.primaryPurple,
                        size: 30,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: context.appColors.lightPurple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: context.appColors.primaryPurple,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Booking details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      booking.bookingDateString,
                      style: styles.subtitleStyle.copyWith(
                        color: appColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.name,
                      style: styles.nameStyle.copyWith(
                        color: appColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.charges.join(', ').toUpperCase(),
                      style: styles.detailStyle.copyWith(
                        color: appColors.textMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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


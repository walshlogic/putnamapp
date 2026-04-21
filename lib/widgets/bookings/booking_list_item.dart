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
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Photo — fixed large size, flush to card edge
            SizedBox(
              width: 150,
              height: 150,
              child: Image.network(
                booking.photoUrl,
                fit: BoxFit.cover,
                cacheWidth: 300,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: appColors.lightPurple,
                    child: Icon(
                      Icons.person,
                      color: appColors.primaryPurple,
                      size: 60,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: appColors.lightPurple,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: appColors.primaryPurple,
                      ),
                    ),
                  );
                },
              ),
            ),

              // Booking details — only this side has margin
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
              ),

              // Chevron icon
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.chevron_right,
                  color: appColors.divider,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

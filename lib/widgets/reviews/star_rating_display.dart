import 'package:flutter/material.dart';

/// Read-only star rating display widget
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({
    required this.rating,
    this.size = 16.0,
    this.color,
    this.showValue = false,
    this.valueStyle,
    super.key,
  });

  final double rating; // 0.0 to 5.0
  final double size;
  final Color? color;
  final bool showValue;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber[600]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...List.generate(5, (index) {
          final starValue = index + 1;
          
          if (rating >= starValue) {
            // Full star
            return Icon(
              Icons.star,
              size: size,
              color: starColor,
            );
          } else if (rating >= starValue - 0.5) {
            // Half star
            return Icon(
              Icons.star_half,
              size: size,
              color: starColor,
            );
          } else {
            // Empty star
            return Icon(
              Icons.star_border,
              size: size,
              color: starColor.withValues(alpha: 0.3),
            );
          }
        }),
        if (showValue) ...<Widget>[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: valueStyle ?? Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}


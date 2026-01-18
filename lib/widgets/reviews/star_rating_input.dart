import 'package:flutter/material.dart';

/// Interactive star rating input widget for writing reviews
class StarRatingInput extends StatefulWidget {
  const StarRatingInput({
    required this.onRatingChanged,
    this.initialRating = 0,
    this.size = 40.0,
    this.color,
    super.key,
  });

  final ValueChanged<int> onRatingChanged;
  final int initialRating; // 0 to 5
  final double size;
  final Color? color;

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  void _setRating(int rating) {
    setState(() {
      _currentRating = rating;
    });
    widget.onRatingChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    final starColor = widget.color ?? Colors.amber[600]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = starValue <= _currentRating;

        return GestureDetector(
          onTap: () => _setRating(starValue),
          child: Icon(
            isSelected ? Icons.star : Icons.star_border,
            size: widget.size,
            color: isSelected ? starColor : starColor.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}


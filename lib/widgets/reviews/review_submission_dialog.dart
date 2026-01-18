import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/place.dart';
import '../../providers/review_providers.dart';
import 'star_rating_input.dart';

/// Dialog for submitting a review (Gold tier only)
class ReviewSubmissionDialog extends ConsumerStatefulWidget {
  const ReviewSubmissionDialog({
    required this.place,
    super.key,
  });

  final Place place;

  @override
  ConsumerState<ReviewSubmissionDialog> createState() =>
      _ReviewSubmissionDialogState();
}

class _ReviewSubmissionDialogState
    extends ConsumerState<ReviewSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isAnonymous = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Submit review
    await ref.read(reviewSubmissionProvider.notifier).submitReview(
          placeId: widget.place.id,
          rating: _rating,
          comment: _commentController.text.trim(),
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          isAnonymous: _isAnonymous,
        );

    // Check submission state
    final submissionState = ref.read(reviewSubmissionProvider);

    submissionState.when(
      data: (review) {
        if (review != null) {
          // Success!
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Review submitted! It will appear after admin approval.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
            // Invalidate reviews to refresh
            ref.invalidate(placeReviewsProvider(widget.place.id));
          }
        }
      },
      loading: () {
        // Still loading, wait
      },
      error: (error, _) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final submissionState = ref.watch(reviewSubmissionProvider);
    final isSubmitting = submissionState.isLoading;

    return AlertDialog(
      title: Text(
        'Write a Review',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: appColors.textDark,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Place name
              Text(
                widget.place.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: appColors.textMedium,
                ),
              ),
              const SizedBox(height: 16),

              // Star Rating
              Text(
                'Rating *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: appColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: StarRatingInput(
                  initialRating: _rating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title (optional)
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  labelStyle: TextStyle(color: appColors.textMedium),
                  hintText: 'e.g., Great food and service!',
                  hintStyle: TextStyle(color: appColors.textLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appColors.accentTeal),
                  ),
                ),
                maxLength: 60,
              ),
              const SizedBox(height: 12),

              // Comment (required)
              TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Review *',
                  labelStyle: TextStyle(color: appColors.textMedium),
                  hintText: 'Share your experience...',
                  hintStyle: TextStyle(color: appColors.textLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appColors.accentTeal),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write a review';
                  }
                  if (value.trim().length < 10) {
                    return 'Review must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Anonymous checkbox
              CheckboxListTile(
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
                title: Text(
                  'Post anonymously',
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.textDark,
                  ),
                ),
                subtitle: Text(
                  'Your name will not be displayed with this review',
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.textLight,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              const SizedBox(height: 8),
              Text(
                '* Required fields',
                style: TextStyle(
                  fontSize: 11,
                  color: appColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isSubmitting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text(
            'Cancel',
            style: TextStyle(color: appColors.textMedium),
          ),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: appColors.accentTeal,
            foregroundColor: appColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Submit Review',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}


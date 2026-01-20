import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../extensions/build_context_extensions.dart';
import '../models/booking.dart';
import '../providers/booking_comment_providers.dart';
import '../widgets/putnam_app_bar.dart';

class BookingCommentCreateScreen extends ConsumerStatefulWidget {
  const BookingCommentCreateScreen({required this.booking, super.key});

  final JailBooking booking;

  @override
  ConsumerState<BookingCommentCreateScreen> createState() =>
      _BookingCommentCreateScreenState();
}

class _BookingCommentCreateScreenState
    extends ConsumerState<BookingCommentCreateScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveComment() async {
    if (_isSaving) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = 'Please enter a comment.';
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final repository = ref.read(bookingCommentRepositoryProvider);
      await repository.submitComment(booking: widget.booking, comment: text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Failed to save comment. Please try again.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'ADD COMMENT',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.booking.name.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: appColors.textLight),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Write your comment...',
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveComment,
            child: Text(_isSaving ? 'SAVING...' : 'POST COMMENT'),
          ),
        ],
      ),
    );
  }
}

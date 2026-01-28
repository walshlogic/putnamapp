import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../extensions/build_context_extensions.dart';
import '../models/booking_comment.dart';
import '../providers/booking_comment_providers.dart';
import '../widgets/putnam_app_bar.dart';

class BookingCommentEditScreen extends ConsumerStatefulWidget {
  const BookingCommentEditScreen({required this.comment, super.key});

  final BookingComment comment;

  @override
  ConsumerState<BookingCommentEditScreen> createState() =>
      _BookingCommentEditScreenState();
}

class _BookingCommentEditScreenState
    extends ConsumerState<BookingCommentEditScreen> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.comment.comment);
  }

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
      await repository.editComment(
        currentComment: widget.comment,
        updatedComment: text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Failed to update comment. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update comment: $e')),
      );
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
            'EDIT COMMENT',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.comment.personName.toUpperCase(),
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
              hintText: 'Update your comment...',
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveComment,
            child: Text(_isSaving ? 'SAVING...' : 'SAVE CHANGES'),
          ),
        ],
      ),
    );
  }
}

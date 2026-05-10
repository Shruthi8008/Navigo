import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentDialog extends ConsumerStatefulWidget {
  const CommentDialog({
    super.key,
    required this.title,
    required this.onSubmit,
  });

  final String title;
  final Future<void> Function(String comment) onSubmit;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Future<void> Function(String comment) onSubmit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CommentDialog(
        title: title,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  ConsumerState<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends ConsumerState<CommentDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    
    Navigator.of(context).pop();
    await widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 5,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Comment',
          border: OutlineInputBorder(),
        ),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _handleSubmit(),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Post'),
        ),
      ],
    );
  }
}

class RatingDialog extends ConsumerStatefulWidget {
  const RatingDialog({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialRating,
  });

  final String title;
  final Future<void> Function(String rating, String? comment) onSubmit;
  final String? initialRating;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Future<void> Function(String rating, String? comment) onSubmit,
    String? initialRating,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        title: title,
        onSubmit: onSubmit,
        initialRating: initialRating,
      ),
    );
  }

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  late String _selectedRating;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating ?? 'moderate';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    
    Navigator.of(context).pop();
    await widget.onSubmit(
      _selectedRating,
      _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRating,
                items: const [
                  DropdownMenuItem(value: 'safe', child: Text('Safe')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'unsafe', child: Text('Unsafe')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRating = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Optional comment',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
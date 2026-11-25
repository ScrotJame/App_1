import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';

/// Sửa một ô xem trước; trả null khi huỷ.
Future<String?> showFieldEditDialog(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FieldEditDialog(title: title, initial: initial),
  );
}

class _FieldEditDialog extends StatefulWidget {
  const _FieldEditDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_FieldEditDialog> createState() => _FieldEditDialogState();
}

class _FieldEditDialogState extends State<_FieldEditDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(S.of(context).save)),
      ],
    );
  }
}

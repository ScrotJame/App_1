import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../../../database/app_db.dart';
import '../../../generated/l10n.dart';
import '../../scan_vocab/widgets/language_picker_sheet.dart';
import '../draft/scan_card.dart';

typedef CardEdit = ({
  String word,
  String pronunciation,
  String meaning,
  String language,
  Set<int> tagIds,
});

/// Bảng sửa một thẻ; trả null khi đóng mà không lưu.
Future<CardEdit?> showCardEditSheet(
  BuildContext context, {
  required ScanCard card,
  required List<Tag> tags,
}) {
  return showModalBottomSheet<CardEdit>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.vocabPageBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CardEditSheet(card: card, tags: tags),
  );
}

class _CardEditSheet extends StatefulWidget {
  const _CardEditSheet({required this.card, required this.tags});

  final ScanCard card;
  final List<Tag> tags;

  @override
  State<_CardEditSheet> createState() => _CardEditSheetState();
}

class _CardEditSheetState extends State<_CardEditSheet> {
  late final _word = TextEditingController(text: widget.card.word);
  late final _pronunciation =
      TextEditingController(text: widget.card.pronunciation);
  late final _meaning = TextEditingController(text: widget.card.meaning);
  late String _language = widget.card.language;
  late final Set<int> _tagIds = Set<int>.of(widget.card.tagIds);

  @override
  void dispose() {
    _word.dispose();
    _pronunciation.dispose();
    _meaning.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.pop<CardEdit>(context, (
      word: _word.text,
      pronunciation: _pronunciation.text,
      meaning: _meaning.text,
      language: _language,
      tagIds: _tagIds,
    ));
  }

  Future<void> _pickLanguage() async {
    final code =
        await showLanguagePickerSheet(context, selected: _language);
    if (code == null || !mounted) return;
    setState(() => _language = code);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(_word, s.fieldVocabulary, AppColors.vocabPurple),
            const SizedBox(height: 12),
            _buildField(
                _pronunciation, s.fieldPronunciation, AppColors.vocabBlue),
            const SizedBox(height: 12),
            _buildField(_meaning, s.fieldMeaning, AppColors.vocabOrange,
                maxLines: 3),
            const SizedBox(height: 12),
            ActionChip(
              avatar: const Icon(Icons.translate_rounded, size: 16),
              label: Text(_language.isEmpty
                  ? s.scan_choose_language
                  : languageLabelOf(_language)),
              onPressed: _pickLanguage,
            ),
            if (widget.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s.scan_review_tags,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in widget.tags)
                    FilterChip(
                      label: Text(tag.tagName),
                      selected: _tagIds.contains(tag.id),
                      onSelected: (on) => setState(() =>
                          on ? _tagIds.add(tag.id) : _tagIds.remove(tag.id)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vocabIndigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(s.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    Color color, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
      ),
    );
  }
}

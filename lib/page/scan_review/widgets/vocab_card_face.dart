import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../../../database/app_db.dart';
import '../../../generated/l10n.dart';
import '../../scan_vocab/widgets/language_picker_sheet.dart';
import '../draft/scan_card.dart';

/// Mặt thẻ, cùng phong cách thẻ xem trước ở màn thêm từ.
class VocabCardFace extends StatelessWidget {
  const VocabCardFace({
    super.key,
    required this.card,
    required this.tags,
    required this.units,
    required this.duplicate,
    this.onTap,
    this.onUnitTap,
  });

  final ScanCard card;
  final List<Tag> tags;
  final List<UnitsEntry> units;
  final DuplicateKind duplicate;
  final VoidCallback? onTap;
  final VoidCallback? onUnitTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.vocabPurple, AppColors.vocabBlue],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.vocabIndigo.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                s.scan_review_card_label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildMainText(
                card.word.isEmpty ? s.fieldVocabulary : card.word,
                size: 40,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 6),
              _buildMainText(
                card.pronunciation.isEmpty
                    ? s.fieldPronunciation
                    : card.pronunciation,
                size: 16,
              ),
              if (card.pronunciationAuto) ...[
                const SizedBox(height: 6),
                _buildPill(Icons.auto_awesome_rounded,
                    s.scan_review_auto_badge),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Colors.white.withValues(alpha: 0.25)),
              ),
              _buildMainText(
                card.meaning.isEmpty ? s.fieldMeaning : card.meaning,
                size: 18,
                weight: FontWeight.w500,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final tag in tags)
                    if (card.tagIds.contains(tag.id))
                      _buildPill(Icons.sell_rounded, tag.tagName),
                  GestureDetector(
                    onTap: onUnitTap,
                    child: _buildPill(
                        Icons.folder_rounded, _unitTitle(s)),
                  ),
                  if (card.language.isNotEmpty)
                    _buildPill(Icons.translate_rounded,
                        languageLabelOf(card.language)),
                ],
              ),
              if (!card.isComplete)
                _buildWarning(s.scan_review_incomplete),
              if (duplicate == DuplicateKind.stored)
                _buildWarning(s.scan_review_duplicate_stored),
              if (duplicate == DuplicateKind.inDraft)
                _buildWarning(s.scan_review_duplicate_draft),
            ],
          ),
        ),
      ),
    );
  }

  String _unitTitle(S s) {
    for (final unit in units) {
      if (unit.id == card.unitId) return unit.title;
    }
    return s.scan_review_no_unit;
  }

  Widget _buildMainText(String text,
      {required double size, FontWeight weight = FontWeight.w400}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white, fontSize: size, fontWeight: weight),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWarning(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.kAmberBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kAmberBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: AppColors.kAmberText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.kAmberText, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

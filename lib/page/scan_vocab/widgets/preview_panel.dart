import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../../../commons/enums.dart';
import '../../../generated/l10n.dart';
import '../scan_vocab_cubit.dart';
import 'language_picker_sheet.dart';
import 'scan_role_style.dart';

/// Ngôn ngữ, ba ô Từ / Âm / Nghĩa và các nút thêm thẻ, duyệt thẻ.
class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.state,
    required this.cardCount,
    required this.onPickLanguage,
    required this.onEdit,
    required this.onClearRole,
    required this.onClearAll,
    required this.onAdd,
    required this.onReview,
  });

  final ScanVocabState state;
  final int cardCount;
  final VoidCallback onPickLanguage;
  final ValueChanged<TokenRole> onEdit;
  final ValueChanged<TokenRole> onClearRole;
  final VoidCallback onClearAll;
  final VoidCallback onAdd;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final preview = state.currentPreview;
    final language = state.detectedLanguage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: Icon(
                state.isLanguageManuallySet
                    ? Icons.lock_rounded
                    : Icons.translate_rounded,
                size: 14,
                color: AppColors.vocabIndigo,
              ),
              label: Text(language == null
                  ? s.scan_choose_language
                  : languageLabelOf(language)),
              backgroundColor: Colors.white,
              onPressed: onPickLanguage,
            ),
          ),
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(TokenRole.word, preview.word),
                const SizedBox(width: 8),
                _buildField(
                    TokenRole.pronunciation, preview.pronunciation),
                const SizedBox(width: 8),
                _buildField(TokenRole.meaning, preview.meaning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (state.hasAnySelection) ...[
                IconButton.outlined(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.clear_rounded, size: 20),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(s.scan_add_card),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vocabIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (cardCount > 0) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onReview,
              icon: const Icon(Icons.style_rounded, size: 20),
              label: Text(s.scan_review_cards(cardCount)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(TokenRole role, String value) {
    final color = scanRoleColor(role);
    final hasValue = value.isNotEmpty;
    return Expanded(
      child: GestureDetector(
        onTap: () => onEdit(role),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withValues(alpha: hasValue ? 0.9 : 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(scanRoleLabel(role),
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700)),
                  ),
                  if (hasValue)
                    GestureDetector(
                      onTap: () => onClearRole(role),
                      child:
                          Icon(Icons.close_rounded, size: 16, color: color),
                    )
                  else
                    Icon(Icons.edit_rounded, size: 12, color: color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hasValue ? value : '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasValue ? Colors.black87 : Colors.black26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

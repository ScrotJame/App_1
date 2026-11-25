import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../commons/app_colors.dart';
import '../../commons/enums.dart';
import '../../generated/l10n.dart';
import 'draft/scan_card.dart';
import 'scan_draft_cubit.dart';
import 'widgets/card_edit_sheet.dart';
import 'widgets/deck_actions.dart';
import 'widgets/deck_summary.dart';
import 'widgets/swipe_deck.dart';
import 'widgets/unit_picker_sheet.dart';
import 'widgets/vocab_card_face.dart';

/// Duyệt các thẻ quét được. Trả `true` khi luồng quét đã xong (đã lưu, hoặc
/// đã bỏ hết thẻ). Quay lại bằng nút Back giữ nguyên thẻ.
class ScanReviewPage extends StatefulWidget {
  const ScanReviewPage({super.key});

  @override
  State<ScanReviewPage> createState() => _ScanReviewPageState();
}

class _ScanReviewPageState extends State<ScanReviewPage> {
  late final ScanDraftCubit _cubit = context.read<ScanDraftCubit>();
  StreamSubscription<String>? _messageSub;

  @override
  void initState() {
    super.initState();
    _messageSub = _cubit.messageController.listen((message) {
      if (mounted) _showSnack(message, AppColors.kRed);
    });
    _cubit.load();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _edit(ScanCard card) async {
    final edit = await showCardEditSheet(context,
        card: card, tags: _cubit.state.tags);
    if (edit == null || !mounted) return;
    await _cubit.editCard(
      card.id,
      word: edit.word,
      pronunciation: edit.pronunciation,
      basePronunciation: card.pronunciation,
      meaning: edit.meaning,
      language: edit.language,
      tagIds: edit.tagIds,
    );
  }

  Future<void> _pickUnit(ScanCard card) async {
    final choice = await showUnitPickerSheet(context,
        units: _cubit.state.units, selected: card.unitId);
    if (choice == null || !mounted) return;
    await _cubit.setUnit(card.id, choice.unitId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScanDraftCubit, ScanDraftState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus &&
          current.saveStatus == LOADSTATUS.SUCCESS,
      listener: (context, state) {
        _showSnack(S.of(context).batch_saved_count(state.savedCount),
            AppColors.kGreen);
        context.pop(true);
      },
      child: BlocSelector<ScanDraftCubit, ScanDraftState, bool>(
        selector: (state) => state.isSaving,
        // Đang lưu thì không cho quay lại: màn này phải còn để nhận kết quả
        // lưu và đóng màn quét.
        builder: (context, isSaving) => PopScope(
          canPop: !isSaving,
          child: Scaffold(
            backgroundColor: AppColors.vocabPageBg,
            appBar: AppBar(
              backgroundColor: AppColors.vocabPageBg,
              elevation: 0,
              centerTitle: true,
              title: Text(
                S.of(context).scan_review_title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
            ),
            body: SafeArea(
              child: BlocBuilder<ScanDraftCubit, ScanDraftState>(
                builder: (context, state) => _buildBody(state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ScanDraftState state) {
    if (state.loadStatus == LOADSTATUS.FAILED) {
      return Center(
        child: FilledButton(
          onPressed: _cubit.load,
          child: Text(S.of(context).scan_review_retry),
        ),
      );
    }
    if (state.loadStatus != LOADSTATUS.SUCCESS) {
      return const Center(child: CircularProgressIndicator());
    }
    final card = state.draft.current;
    if (card == null) {
      return DeckSummary(
        keptCount: state.draft.kept.length,
        discardedCount: state.draft.discardedCount,
        isSaving: state.isSaving,
        onSave: _cubit.save,
        onExit: () => context.pop(true),
        onUndo: state.draft.canUndo ? _cubit.undo : null,
      );
    }
    return _buildDeck(state, card);
  }

  Widget _buildDeck(ScanDraftState state, ScanCard card) {
    final s = S.of(context);
    final total = state.draft.cards.length;
    final position = total - state.draft.pending.length + 1;
    final next = state.draft.next;
    return Column(
      children: [
        Text(
          s.scan_review_progress(position, total),
          style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: SwipeDeck(
              key: ValueKey(card.id),
              canKeep: state.canKeep && card.isComplete,
              keepLabel: s.scan_review_keep,
              discardLabel: s.scan_review_discard,
              onKeep: () => _cubit.keep(card.id),
              onDiscard: () => _cubit.discard(card.id),
              // Cubit tự báo lý do khi thẻ thiếu chữ.
              onKeepBlocked: () => _cubit.keep(card.id),
              behind: next == null
                  ? null
                  : VocabCardFace(
                      card: next,
                      tags: state.tags,
                      units: state.units,
                      duplicate: state.duplicateOf(next.id),
                    ),
              child: VocabCardFace(
                card: card,
                tags: state.tags,
                units: state.units,
                duplicate: state.duplicateOf(card.id),
                onTap: () => _edit(card),
                onUnitTap: () => _pickUnit(card),
              ),
            ),
          ),
        ),
        DeckActions(
          onDiscard: () => _cubit.discard(card.id),
          onUndo: state.draft.canUndo ? _cubit.undo : null,
          onEdit: () => _edit(card),
          onKeep: state.canKeep ? () => _cubit.keep(card.id) : null,
        ),
      ],
    );
  }
}

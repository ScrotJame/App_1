import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../commons/app_colors.dart';
import '../../commons/enums.dart';
import '../../generated/l10n.dart';
import '../../repository/tag_repository.dart';
import '../../repository/unit_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../../router/router.dart';
import '../../service/pronunciation_service.dart';
import '../scan_review/scan_draft_cubit.dart';
import 'scan_vocab_cubit.dart';
import 'widgets/empty_scan_view.dart';
import 'widgets/field_edit_dialog.dart';
import 'widgets/language_picker_sheet.dart';
import 'widgets/ocr_image_view.dart';
import 'widgets/preview_panel.dart';
import 'widgets/role_selector.dart';
import 'widgets/scan_role_style.dart';

/// Chọn chữ trên ảnh để tạo thẻ. Trả `true` khi đã lưu ít nhất một từ, để
/// màn gọi nạp lại; bỏ hết thẻ rồi thoát thì trả `false`.
class ScanVocabPage extends StatelessWidget {
  /// Unit mặc định của thẻ; null là không thuộc Unit nào.
  final int? unitId;

  const ScanVocabPage({super.key, this.unitId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ScanVocabCubit()),
        BlocProvider(
          create: (context) => ScanDraftCubit(
            context.read<VocabularyRepository>(),
            context.read<TagRepository>(),
            context.read<UnitRepository>(),
            context.read<PronunciationService>(),
            defaultUnitId: unitId,
          ),
        ),
      ],
      child: const _ScanVocabView(),
    );
  }
}

class _ScanVocabView extends StatefulWidget {
  const _ScanVocabView();

  @override
  State<_ScanVocabView> createState() => _ScanVocabViewState();
}

class _ScanVocabViewState extends State<_ScanVocabView> {
  File? _imageFile;

  late final ScanVocabCubit _scan = context.read<ScanVocabCubit>();
  late final ScanDraftCubit _draft = context.read<ScanDraftCubit>();

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked =
          await ImagePicker().pickImage(source: source, imageQuality: 90);
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      setState(() => _imageFile = file);
      await _scan.runOcr(file);
    } catch (e) {
      if (!mounted) return;
      _showSnack(S.of(context).error_generic(e.toString()), AppColors.kRed);
    }
  }

  void _addCard() {
    final item = _scan.takeCurrentItem();
    if (item == null) {
      _showSnack(
          S.of(context).scan_need_word_or_meaning, AppColors.kAmber);
      return;
    }
    _draft.addCard(item);
    _showSnack(
        S.of(context).scan_card_added(_draft.state.draft.cards.length),
        AppColors.kGreen);
  }

  Future<void> _openReview() async {
    final done =
        await context.push<bool>(Routes.scanReview, extra: _draft);
    // Luồng đã xong: báo cho màn gọi chỉ khi thật sự có từ được lưu.
    if (done == true && mounted) _close(_draft.state.savedCount > 0);
  }

  void _close(bool? result) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go(Routes.home);
    }
  }

  Future<void> _editField(TokenRole role) async {
    final preview = _scan.state.currentPreview;
    final value = await showFieldEditDialog(
      context,
      title: scanRoleLabel(role),
      initial: switch (role) {
        TokenRole.word => preview.word,
        TokenRole.pronunciation => preview.pronunciation,
        TokenRole.meaning => preview.meaning,
        TokenRole.none => '',
      },
    );
    if (value == null || !mounted) return;
    _scan.editField(role, value);
  }

  Future<void> _pickLanguage() async {
    final code = await showLanguagePickerSheet(
      context,
      selected: _scan.state.detectedLanguage,
      showAuto: _scan.state.isLanguageManuallySet,
    );
    if (code == null || !mounted) return;
    if (code == kAutoLanguage) {
      await _scan.useAutoLanguage();
    } else {
      _scan.setLanguageManually(code);
    }
  }

  Future<void> _confirmLeave() async {
    final s = S.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.scan_discard_title),
        content: Text(
            s.scan_discard_message(_draft.state.draft.unsavedCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.scan_stay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.kRed),
            child: Text(s.scan_discard_confirm),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _close(null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanDraftCubit, ScanDraftState>(
      builder: (context, draftState) {
        return PopScope(
          canPop: !draftState.hasUnsaved,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            backgroundColor: AppColors.vocabPageBg,
            appBar: AppBar(
              backgroundColor: AppColors.vocabPageBg,
              elevation: 0,
              centerTitle: true,
              title: Text(
                S.of(context).scan_title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
            ),
            body: SafeArea(child: _buildBody(draftState)),
          ),
        );
      },
    );
  }

  Widget _buildBody(ScanDraftState draftState) {
    final cardCount = draftState.draft.cards.length;
    return BlocBuilder<ScanVocabCubit, ScanVocabState>(
      builder: (context, state) {
        final imageFile = _imageFile;
        if (imageFile == null) return EmptyScanView(onPick: _pickImage);
        return Column(
          children: [
            RoleSelector(
              activeRole: state.activeRole,
              onChanged: _scan.setActiveRole,
            ),
            Expanded(
              child: OcrImageView(
                imageFile: imageFile,
                state: state,
                onPick: _pickImage,
              ),
            ),
            PreviewPanel(
              state: state,
              cardCount: cardCount,
              onPickLanguage: _pickLanguage,
              onEdit: _editField,
              onClearRole: _scan.clearRole,
              onClearAll: _scan.clearAllSelections,
              onAdd: _addCard,
              onReview: _openReview,
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/tag_repository.dart';

import '../../commons/app_colors.dart';
import '../../repository/vocabulary_repository.dart';
import 'add_word_cubit.dart';

class AddWordPage extends StatefulWidget {
  final PageType type;
  final VocabularyEntry? initialEntry;

  const AddWordPage({
    super.key,
    this.type = PageType.Add,
    this.initialEntry,
  }) : assert(
  type == PageType.Add || initialEntry != null,
  'initialEntry là bắt buộc khi type = PageType.Put',
  );

  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage>
    with SingleTickerProviderStateMixin {
  late final AddWordCubit _cubit;
  late final AnimationController _cardController;
  late final Animation<double> _cardFadeAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  final _vocabularyController = TextEditingController();
  final _furiganaController = TextEditingController();
  final _meaningController = TextEditingController();

  bool get _isEditMode => widget.type == PageType.Put;

  @override
  void initState() {
    super.initState();
    _cubit = AddWordCubit(
      context.read<VocabularyRepository>(),
      context.read<TagRepository>(),
    );

    if (_isEditMode && widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      _vocabularyController.text = entry.word;
      _furiganaController.text = entry.pronunciation ?? '';
      _meaningController.text = entry.meaning;

      // FIX: loadTags() trước, sau đó mới initForEdit() để tags có sẵn
      // khi selectedTagIds được emit → card hiển thị đúng ngay lần đầu
      _cubit.loadTags().then((_) => _cubit.initForEdit(entry));
    } else {
      _cubit.loadTags();
    }

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _cardFadeAnimation =
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut);

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _cubit.close();
    _cardController.dispose();
    _vocabularyController.dispose();
    _furiganaController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isEditMode) {
      await _cubit.updateWord(widget.initialEntry!.id);
    } else {
      await _cubit.saveWord();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<AddWordCubit, AddWordState>(
        listener: (context, state) {
          if (state.loadstatus == LOADSTATUS.SUCCESS) {
            _showSuccessSnackbar(context);
            if (_isEditMode) {
              Navigator.maybePop(context, true);
            } else {
              _cubit.reset();
              _cubit.loadTags();
              _vocabularyController.clear();
              _furiganaController.clear();
              _meaningController.clear();
            }
          } else if (state.loadstatus == LOADSTATUS.FAILED &&
              state.errorMessage != null) {
            _showErrorSnackbar(context, state.errorMessage!);
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewCard(),
                const SizedBox(height: 24),
                _buildForm(),
                const SizedBox(height: 20),
                _buildTagSection(),
                const SizedBox(height: 32),
                _buildButtonSubmit(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF2F4F8),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.black87, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        _isEditMode ? 'Chỉnh sửa từ' : 'Thêm mới',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border_rounded,
              color: Color(0xFF6B7FD4), size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  // ─── Preview card ─────────────────────────────────────────
  Widget _buildPreviewCard() {
    return BlocBuilder<AddWordCubit, AddWordState>(
      // FIX: thêm selectedTagIds vào buildWhen để card rebuild khi toggle tag
      buildWhen: (prev, curr) =>
      prev.vocabulary != curr.vocabulary ||
          prev.furigana != curr.furigana ||
          prev.meaning != curr.meaning ||
          prev.selectedTagIds != curr.selectedTagIds ||
          prev.tags != curr.tags,
      builder: (context, state) {
        return SlideTransition(
          position: _cardSlideAnimation,
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B6FD4), Color(0xFF5B8DEF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B7FD4).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                children: [
                  Text(
                    'Thẻ từ vựng',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.vocabulary.isNotEmpty
                        ? state.vocabulary
                        : 'Từ vựng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.furigana.isNotEmpty ? state.furigana : 'Phát âm',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                        color: Colors.white.withOpacity(0.25), thickness: 1),
                  ),
                  Text(
                    state.meaning.isNotEmpty ? state.meaning : 'Nghĩa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // FIX: hiển thị tag chips trên card khi có tag được chọn
                  if (state.selectedTagIds.isNotEmpty &&
                      state.tags != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: state.tags!
                          .where((t) =>
                          state.selectedTagIds.contains(t.id))
                          .map(
                            (t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            t.tagName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Form ─────────────────────────────────────────────────
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          label: 'Từ vựng',
          hint: 'Nhập từ vựng',
          controller: _vocabularyController,
          onChanged: _cubit.onVocabularyChanged,
          accentColor: const Color(0xFF6B7FD4),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Phát âm',
          hint: 'Nhập cách phát âm',
          controller: _furiganaController,
          onChanged: _cubit.onFuriganaChanged,
          accentColor: const Color(0xFF5B8DEF),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Nghĩa',
          hint: 'Nhập nghĩa từ',
          controller: _meaningController,
          onChanged: _cubit.onMeaningChanged,
          accentColor: const Color(0xFFF4A261),
          minLines: 2,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required Color accentColor,
    int minLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: minLines,
            maxLines: minLines == 1 ? 1 : null,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Tag section ──────────────────────────────────────────
  Widget _buildTagSection() {
    return BlocBuilder<AddWordCubit, AddWordState>(
      buildWhen: (prev, curr) =>
      prev.tags != curr.tags ||
          prev.selectedTagIds != curr.selectedTagIds,
      builder: (context, state) {
        final tags = state.tags;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7FD4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tag',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
                if (state.selectedTagIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7FD4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.selectedTagIds.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Tag chips
            if (tags == null)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF6B7FD4)),
                ),
              )
            else if (tags.isEmpty)
              Text('Chưa có tag nào',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map((tag) => _buildTagChip(
                  tag: tag,
                  isSelected: state.isTagSelected(tag.id),
                ))
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTagChip({required Tag tag, required bool isSelected}) {
    return GestureDetector(
      onTap: () => _cubit.toggleTag(tag.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B7FD4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B7FD4)
                : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF6B7FD4).withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              tag.tagName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Submit button ────────────────────────────────────────
  Widget _buildButtonSubmit() {
    return BlocBuilder<AddWordCubit, AddWordState>(
      buildWhen: (prev, curr) => prev.loadstatus != curr.loadstatus,
      builder: (context, state) {
        final isLoading = state.loadstatus == LOADSTATUS.LOADING;
        return GestureDetector(
          onTap: isLoading ? null : _onSubmit,
          child: AnimatedScale(
            scale: isLoading ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _isEditMode
                    ? AppColors.blueGradient
                    : AppColors.greenGradient,
                boxShadow: [
                  BoxShadow(
                    color: (_isEditMode
                        ? const Color(0xFF1A4FA8)
                        : const Color(0xFF2A7A1C))
                        .withOpacity(0.7),
                    blurRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: (_isEditMode
                        ? const Color(0xFF4A8DEF)
                        : const Color(0xFF50C040))
                        .withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
                    : Text(
                  _isEditMode ? 'Cập nhật' : 'Lưu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Snackbars ────────────────────────────────────────────
  void _showSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode
            ? 'Cập nhật từ thành công!'
            : 'Đã thêm từ mới thành công!'),
        backgroundColor: const Color(0xFF50C040),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/helper/language_helper.dart';

import '../../models/tag_vocab.dart';
import '../../models/unit_entity.dart';
import '../../repository/unit_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../add_word/add_word_cubit.dart';
import '../add_word/add_word_page.dart';
import '../scan_vocab/scan_vocab_page.dart';
import '../widgets/app_gradient_header.dart';
import '../widgets/drop_down_widget.dart';
import 'list_word_cubit.dart';
///use
//Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ListWordPage(unit: unitWithWords),
//       ),
//     );

class ListWordPage extends StatefulWidget {
  final UnitWithWords? unit;

  const ListWordPage({super.key, this.unit});

  @override
  State<ListWordPage> createState() => _ListWordPageState();
}

class _ListWordPageState extends State<ListWordPage> {

  late final ListWordCubit _cubit;
  final _menuKey = GlobalKey();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.unit != null) {
      // Unit mode: dùng named constructor, watch stream DB realtime
      _cubit = ListWordCubit.forUnit(
        context.read<VocabularyRepository>(),
        context.read<UnitRepository>(),
        widget.unit!.unit.id,
      );
      _cubit.watchUnit();
    } else {
      _cubit = ListWordCubit(context.read<VocabularyRepository>());
      _cubit.loadWords();
      _cubit.getLanguageTags();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditPage(VocabularyEntry word) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddWordPage(type: PageType.Put, initialEntry: word),
      ),
    );
    // Stream tự cập nhật sau khi edit/delete trong unit mode
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ListWordCubit, ListWordState>(
        listenWhen: (prev, curr) =>
        curr.loadstatus == LOADSTATUS.FAILED && curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage ?? ''),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: RefreshIndicator(
            onRefresh: () async {
              if (widget.unit == null) {
                await Future.wait([_cubit.loadWords(), _cubit.getLanguageTags()]);
              }
              // Unit mode: stream tự cập nhật, không cần làm gì
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (widget.unit == null)...
                [_buildFilterBar()]
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: BlocBuilder<ListWordCubit, ListWordState>(
                      buildWhen: (p, c) => p.unitWordCount != c.unitWordCount,
                      builder: (context, state) => Text(
                        '${state.unitWordCount} từ vựng',
                        style: TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ),
                  ),
                ],
                Expanded(child: _buildWordList()),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return BlocBuilder<ListWordCubit, ListWordState>(
      buildWhen: (prev, curr) =>
      prev.isSearching != curr.isSearching ||
          prev.totalCount != curr.totalCount,
      builder: (context, state) {
        final topPadding = MediaQuery.of(context).padding.top;
        return AppGradientHeader(
          height: topPadding + 110,
          gradientColors: const [Color(0xFF7B8FE0), Color(0xFF5B6EC7)],
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(
                !state.isSearching)...[
                  IconButton(
                    icon: Icon( Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),],
                Expanded(
                  child: state.isSearching
                      ? _buildSearchField()
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.unit?.unit.title ?? 'Vocabulary List', // ← MỚI
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    state.isSearching
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    _cubit.toggleSearch();
                    if (state.isSearching) _searchController.clear();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      onChanged: _cubit.onSearchChanged,
      style: const TextStyle(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm từ vựng...',
        hintStyle: const TextStyle(color: Colors.white60, fontSize: 15),
        border: InputBorder.none,
        prefixIcon:
        const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
        prefixIconConstraints:
        const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  // ─── Filter bar ───────────────────────────────────────────
  Widget _buildFilterBar() {
    return BlocBuilder<ListWordCubit, ListWordState>(
      buildWhen: (prev, curr) =>
      prev.languageTags != curr.languageTags ||
          prev.activeLanguage != curr.activeLanguage, // ← fix buildWhen
      builder: (context, state) {
        final tabs = [null, ...state.languageTags];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: tabs
                .map(
                  (tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  label: LanguageHelper.getDetectedLanguageLabelTag(tag),
                  tag: tag,
                  activeLanguage: state.activeLanguage,
                ),
              ),
            )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? tag,
    String? activeLanguage,
  }) {
    final isActive = tag == activeLanguage;
    return GestureDetector(
      onTap: () => _cubit.onLanguageChanged(tag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6B7FD4) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  // ─── Word list ────────────────────────────────────────────
  Widget _buildWordList() {
    return BlocBuilder<ListWordCubit, ListWordState>(
      builder: (context, state) {
        if (state.loadstatus == LOADSTATUS.LOADING) {
          return const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF6B7FD4), strokeWidth: 2.5),
          );
        }
        if (state.filteredWords.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: state.filteredWords.length,
          itemBuilder: (context, index) =>
              _buildWordCard(state.filteredWords[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Chưa có từ vựng nào',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Nhấn + để thêm từ mới',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─── Word card ────────────────────────────────────────────
  Widget _buildWordCard(VocabularyWithTags item) {
    final word = item.word;
    final tags = item.tags;
    final _cardKey = GlobalKey();

    return GestureDetector(
      onTap: () => _showWordMenu(context, _cardKey, item),
      child: Container(
        key: _cardKey,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildWordContent(word, tags ??[])),
              const SizedBox(width: 8),
              _buildCardActions(word),
            ],
          ),
        ),
      ),
    );
  }

  void _showWordMenu(
      BuildContext context,
      GlobalKey anchorKey,
      VocabularyWithTags item,
      ) {
    final word = item.word;

    bool preferAbove = false;
    final renderBox =
    anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final itemOffset = renderBox.localToGlobal(Offset.zero);
      final itemBottom = itemOffset.dy + renderBox.size.height;
      final screenHeight = MediaQuery.of(context).size.height;
      const estimatedMenuHeight = 180.0;
      preferAbove = (screenHeight - itemBottom) < estimatedMenuHeight;
    }

    DropDownWidget.show(
      context: context,
      anchorKey: anchorKey,
      alignRight: true,
      preferAbove: preferAbove,
      items: [
        DropDownItem(
          label: 'Chỉnh sửa',
          icon: CupertinoIcons.pencil,
          onTap: () => _openEditPage(word),
        ),
        DropDownItem(
          label: word.isFavorite == true
              ? 'Bỏ đánh dấu học'
              : 'Đánh dấu đã học',
          icon: word.isFavorite == true
              ? CupertinoIcons.star_slash
              : CupertinoIcons.star,
          onTap: () => {

          },
        ),
        DropDownItem(
          label: 'Phát âm',
          icon: CupertinoIcons.volume_up,
          onTap: () {
            // TODO: TTS
          },
        ),
        DropDownItem(
          label: 'Xóa từ',
          icon: CupertinoIcons.trash,
          isDestructive: true,
          hasDividerAbove: true,
          onTap: () async {
            final confirm = await _confirmDelete(word);
            if (confirm) {
              await _cubit.deleteWord(word.id);
            }
          },
        ),
      ],
    );
  }

  Widget _buildWordContent(VocabularyEntry word, List<Tag> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            ...tags.map((tag) => _buildBadge(tag.tagName)),
          ],
        ),
        // Pronunciation
        if (word.pronunciation != null && word.pronunciation!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            word.pronunciation!,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 6),
        // Meaning
        Text(
          word.meaning,
          style: const TextStyle(
              fontSize: 14, color: Colors.black87, height: 1.4),
        ),
        // Example
        if (word.example != null && word.example!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '"${word.example}"',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(String label) {
    // JLPT tag (N1-N5) → tím, còn lại → xám
    final isJlpt = RegExp(r'^N[1-5]$').hasMatch(label);
    final color = isJlpt ? const Color(0xFFE8E3FF) : const Color(0xFFE8E8E8);
    final textColor =
    isJlpt ? const Color(0xFF6B7FD4) : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _buildCardActions(VocabularyEntry word) {
    final isFavorite = word.isFavorite == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.volume_up_rounded,
              color: Colors.grey.shade400, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            // TODO: integrate TTS
          },
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _cubit.toggleLearned(word.id),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              key: ValueKey(isFavorite),
              color:
              isFavorite ? const Color(0xFF6B7FD4) : Colors.grey.shade400,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline_rounded,
          color: Colors.redAccent, size: 24),
    );
  }

  // ─── FAB ──────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () async {
        final added = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddWordPage(
              unitId: widget.unit?.unit.id, // null = add tổng, non-null = add vào unit
            ),
          ),
        );
        // Fallback reload: nếu stream không tự emit (do UnitRepository
        // không watch bảng word_unit), reload thủ công sau khi thêm từ.
        if (added == true && widget.unit != null) {
          await _cubit.reloadUnit();
        } else if (added == true && widget.unit == null) {
          await _cubit.loadWords();
        }
      },
      backgroundColor: const Color(0xFF6B7FD4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    );
  }

  // ─── Confirm delete ───────────────────────────────────────
  Future<bool> _confirmDelete(VocabularyEntry word) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa từ vựng',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xóa "${word.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    ) ??
        false;
  }
}
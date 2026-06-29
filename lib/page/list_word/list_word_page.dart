import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/helper/language_helper.dart';

import '../../commons/app_images.dart';
import '../../generated/l10n.dart';
import '../../models/tag_vocab.dart';
import '../../models/unit_entity.dart';
import '../../repository/unit_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../../router/router.dart';
import '../add_word/add_word_cubit.dart';
import '../add_word/add_word_page.dart';
import '../scan_vocab/scan_vocab_page.dart';
import '../widgets/app_gradient_header.dart';
import '../widgets/drop_down_widget.dart';
import 'list_word_cubit.dart';


class ListWordPage extends StatefulWidget {
  final UnitWithWords? unit;

  const ListWordPage({super.key, this.unit});

  @override
  State<ListWordPage> createState() => _ListWordPageState();
}

class _ListWordPageState extends State<ListWordPage> {

  late final ListWordCubit _cubit;
  final _searchController = TextEditingController();
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.unit != null) {
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
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddWordPage(type: PageType.Put, initialEntry: word),
      ),
    );
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
        child: BlocBuilder<ListWordCubit, ListWordState>(
          buildWhen: (prev, curr) => prev.isSelectionMode != curr.isSelectionMode,
          builder: (context, state) {
            return Scaffold(
              backgroundColor: const Color(0xFFF5F6FA),
              body: RefreshIndicator(
                onRefresh: () async {
                  if (widget.unit == null) {
                    await Future.wait([_cubit.loadWords(), _cubit.getLanguageTags()]);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header thay đổi theo selection mode
                    state.isSelectionMode
                        ? _buildSelectionHeader()
                        : _buildHeader(),
                    if (!state.isSelectionMode && widget.unit == null)...[
                      _buildFilterBar(),
                    ] else if (!state.isSelectionMode && widget.unit != null)...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: BlocBuilder<ListWordCubit, ListWordState>(
                          buildWhen: (p, c) => p.unitWordCount != c.unitWordCount,
                          builder: (context, state) => Text(
                            '${state.unitWordCount} từ vựng',
                            style: const TextStyle(fontSize: 13, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                    Expanded(child: _buildWordList()),
                  ],
                ),
              ),
              // Bottom bar khi đang chọn
              bottomNavigationBar: state.isSelectionMode
                  ? _buildSelectionBottomBar()
                  : null,
              floatingActionButton: state.isSelectionMode
                  ? null
                  : _buildFAB(),
            );
          },
        ),
      ),
    );
  }

  // ─── Selection Header ───────────────────────────────────────
  Widget _buildSelectionHeader() {
    return BlocBuilder<ListWordCubit, ListWordState>(
      buildWhen: (prev, curr) =>
      prev.selectedWordIds != curr.selectedWordIds ||
          prev.filteredWords != curr.filteredWords,
      builder: (context, state) {
        final topPadding = MediaQuery.of(context).padding.top;
        final allSelected = state.filteredWords.isNotEmpty &&
            state.selectedWordIds.length == state.filteredWords.length;

        return Container(
          padding: EdgeInsets.fromLTRB(8, topPadding + 8, 8, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE57373), Color(0xFFEF5350)],
            ),
          ),
          child: Row(
            children: [
              // Nút đóng
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                onPressed: _cubit.toggleSelectionMode,
              ),
              // Số lượng đã chọn
              Expanded(
                child: Text(
                  S.of(context).selected_count(state.selectedCount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Nút Chọn/Bỏ chọn tất cả
              TextButton.icon(
                onPressed: allSelected ? _cubit.deselectAll : _cubit.selectAll,
                icon: Icon(
                  allSelected ? Icons.deselect : Icons.select_all,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  allSelected
                      ? S.of(context).deselect_all
                      : S.of(context).select_all,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Selection Bottom Bar ──────────────────────────────────
  Widget _buildSelectionBottomBar() {
    return BlocBuilder<ListWordCubit, ListWordState>(
      buildWhen: (prev, curr) => prev.selectedWordIds != curr.selectedWordIds,
      builder: (context, state) {
        if (state.selectedWordIds.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Nút "Thêm vào unit" ──────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAddToUnitSheet(state.selectedCount),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B8FE0), Color(0xFF5B6EC7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B6EC7).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.library_add_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Thêm vào unit (${state.selectedCount})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ── Nút "Xóa" (icon, nhỏ hơn) ────────────────────
              GestureDetector(
                onTap: () => _confirmBatchDelete(state.selectedCount),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFFEBEB),
                    border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.4)),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF5350),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Bottom sheet chọn unit ────────────────────────────────
  Future<void> _showAddToUnitSheet(int selectedCount) async {
    final unitRepo = context.read<UnitRepository>();

    // Load danh sách unit
    List<UnitsEntry> units;
    try {
      units = await unitRepo.getAllUnits();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải danh sách unit'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    if (units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có unit nào. Hãy tạo unit trước.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitPickerSheet(
        units: units,
        selectedCount: selectedCount,
        onUnitSelected: (unit) async {
          Navigator.pop(context); // đóng sheet

          // Trong global list mode, _cubit không có _unitRepo
          // → gọi trực tiếp qua unitRepo từ context
          int added;
          if (widget.unit == null) {
            // Global mode: cubit không có _unitRepo, gọi repo trực tiếp
            added = await unitRepo.addWordsToUnit(
              unitId: unit.id,
              wordIds: _cubit.state.selectedWordIds.toList(),
            );
            _cubit.exitSelectionAfterBatchAdd();
            await _cubit.loadWords();
          } else {
            // Unit mode: cubit có đủ _unitRepo
            added = await _cubit.addSelectedToUnit(unit.id);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  added > 0
                      ? 'Đã thêm $added từ vào "${unit.title}"'
                      : 'Không có từ nào được cập nhật',
                ),
                backgroundColor: added > 0
                    ? const Color(0xFF50C040)
                    : const Color(0xFF9E9E9E),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
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
          height: topPadding + 90,
          gradientColors: const [Color(0xFF7B8FE0), Color(0xFF5B6EC7)],
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(
                !state.isSearching)...[
                  IconButton(
                    icon: const Icon( Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      if (widget.unit != null) {
                        Navigator.pop(context);
                      } else{
                        context.go(Routes.home);
                      }
                    }
                    ,
                  ),],
                Expanded(
                  child: state.isSearching
                      ? _buildSearchField()
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.unit?.unit.title ?? 'Vocabulary List',
                        style: const TextStyle(
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
                InkWell(
                    onTap: (){
                      context.push(Routes.listUnit);
                    },
                    child: SvgPicture.asset(AppImages.icLibraryAdd, width: 24, color: Colors.white,)),
                const SizedBox(width: 16),
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
          prev.activeLanguage != curr.activeLanguage,
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
              _buildWordCard(state.filteredWords[index], state),
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
  Widget _buildWordCard(VocabularyWithTags item, ListWordState state) {
    final word = item.word;
    final tags = item.tags;
    final cardKey = GlobalKey();
    final isSelected = state.isWordSelected(word.id);
    final isSelecting = state.isSelectionMode;

    return GestureDetector(
      onTap: () {
        if (isSelecting) {
          _cubit.toggleWordSelection(word.id);
        } else {
          _showWordMenu(context, cardKey, item);
        }
      },
      onLongPress: () {
        if (!isSelecting) {
          _cubit.toggleSelectionMode();
          _cubit.toggleWordSelection(word.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        key: cardKey,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEDE7F6)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF6B7FD4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox khi ở selection mode
              if (isSelecting) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? const Color(0xFF6B7FD4)
                          : Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
              ],
              Expanded(child: _buildWordContent(word, tags ?? [])),
              if (!isSelecting) ...[
                const SizedBox(width: 8),
                _buildCardActions(word),
              ],
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
          onTap: () {

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

  // ─── FAB ──────────────────────────────────────────────────
  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: _isFabExpanded ? Offset.zero : const Offset(0, 0.3),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isFabExpanded ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_isFabExpanded,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSpeedDialItem(
                    icon: AppImages.icLibrary,
                    label: 'Thư viện từ vựng',
                    onTap: () {
                      setState(() => _isFabExpanded = false);
                      // TODO: mở trang thư viện
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSpeedDialItem(
                    icon: AppImages.icAddCircle,
                    label: 'Thêm từ thủ công',
                    onTap: () async {
                      setState(() => _isFabExpanded = false);
                      final added = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddWordPage(
                            unitId: widget.unit?.unit.id,
                          ),
                        ),
                      );
                      if (added == true && widget.unit != null) {
                        await _cubit.reloadUnit();
                      } else if (added == true && widget.unit == null) {
                        await _cubit.loadWords();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSpeedDialItem(
                    icon: AppImages.icScanFile,
                    label: 'Quét từ vựng',
                    onTap: () async {
                      setState(() => _isFabExpanded = false);
                      final added = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanVocabPage(),
                        ),
                      );
                      if (added == true && widget.unit != null) {
                        await _cubit.reloadUnit();
                      } else if (added == true && widget.unit == null) {
                        await _cubit.loadWords();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // ── Main FAB ──
        FloatingActionButton(
          onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
          backgroundColor: const Color(0xFF6B7FD4),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: _isFabExpanded ? 0.125 : 0,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    String? icon,
    IconData? iconData,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label tooltip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Icon button
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6B7FD4),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B7FD4).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: iconData != null
                  ? Icon(iconData, size: 24, color: Colors.white)
                  : SvgPicture.asset(
                icon ?? '',
                width: 24,
                height: 24,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Confirm delete (single) ───────────────────────────────
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

  // ─── Confirm batch delete ────────────────────────────────
  Future<void> _confirmBatchDelete(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          S.of(context).confirm_batch_delete_title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(S.of(context).confirm_batch_delete_msg(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancel,
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              S.of(context).delete,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deletedCount = await _cubit.deleteSelectedWords();
      if (deletedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).batch_deleted_success(deletedCount)),
            backgroundColor: const Color(0xFF50C040),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Unit Picker Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _UnitPickerSheet extends StatefulWidget {
  final List<UnitsEntry> units;
  final int selectedCount;
  final void Function(UnitsEntry unit) onUnitSelected;

  const _UnitPickerSheet({
    required this.units,
    required this.selectedCount,
    required this.onUnitSelected,
  });

  @override
  State<_UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<_UnitPickerSheet> {
  int? _hoveredId; // highlight khi tap

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.library_add_rounded,
                    color: Color(0xFF6B7FD4), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn unit để thêm',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${widget.selectedCount} từ sẽ được thêm vào unit bạn chọn',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Unit list ──
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                top: 8,
                bottom: bottomPadding + 16,
              ),
              itemCount: widget.units.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final unit = widget.units[index];
                final isHovered = _hoveredId == unit.id;

                return GestureDetector(
                  onTapDown: (_) => setState(() => _hoveredId = unit.id),
                  onTapUp: (_) {
                    setState(() => _hoveredId = null);
                    widget.onUnitSelected(unit);
                  },
                  onTapCancel: () => setState(() => _hoveredId = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    color: isHovered
                        ? const Color(0xFFEDE7F6)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        // Unit icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.folder_outlined,
                            color: Color(0xFF6B7FD4),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Unit info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
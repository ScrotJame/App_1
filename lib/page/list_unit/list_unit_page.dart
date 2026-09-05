import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/components/edit_dialog.dart';

import '../../database/app_db.dart';
import '../../models/unit_entity.dart';
import '../../repository/unit_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../../router/router.dart';
import '../list_word/list_word_page.dart';
import '../widgets/app_gradient_header.dart';
import 'list_unit_cubit.dart';

// Bảng màu cho các unit (lặp vòng nếu > 6 unit)
const _unitColors = [
  Color(0xFF5C6BC0), // indigo
  Color(0xFFF9A825), // amber
  Color(0xFF2E7D32), // green
  Color(0xFF7B1FA2), // purple
  Color(0xFF00838F), // cyan
  Color(0xFFD84315), // deep-orange
];

class ListUnitPage extends StatefulWidget {
  const ListUnitPage({super.key});

  @override
  State<ListUnitPage> createState() => _ListUnitPageState();
}

class _ListUnitPageState extends State<ListUnitPage> {
  late final ListUnitCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = ListUnitCubit(
      context.read<UnitRepository>(),
      context.read<VocabularyRepository>(),
    );
    _cubit.loadUnits();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ListUnitCubit, ListUnitState>(
        listenWhen: (prev, curr) =>
        curr.loadStatus == LOADSTATUS.FAILED &&
            curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage ?? ''),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cubit.loadUnits,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFAB(),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────
  Widget _buildHeader() {
    return BlocBuilder<ListUnitCubit, ListUnitState>(
      buildWhen: (prev, curr) => prev.isSearching != curr.isSearching,
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
                if(!state.isSearching)...[
                  InkWell(
                    onTap: () => context.go(Routes.home),
                    child: Icon(Icons.arrow_back_ios_new, color: Colors.white,)
                  ),
                ],
                const SizedBox(width: 6,),
                Expanded(
                  child: state.isSearching
                      ? _buildSearchField()
                      : Text(
                    'Vocabulary Units',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
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
                      context.push(Routes.listWord);
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
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm unit hoặc từ vựng...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildSortButton() {
    return BlocBuilder<ListUnitCubit, ListUnitState>(
      buildWhen: (prev, curr) => prev.sortOrder != curr.sortOrder,
      builder: (context, state) {
        return PopupMenuButton<UnitSortOrder>(
          icon: const Icon(Icons.tune_rounded, color: Colors.black87, size: 22),
          onSelected: _cubit.onSortChanged,
          itemBuilder: (_) => [
            _sortMenuItem(UnitSortOrder.byId, 'Thứ tự mặc định',
                Icons.format_list_numbered_rounded, state.sortOrder),
            _sortMenuItem(UnitSortOrder.byTitle, 'Theo tên (A-Z)',
                Icons.sort_by_alpha_rounded, state.sortOrder),
            _sortMenuItem(UnitSortOrder.byWordCount, 'Nhiều từ nhất',
                Icons.bar_chart_rounded, state.sortOrder),
          ],
        );
      },
    );
  }

  PopupMenuItem<UnitSortOrder> _sortMenuItem(
      UnitSortOrder value,
      String label,
      IconData icon,
      UnitSortOrder active,
      ) {
    final isActive = value == active;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color:
              isActive ? const Color(0xFF6B7FD4) : Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              color:
              isActive ? const Color(0xFF6B7FD4) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────
  Widget _buildBody() {
    return BlocBuilder<ListUnitCubit, ListUnitState>(
      builder: (context, state) {
        if (state.loadStatus == LOADSTATUS.LOADING) {
          return const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF6B7FD4), strokeWidth: 2.5),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('${state.totalUnitCount} units',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500),
              ),
            ),
            Expanded(
              child: state.filteredUnits.isEmpty
                  ? _buildEmptyState()
                  : _buildUnitList(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnitList(ListUnitState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: state.filteredUnits.length,
      itemBuilder: (context, index) {
        final unitWithWords = state.filteredUnits[index];
        final color = _unitColors[index % _unitColors.length];
        final isExpanded = state.isExpanded(unitWithWords.unit.id);
        return _buildUnitCard(unitWithWords, index + 1, color, isExpanded);
      },
    );
  }

  // ─── Unit card ────────────────────────────────────────────
  Widget _buildUnitCard(
      UnitWithWords item,
      int displayIndex,
      Color color,
      bool isExpanded,
      ) {
    final unit = item.unit;

    return Dismissible(
      key: ValueKey(unit.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (_) async {
        final result = await _confirmDelete(unit.title);
        return result;
      },
      onDismissed: (_) => _cubit.deleteUnit(unit.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header row ──
            InkWell(
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListWordPage(unit: item),
                  ),
                ).then((_) => _cubit.loadUnits());
              },
              //=> _cubit.toggleExpand(unit.id),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Index badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$displayIndex',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + word count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.wordCount} words',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    // Edit button
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 18, color: Colors.grey.shade400),
                      padding: EdgeInsets.zero,
                      constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => showUpdateDialog(
                        context,
                        initialValue: unit.title,
                        tagColor: color,
                        onUpdate: (value) => _cubit.updateUnit(unit.id, value, unit.createdAt, unit.updatedAt),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Word list (expanded) ──
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _buildWordListSection(item, color)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Word list inside unit ────────────────────────────────
  Widget _buildWordListSection(UnitWithWords item, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: Colors.grey.shade100),
        if (item.words.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Chưa có từ vựng nào trong unit này.',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic),
            ),
          )
        else
          ...item.words.map((word) => _buildWordRow(word, accentColor, item.unit.id)),
        _buildAddWordButton(item.unit.id, accentColor),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildWordRow(VocabularyEntry word, Color accentColor, int unitId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (word.pronunciation != null &&
                    word.pronunciation!.isNotEmpty)
                  Text(
                    word.pronunciation!,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              word.meaning,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Nút tháo từ khỏi unit
          IconButton(
            icon: Icon(Icons.link_off_rounded,
                size: 16, color: Colors.grey.shade300),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Tháo khỏi unit',
            onPressed: () async {
              final confirm = await _confirmRemoveWord(word.word);
              if (!mounted) return; // thêm dòng này
              if (confirm) {
                _cubit.removeWordFromUnit(wordId: word.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddWordButton(int unitId, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: OutlinedButton.icon(
        onPressed: () => _showAddWordToUnitDialog(unitId),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(double.infinity, 36),
        ),
        icon: Icon(Icons.add_rounded, size: 16, color: accentColor),
        label: Text(
          'Thêm từ vào unit',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: accentColor),
        ),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Chưa có unit nào',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Nhấn + để tạo unit mới',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─── Dismiss background ───────────────────────────────────
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
      onPressed: _showAddDialog,
      backgroundColor: const Color(0xFF6B7FD4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    );
  }

  // ─── Dialog: Thêm unit ────────────────────────────────────
  void _showAddDialog() {
    _showUnitDialog(
      title: 'Thêm unit mới',
      confirmLabel: 'Thêm',
      onConfirm: (text) => _cubit.addUnit(text),
    );
  }

  void _showEditDialog(
      int id, String currentTitle, DateTime? createdAt, DateTime? updatedAt) {
    _showUnitDialog(
      title: 'Đổi tên unit',
      initialValue: currentTitle,
      confirmLabel: 'Lưu',
      onConfirm: (text) =>
          _cubit.updateUnit(id, text, createdAt, updatedAt),
    );
  }

  void _showUnitDialog({
    required String title,
    String initialValue = '',
    required String confirmLabel,
    required void Function(String) onConfirm,
  }) {
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Tên unit...',
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onConfirm(text);
                Navigator.pop(ctx);
              }
            },
            child: Text(confirmLabel,
                style: const TextStyle(
                    color: Color(0xFF6B7FD4),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── Dialog: Thêm từ vào unit ─────────────────────────────
  void _showAddWordToUnitDialog(int unitId) {
    // Load danh sách từ chưa có unit
    _cubit.loadWordWithoutUnit();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: _cubit,
        child: _AddWordToUnitSheet(
          unitId: unitId,
          cubit: _cubit,
        ),
      ),
    );
  }

  // ─── Confirm dialogs ──────────────────────────────────────
  Future<bool> _confirmDelete(String unitTitle) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa unit',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc muốn xóa "$unitTitle"?\n'
              'Các từ vựng trong unit sẽ KHÔNG bị xóa — chúng chỉ bị tháo khỏi unit này.',
        ),
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

  Future<bool> _confirmRemoveWord(String wordText) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Tháo từ khỏi unit',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Tháo "$wordText" khỏi unit này?\nTừ sẽ không bị xóa, chỉ bị tháo ra khỏi unit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tháo',
                style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    ) ??
        false;
  }
}

class _AddWordToUnitSheet extends StatefulWidget {
  const _AddWordToUnitSheet({
    required this.unitId,
    required this.cubit,
  });

  final int unitId;
  final ListUnitCubit cubit;

  @override
  State<_AddWordToUnitSheet> createState() => _AddWordToUnitSheetState();
}

class _AddWordToUnitSheetState extends State<_AddWordToUnitSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Tab 1: Từ mới ──
  final _wordCtrl = TextEditingController();
  final _meaningCtrl = TextEditingController();
  final _pronCtrl = TextEditingController();

  // ── Tab 2: Chọn từ có sẵn ──
  final _pickSearchCtrl = TextEditingController();
  String _pickQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wordCtrl.dispose();
    _meaningCtrl.dispose();
    _pronCtrl.dispose();
    _pickSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Thêm từ vào unit',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6B7FD4),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6B7FD4),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14),
            tabs: const [
              Tab(text: 'Tạo từ mới'),
              Tab(text: 'Chọn từ có sẵn'),
            ],
          ),
          const Divider(height: 1),
          // Tab content
          SizedBox(
            height: 340,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewWordTab(),
                _buildPickWordTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: tạo từ mới ────────────────────────────────────
  Widget _buildNewWordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          _input(_wordCtrl, 'Từ vựng *', Icons.translate_rounded),
          const SizedBox(height: 12),
          _input(_meaningCtrl, 'Nghĩa *', Icons.menu_book_rounded),
          const SizedBox(height: 12),
          _input(_pronCtrl, 'Phát âm (tuỳ chọn)',
              Icons.record_voice_over_rounded),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitNewWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7FD4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Thêm từ',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _input(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _submitNewWord() {
    final word = _wordCtrl.text.trim();
    final meaning = _meaningCtrl.text.trim();
    if (word.isEmpty || meaning.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập từ vựng và nghĩa'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.cubit.addWordToUnit(
      unitId: widget.unitId,
      word: word,
      meaning: meaning,
      pronunciation: _pronCtrl.text.trim().isEmpty
          ? null
          : _pronCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  // ── Tab 2: chọn từ có sẵn ────────────────────────────────
  Widget _buildPickWordTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _pickSearchCtrl,
            onChanged: (v) => setState(() => _pickQuery = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Tìm từ...',
              prefixIcon: Icon(Icons.search_rounded,
                  size: 18, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<ListUnitCubit, ListUnitState>(
            buildWhen: (prev, curr) =>
            prev.unassignedWords != curr.unassignedWords,
            builder: (context, state) {
              final words = state.unassignedWords.where((w) {
                if (_pickQuery.isEmpty) return true;
                return w.word.toLowerCase().contains(_pickQuery) ||
                    w.meaning.toLowerCase().contains(_pickQuery);
              }).toList();

              if (words.isEmpty) {
                return Center(
                  child: Text(
                    _pickQuery.isEmpty
                        ? 'Không có từ nào chưa thuộc unit'
                        : 'Không tìm thấy từ phù hợp',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: words.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (ctx, i) {
                  final w = words[i];
                  return ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    title: Text(
                      w.word,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      w.meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        widget.cubit.assignExistingWordToUnit(
                          wordId: w.id,
                          unitId: widget.unitId,
                        );
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7FD4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Thêm',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
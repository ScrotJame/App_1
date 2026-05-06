import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/enums.dart';

import '../../database/app_db.dart';
import '../../models/unit_entity.dart';
import '../../repository/unit_repository.dart';
import 'list_unit_cubit.dart';

// Bảng màu cho các unit (lặp vòng nếu > 4 unit)
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
    _cubit = ListUnitCubit(context.read<UnitRepository>());
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
          appBar: _buildAppBar(),
          body: RefreshIndicator(
            onRefresh: _cubit.loadUnits,
            child: _buildBody(),
          ),
          floatingActionButton: _buildFAB(),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: BlocBuilder<ListUnitCubit, ListUnitState>(
        buildWhen: (prev, curr) => prev.isSearching != curr.isSearching,
        builder: (context, state) {
          return AppBar(
            backgroundColor: const Color(0xFFF5F6FA),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: state.isSearching
                ? _buildSearchField()
                : const Text(
              'Vocabulary List',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  state.isSearching
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  color: Colors.black87,
                  size: 22,
                ),
                onPressed: () {
                  _cubit.toggleSearch();
                  if (state.isSearching) _searchController.clear();
                },
              ),
              _buildSortButton(),
              const SizedBox(width: 4),
            ],
          );
        },
      ),
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
              color: isActive
                  ? const Color(0xFF6B7FD4)
                  : Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight:
              isActive ? FontWeight.w700 : FontWeight.normal,
              color: isActive
                  ? const Color(0xFF6B7FD4)
                  : Colors.black87,
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
            _buildSummaryBar(state),
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

  // ─── Summary bar ──────────────────────────────────────────
  Widget _buildSummaryBar(ListUnitState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Text(
            '${state.totalUnitCount} units · ${state.totalWordCount} words',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500),
          ),
          const Spacer(),
          // Expand/Collapse all
          GestureDetector(
            onTap: state.expandedUnitIds.length == state.allUnits.length
                ? _cubit.collapseAll
                : _cubit.expandAll,
            child: Text(
              state.expandedUnitIds.length == state.allUnits.length
                  ? 'Thu gọn tất cả'
                  : 'Mở rộng tất cả',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7FD4)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Unit list ────────────────────────────────────────────
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
      confirmDismiss: (_) => _confirmDelete(unit.title),
      onDismissed: (_) => _cubit.deleteUnit(unit.id),
      child: Container(
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
        child: Column(
          children: [
            // ── Header row ──
            InkWell(
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : BorderRadius.circular(16),
              onTap: () => _cubit.toggleExpand(unit.id),
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
                      onPressed: () => _showEditDialog(
                        unit.id,
                        unit.title,
                        unit.createdAt,
                        unit.updatedAt,
                      ),
                    ),
                    // Expand arrow
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400),
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
    if (item.words.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Text(
          'Chưa có từ vựng nào trong unit này.',
          style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: [
        Divider(height: 1, color: Colors.grey.shade100),
        ...item.words.map(
              (word) => _buildWordRow(word, accentColor),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildWordRow(VocabularyEntry word, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.6),
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
        ],
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

  // ─── Dialogs ──────────────────────────────────────────────
  void _showAddDialog() {
    _showUnitDialog(
      title: 'Thêm unit mới',
      confirmLabel: 'Thêm',
      onConfirm: (text) => _cubit.addUnit(text),
    );
  }

  void _showEditDialog(int id, String currentTitle, DateTime? createdAt ,DateTime updatedAt) {
    _showUnitDialog(
      title: 'Đổi tên unit',
      initialValue: currentTitle,
      confirmLabel: 'Lưu',
      onConfirm: (text) => _cubit.updateUnit(id, text, createdAt, updatedAt),
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

  Future<bool> _confirmDelete(String unitTitle) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa unit',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Bạn có chắc muốn xóa "$unitTitle"?\nTất cả từ vựng trong unit cũng sẽ bị xóa.'),
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
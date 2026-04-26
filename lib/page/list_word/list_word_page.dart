import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';

import '../../repository/vocabulary_repository.dart';
import '../add_word/add_word_page.dart';
import 'list_word_cubit.dart';

class ListWordPage extends StatefulWidget {
  const ListWordPage({super.key});

  @override
  State<ListWordPage> createState() => _ListWordPageState();
}

class _ListWordPageState extends State<ListWordPage> {
  late final ListWordCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = ListWordCubit(context.read<VocabularyRepository>());
    _cubit.loadWords();
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
      child: BlocListener<ListWordCubit, ListWordState>(
        listenWhen: (prev, curr) =>
        curr.loadstatus == LOADSTATUS.FAILED &&
            curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? ''),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: _buildAppBar(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterBar(),
              Expanded(child: _buildWordList()),
            ],
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
      child: BlocBuilder<ListWordCubit, ListWordState>(
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
                  state.isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.black87,
                  size: 22,
                ),
                onPressed: () {
                  _cubit.toggleSearch();
                  if (state.isSearching) _searchController.clear();
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded,
                    color: Colors.black87, size: 22),
                onPressed: () {},
              ),
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
        hintText: 'Tìm kiếm từ vựng...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        border: InputBorder.none,
      ),
    );
  }

  // ─── Filter bar ───────────────────────────────────────────

  Widget _buildFilterBar() {
    return BlocBuilder<ListWordCubit, ListWordState>(
      buildWhen: (prev, curr) =>
      prev.activeTab != curr.activeTab ||
          prev.totalCount != curr.totalCount,
          //  || prev.learnedCount != curr.learnedCount,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: [
              Text(
                '${state.totalCount} words',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterChip(
                label: 'All',
                tab: FilterTab.all,
                activeTab: state.activeTab,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Learned',
                tab: FilterTab.learned,
                activeTab: state.activeTab,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'New',
                tab: FilterTab.newWord,
                activeTab: state.activeTab,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required FilterTab tab,
    required FilterTab activeTab,
  }) {
    final isActive = tab == activeTab;
    return GestureDetector(
      onTap: () => _cubit.onTabChanged(tab),
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
              color: Color(0xFF6B7FD4),
              strokeWidth: 2.5,
            ),
          );
        }

        if (state.filteredWords.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: state.filteredWords.length,
          itemBuilder: (context, index) {
            final word = state.filteredWords[index];
            return _buildWordCard(word, index);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Chưa có từ vựng nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn + để thêm từ mới',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(VocabularyEntry word, int index) {
    final isLearned = word.isLearned == true;

    return Dismissible(
      key: ValueKey(word.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (_) => _confirmDelete(word),
      onDismissed: (_) => _cubit.deleteWord(word.id),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildWordContent(word)),
              const SizedBox(width: 8),
              _buildCardActions(word, isLearned),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordContent(VocabularyEntry word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Word + badge
        Row(
          children: [
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            if (word.wordType != null && word.wordType!.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildBadge(word.wordType!),
            ],
          ],
        ),
        // Pronunciation
        if (word.pronunciation != null &&
            word.pronunciation!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            word.pronunciation!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 6),
        // Meaning
        Text(
          word.meaning,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        // Example (nếu có)
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
    // Màu badge theo loại từ
    final isAdjective = label.toLowerCase().contains('adj') ||
        label.toLowerCase().contains('形');
    final color =
    isAdjective ? const Color(0xFFE8E3FF) : const Color(0xFFE8E8E8);
    final textColor =
    isAdjective ? const Color(0xFF6B7FD4) : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCardActions(VocabularyEntry word, bool isLearned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TTS button
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
        // Bookmark / learned toggle
        GestureDetector(
          onTap: () => _cubit.toggleLearned(word.id),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isLearned ? Icons.star_rounded : Icons.star_border_rounded,
              key: ValueKey(isLearned),
              color: isLearned
                  ? const Color(0xFF6B7FD4)
                  : Colors.grey.shade400,
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
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddWordPage()),
        );
        // Reload sau khi thêm từ mới
        _cubit.loadWords();
      },
      backgroundColor: const Color(0xFF6B7FD4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    );
  }

  // ─── Confirm delete dialog ────────────────────────────────

  Future<bool> _confirmDelete(VocabularyEntry word) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
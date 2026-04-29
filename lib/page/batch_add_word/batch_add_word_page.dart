import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../scan_vocab/scan_vocab_cubit.dart';
import 'batch_add_word_cubit.dart';

class BatchAddWordPage extends StatelessWidget {
  final List<ScannedVocabItem> items;

  const BatchAddWordPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BatchAddWordCubit(
        context.read<VocabularyRepository>(),
        context.read<TagRepository>(),
        items,
      )..loadTags(),
      child: const _BatchAddWordView(),
    );
  }
}

class _BatchAddWordView extends StatelessWidget {
  const _BatchAddWordView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<BatchAddWordCubit, BatchAddWordState>(
      listener: (context, state) {
        if (state.status == LOADSTATUS.SUCCESS) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã lưu ${state.savedCount} từ thành công!'),
              backgroundColor: const Color(0xFF50C040),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
        } else if (state.status == LOADSTATUS.FAILED && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<BatchAddWordCubit, BatchAddWordState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F4F8),
            appBar: _buildAppBar(state),
            body: state.items.isEmpty
                ? const Center(child: Text('Chưa có từ nào', style: TextStyle(color: Colors.black45)))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: state.items.length,
              itemBuilder: (ctx, i) => _buildCard(context, state, i),
            ),
            bottomNavigationBar: _buildSaveButton(context, state),
          );
        },
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BatchAddWordState state) {
    return AppBar(
      backgroundColor: const Color(0xFFF2F4F8),
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          const Text('Danh sách từ quét được', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          Text('${state.items.length} từ', style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }

  // ── Item Card ─────────────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context, BatchAddWordState state, int index) {
    final item = state.items[index];
    final selectedTagIds = state.tagsForItem(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: item.hasError ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7B6FD4).withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: Color(0xFF7B6FD4), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                if (item.hasError)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDelete(context, index, item),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF6B7FD4), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditDialog(context, index, item),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('Từ vựng', item.word, const Color(0xFF7B6FD4), item.word.isEmpty),
                const SizedBox(height: 8),
                _buildField('Phát âm', item.pronunciation, const Color(0xFF5B8DEF), false),
                const SizedBox(height: 8),
                _buildField('Nghĩa', item.meaning, const Color(0xFFF4A261), item.meaning.isEmpty),
                if (state.tags != null && state.tags!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text('Tags', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: state.tags!.map((tag) {
                      final isSelected = selectedTagIds.contains(tag.id);
                      return GestureDetector(
                        onTap: () => context.read<BatchAddWordCubit>().toggleTag(index, tag.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6B7FD4) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFF6B7FD4) : Colors.grey.shade300),
                          ),
                          child: Text(
                            tag.tagName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, Color color, bool hasError) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 16,
          margin: const EdgeInsets.only(top: 2, right: 8),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600))),
        Expanded(
          child: Text(
            value.isEmpty ? '(trống)' : value,
            style: TextStyle(
              fontSize: 14,
              color: value.isEmpty ? (hasError ? Colors.redAccent : Colors.grey.shade400) : Colors.black87,
              fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, int index, ScannedVocabItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá từ?'),
        content: Text('Xoá "${item.word.isEmpty ? 'từ này' : item.word}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BatchAddWordCubit>().removeItem(index);
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Edit Dialog ───────────────────────────────────────────────────────────
  void _showEditDialog(BuildContext context, int index, ScannedVocabItem item) {
    final wordCtrl = TextEditingController(text: item.word);
    final pronCtrl = TextEditingController(text: item.pronunciation);
    final meaningCtrl = TextEditingController(text: item.meaning);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Chỉnh sửa từ ${index + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField('Từ vựng *', wordCtrl, const Color(0xFF7B6FD4)),
              const SizedBox(height: 12),
              _dialogField('Phát âm', pronCtrl, const Color(0xFF5B8DEF)),
              const SizedBox(height: 12),
              _dialogField('Nghĩa *', meaningCtrl, const Color(0xFFF4A261), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () {
              context.read<BatchAddWordCubit>().updateItem(
                index,
                ScannedVocabItem(word: wordCtrl.text, pronunciation: pronCtrl.text, meaning: meaningCtrl.text),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B6FD4), foregroundColor: Colors.white),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, Color color, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton(BuildContext context, BatchAddWordState state) {
    final isLoading = state.status == LOADSTATUS.LOADING;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      color: Colors.white,
      child: GestureDetector(
        onTap: isLoading ? null : context.read<BatchAddWordCubit>().saveAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF7B6FD4), Color(0xFF5B8DEF)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6B7FD4).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(
            'Lưu tất cả ${state.items.length} từ',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
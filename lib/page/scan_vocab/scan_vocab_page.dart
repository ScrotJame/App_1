import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../commons/enums.dart';
import '../../models/model_local/support_language_local.dart';
import '../batch_add_word/batch_add_word_page.dart';
import 'scan_vocab_cubit.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────
class ScanVocabPage extends StatelessWidget {
  const ScanVocabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScanVocabCubit(),
      child: const _ScanVocabView(),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────────────────────
class _ScanVocabView extends StatefulWidget {
  const _ScanVocabView();

  @override
  State<_ScanVocabView> createState() => _ScanVocabViewState();
}

class _ScanVocabViewState extends State<_ScanVocabView> {
  File? _imageFile;

  final _imageKey = GlobalKey();

  static const _roleColors = {
    TokenRole.word: Color(0xFF7B6FD4),
    TokenRole.pronunciation: Color(0xFF5B8DEF),
    TokenRole.meaning: Color(0xFFF4A261),
    TokenRole.none: Colors.transparent,
    TokenRole.language: Color(0xFF92F461),
  };

  static const _roleLabels = {
    TokenRole.word: 'Từ vựng',
    TokenRole.pronunciation: 'Phát âm',
    TokenRole.meaning: 'Nghĩa',
    TokenRole.language: 'Ngôn ngữ',
  };

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
    if (mounted) context.read<ScanVocabCubit>().runOcr(File(picked.path));
  }

  Future<void> _addCurrentItem() async {
    final success = await context.read<ScanVocabCubit>().addCurrentItem();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất Từ vựng hoặc Nghĩa'), backgroundColor: Colors.orange),
      );
    } else {
      final count = context.read<ScanVocabCubit>().state.vocabItems.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm – danh sách có $count từ'),
          backgroundColor: const Color(0xFF50C040),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _goToBatch(ScanVocabState state) {
    if (state.vocabItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có từ nào'), backgroundColor: Colors.orange),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BatchAddWordPage(
        items: List.from(state.vocabItems),
        detectedLanguage: state.detectedLanguage,
      ),
    ));
  }

  // ─── Bottom sheet chọn ngôn ngữ ──────────────────────────────────────────
  void _showLanguagePicker(ScanVocabState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'Chọn ngôn ngữ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (state.isLanguageManuallySet)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.read<ScanVocabCubit>().emit(
                            context.read<ScanVocabCubit>().state.copyWith(
                              isLanguageManuallySet: false,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tự động',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: kSupportedLanguages.length,
                    itemBuilder: (_, i) {
                      final lang = kSupportedLanguages[i];
                      final isSelected = state.detectedLanguage == lang.code;
                      return ListTile(
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          lang.label,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF9B8FE4) : Colors.white,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: Color(0xFF9B8FE4), size: 20)
                            : null,
                        onTap: () {
                          context.read<ScanVocabCubit>().setLanguageManually(lang.code);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ─── Tính vùng ảnh thực sự được render (BoxFit.contain) ──────────────────
  Rect _getDisplayRect(Size widgetSize, Size imageSize) {
    final widgetRatio = widgetSize.width / widgetSize.height;
    final imageRatio = imageSize.width / imageSize.height;

    double dispW, dispH;
    if (imageRatio > widgetRatio) {
      dispW = widgetSize.width;
      dispH = widgetSize.width / imageRatio;
    } else {
      dispH = widgetSize.height;
      dispW = widgetSize.height * imageRatio;
    }

    final left = (widgetSize.width - dispW) / 2;
    final top = (widgetSize.height - dispH) / 2;
    return Rect.fromLTWH(left, top, dispW, dispH);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanVocabCubit, ScanVocabState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _buildAppBar(state),
          body: _imageFile == null
              ? _buildEmptyState()
              : _buildLensView(state),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ScanVocabState state) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text('Quét từ vựng', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      actions: [
        if (state.vocabItems.isNotEmpty)
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.checklist_rounded, color: Colors.white, size: 24),
                onPressed: () => _goToBatch(state),
              ),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFFF4A261), shape: BoxShape.circle),
                  child: Text('${state.vocabItems.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_rounded, size: 50, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          const Text('Chụp ảnh hoặc chọn từ thư viện\nđể quét từ vựng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white60, height: 1.6)),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPickButton(icon: Icons.camera_alt_rounded, label: 'Chụp ảnh', onTap: () => _pickImage(ImageSource.camera)),
              const SizedBox(width: 16),
              _buildPickButton(icon: Icons.photo_library_rounded, label: 'Thư viện', onTap: () => _pickImage(ImageSource.gallery)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Lens View ─────────────────────────────────────────────────────────────
  Widget _buildLensView(ScanVocabState state) {
    return Column(
      children: [
        _buildRoleSelector(state),
        Expanded(child: _buildImageWithOverlay(state)),
        _buildBottomPanel(state),
      ],
    );
  }

  // ── Role Selector ─────────────────────────────────────────────────────────
  Widget _buildRoleSelector(ScanVocabState state) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: TokenRole.values
            .where((r) => r != TokenRole.none)
            .map((role) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildRoleChip(role, state.activeRole),
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildRoleChip(TokenRole role, TokenRole activeRole) {
    final isActive = activeRole == role;
    final color = _roleColors[role]!;
    return GestureDetector(
      onTap: () => context.read<ScanVocabCubit>().setActiveRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : color.withValues(alpha: 0.4), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          _roleLabels[role]!,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? Colors.white : color),
        ),
      ),
    );
  }

  // ── Image + Overlay ───────────────────────────────────────────────────────
  Widget _buildImageWithOverlay(ScanVocabState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);

        Rect? displayRect;
        if (state.imageSize != null) {
          displayRect = _getDisplayRect(widgetSize, state.imageSize!);
        }

        return GestureDetector(
          onPanStart: (d) {
            context.read<ScanVocabCubit>().updateDragRect(
              Rect.fromLTWH(d.localPosition.dx, d.localPosition.dy, 0, 0),
            );
          },
          onPanUpdate: (d) {
            final cur = context.read<ScanVocabCubit>().state.dragRect;
            if (cur == null) return;
            context.read<ScanVocabCubit>().updateDragRect(
              Rect.fromPoints(cur.topLeft, d.localPosition),
            );
          },
          onPanEnd: (_) {
            final cur = context.read<ScanVocabCubit>().state.dragRect;
            if (cur != null && displayRect != null) {
              context.read<ScanVocabCubit>().commitDragSelection(cur, widgetSize, displayRect);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                _imageFile!,
                key: _imageKey,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
              if (state.status == SCANSTATUS.scanning)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text('Đang nhận diện...', style: TextStyle(color: Colors.white70)),
                    ]),
                  ),
                ),
              if (state.status == SCANSTATUS.scanned && displayRect != null)
                CustomPaint(
                  painter: _BlockOverlayPainter(
                    blocks: state.blocks,
                    displayRect: displayRect,
                    imageSize: state.imageSize!,
                    roleColors: _roleColors,
                    activeRole: state.activeRole,
                  ),
                ),
              if (state.dragRect != null)
                CustomPaint(
                  painter: _DragRectPainter(
                    rect: state.dragRect!,
                    color: _roleColors[state.activeRole]!,
                  ),
                ),
              Positioned(
                bottom: 12, left: 12,
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.photo_library_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Đổi ảnh', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
              Positioned(
                bottom: 12, right: 12,
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Chụp lại', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Bottom Panel ──────────────────────────────────────────────────────────
  Widget _buildBottomPanel(ScanVocabState state) {
    final preview = state.currentPreview;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Language badge (tappable) ──────────────────────────────────
          if (state.status == SCANSTATUS.scanned)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showLanguagePicker(state),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: state.isLanguageManuallySet
                            ? const Color(0xFF7B6FD4).withValues(alpha: 0.28)
                            : const Color(0xFF7B6FD4).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: state.isLanguageManuallySet
                              ? const Color(0xFF7B6FD4).withValues(alpha: 0.9)
                              : const Color(0xFF7B6FD4).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate_rounded, size: 13, color: Color(0xFF9B8FE4)),
                          const SizedBox(width: 5),
                          Text(
                            state.detectedLanguage != null
                                ? state.languageBadgeLabel
                                : 'Chọn ngôn ngữ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: state.detectedLanguage != null
                                  ? const Color(0xFF9B8FE4)
                                  : Colors.white38,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Chỉ báo manual
                          if (state.isLanguageManuallySet)
                            const Icon(Icons.edit_rounded, size: 11, color: Color(0xFF9B8FE4))
                          else
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF9B8FE4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Preview chips ─────────────────────────────────────────────
          Row(
            children: [
              _buildPreviewChip('Từ', preview.word, const Color(0xFF7B6FD4), role: TokenRole.word),
              const SizedBox(width: 8),
              _buildPreviewChip('Âm', preview.pronunciation, const Color(0xFF5B8DEF), role: TokenRole.pronunciation),
              const SizedBox(width: 8),
              Expanded(child: _buildPreviewChip('Nghĩa', preview.meaning, const Color(0xFFF4A261), expand: true, role: TokenRole.meaning)),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              if (state.hasAnySelection)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => context.read<ScanVocabCubit>().clearAllSelections(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.clear_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addCurrentItem,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Thêm vào danh sách'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B6FD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          if (state.vocabItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _goToBatch(state),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text('Tiếp tục với ${state.vocabItems.length} từ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF50C040),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewChip(String label, String value, Color color, {bool expand = false, required TokenRole role}) {
    final hasValue = value.isNotEmpty;
    return GestureDetector(
      onTap: hasValue
          ? () => context.read<ScanVocabCubit>().clearRole(role)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: hasValue ? 0.7 : 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                if (hasValue) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.close_rounded, size: 11, color: color),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(fontSize: 13, color: value.isEmpty ? Colors.white30 : Colors.white, fontWeight: FontWeight.w500),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CustomPainter: vẽ bounding box của các OCR block ────────────────────────
class _BlockOverlayPainter extends CustomPainter {
  final List<OcrBlock> blocks;
  final Rect displayRect;
  final Size imageSize;
  final Map<TokenRole, Color> roleColors;
  final TokenRole activeRole;

  _BlockOverlayPainter({
    required this.blocks,
    required this.displayRect,
    required this.imageSize,
    required this.roleColors,
    required this.activeRole,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = displayRect.width / imageSize.width;
    final scaleY = displayRect.height / imageSize.height;

    for (final block in blocks) {
      final r = Rect.fromLTWH(
        displayRect.left + block.boundingBox.left * scaleX,
        displayRect.top + block.boundingBox.top * scaleY,
        block.boundingBox.width * scaleX,
        block.boundingBox.height * scaleY,
      );

      if (block.isSelected) {
        final color = roleColors[block.role]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()..color = color.withValues(alpha: 0.35),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final roleLabel = {
          TokenRole.word: 'Từ',
          TokenRole.pronunciation: 'Âm',
          TokenRole.meaning: 'Nghĩa',
        }[block.role] ?? '';
        final tp = TextPainter(
          text: TextSpan(
            text: ' $roleLabel ',
            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, background: Paint()..color = color),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(r.left, r.top - 16));
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BlockOverlayPainter old) =>
      old.blocks != blocks || old.displayRect != displayRect;
}

// ─── CustomPainter: vẽ drag selection rect ───────────────────────────────────
class _DragRectPainter extends CustomPainter {
  final Rect rect;
  final Color color;

  const _DragRectPainter({required this.rect, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.2));
    final dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawDashedRect(canvas, rect, dashPaint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dash = 6.0, gap = 4.0;
    void drawDashedLine(Offset a, Offset b) {
      final d = (b - a);
      final len = d.distance;
      final dir = d / len;
      double pos = 0;
      while (pos < len) {
        final end = (pos + dash).clamp(0.0, len);
        canvas.drawLine(a + dir * pos, a + dir * end, paint);
        pos += dash + gap;
      }
    }
    drawDashedLine(rect.topLeft, rect.topRight);
    drawDashedLine(rect.topRight, rect.bottomRight);
    drawDashedLine(rect.bottomRight, rect.bottomLeft);
    drawDashedLine(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(_DragRectPainter old) => old.rect != rect || old.color != color;
}
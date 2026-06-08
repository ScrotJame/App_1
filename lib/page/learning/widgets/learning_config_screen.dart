import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_abc/helper/language_helper.dart';

import '../../../commons/app_colors.dart';
import '../../../commons/enums.dart';
import '../../widgets/app_gradient_header.dart';
import '../learning_cubit.dart';
import '../../../repository/vocabulary_repository.dart';
import '../../../repository/unit_repository.dart';

// ── Palette (giống InventoryPage) ────────────────────────────────
const _kBg     = Color(0xFFF2F3F7);
const _kCard   = Colors.white;
const _kAccent = Color(0xFF42C8F5);
const _kDark   = Color(0xFF1A1A2E);
const _kGrey   = Color(0xFF9E9E9E);

/// Màn hình cấu hình bài học — hiển thị khi phase == LearningPhase.config
class LearningConfigScreen extends StatelessWidget {
  const LearningConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: BlocBuilder<LearningCubit, LearningState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  // ─── Header (style InventoryPage) ──────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return AppGradientHeader(
      height: 160,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              _buildTopBar(context),
              const SizedBox(height: 6),
              _buildSubtitle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kDark, size: 20),
          ),
          Expanded(
            child: Text(
              'Học từ vựng',
              textAlign: TextAlign.center,
              style: GoogleFonts.balooBhai2(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
          ),
          // Placeholder giữ cân đối layout
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Chọn phương thức học phù hợp với bạn',
        textAlign: TextAlign.center,
        style: GoogleFonts.balooBhai2(
          fontSize: 13,
          color: _kDark.withOpacity(0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, LearningState state) {
    final cubit = context.read<LearningCubit>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Banner card (style GradientCard của config_screen) ──
                _buildBannerCard(context, state),
                const SizedBox(height: 24),

                // ── Section: chọn kiểu học ──────────────────────────────
                _sectionTitle('Kiểu học', Icons.school_rounded),
                const SizedBox(height: 12),
                _buildLearningTypeGrid(context, state, cubit),
                const SizedBox(height: 32),

                // ── Error banner ────────────────────────────────────────
                if (state.loadStatus == LOADSTATUS.FAILED &&
                    state.errorMessage != null) ...[
                  _buildErrorBanner(state.errorMessage ?? ''),
                  const SizedBox(height: 12),
                ],

              ],
            ),
          ),
        ),

        // ── Start button ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStartButton(context, state, cubit),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Banner Card ───────────────────────────────────────────────

  Widget _buildBannerCard(BuildContext context, LearningState state) {
    final limit = state.config.limitWords;
    final lang = state.config.language;
    final unitId = state.config.unitId;

    final String summaryText;

    return GestureDetector(
      onTap: () => _showConfigBottomSheet(context, state),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF42C8F5), Color(0xFF1E9FD8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF42C8F5).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded,
                color: Colors.white, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Tuỳ chỉnh bài học',
                style: GoogleFonts.balooBhai2(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  void _showConfigBottomSheet(BuildContext context, LearningState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _LearningConfigBottomSheetContent(
          initialConfig: state.config,
          onApply: (limit, lang, unitId) {
            final cubit = context.read<LearningCubit>();
            cubit.setLimitWords(limit);
            cubit.setLanguage(lang);
            cubit.setUnitId(unitId);
          },
        );
      },
    );
  }

  // ─── Learning Type Grid (style InventoryItemCard) ───────────────

  Widget _buildLearningTypeGrid(
    BuildContext context,
    LearningState state,
    LearningCubit cubit,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: _learningTypeItems.length,
      itemBuilder: (_, i) {
        final item = _learningTypeItems[i];
        final isSelected = state.config.learningType == item.type;
        return _LearningTypeCard(
          item: item,
          isSelected: isSelected,
          onTap: () => cubit.setLearningType(item.type),
        );
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kAccent),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.kRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.kRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    LearningState state,
    LearningCubit cubit,
  ) {
    final isLoading = state.loadStatus == LOADSTATUS.LOADING;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : cubit.startLearning,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_forward_rounded, size: 20),
        label: Text(
          'Bắt đầu học',
          style: GoogleFonts.balooBhai2(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kAccent.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: _kAccent.withOpacity(0.35),
        ),
      ),
    );
  }
}

// ─── Learning Type Item Data ──────────────────────────────────────

class _LearningTypeItem {
  final LearningType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _LearningTypeItem({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}

const _learningTypeItems = [
  _LearningTypeItem(
    type: LearningType.flashCard,
    icon: Icons.flip_camera_android_rounded,
    title: 'Flashcard',
    subtitle: 'Học bằng thẻ lật',
    accentColor: Color(0xFF42C8F5),
  ),
  _LearningTypeItem(
    type: LearningType.wordMatching,
    icon: Icons.extension_rounded,
    title: 'Word Matching',
    subtitle: 'Nối từ và nghĩa',
    accentColor: Color(0xFF4CAF50),
  ),
  _LearningTypeItem(
    type: LearningType.quizGame,
    icon: Icons.quiz_rounded,
    title: 'Quiz Game',
    subtitle: 'Trắc nghiệm từ vựng',
    accentColor: Color(0xFF7C3AED),
  ),
  _LearningTypeItem(
    type: LearningType.comingSoon,
    icon: Icons.more_horiz_rounded,
    title: 'Coming Soon',
    subtitle: 'Sắp ra mắt',
    accentColor: Color(0xFF9E9E9E),
  ),
];

// ─── Learning Type Card (style InventoryItemCard) ────────────────

class _LearningTypeCard extends StatelessWidget {
  final _LearningTypeItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _LearningTypeCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPressed = ValueNotifier<bool>(false);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) => isPressed.value = false,
      onTapCancel: () => isPressed.value = false,
      onTap: onTap,
      child: ValueListenableBuilder<bool>(
        valueListenable: isPressed,
        builder: (_, pressed, child) {
          return AnimatedScale(
            scale: pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? item.accentColor.withOpacity(0.12)
                : _kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? item.accentColor : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? item.accentColor.withOpacity(0.2)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon circle (style _ItemImage inventory)
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.accentColor.withOpacity(0.15),
                    border: Border.all(
                      color: item.accentColor.withOpacity(isSelected ? 0.7 : 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.accentColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.balooBhai2(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? item.accentColor : _kDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.balooBhai2(
                    fontSize: 11,
                    color: isSelected
                        ? item.accentColor.withOpacity(0.8)
                        : _kGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // if (isSelected) ...[
                //   const SizedBox(height: 6),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Customize Bottom Sheet Content ──────────────────────────────────

class _LearningConfigBottomSheetContent extends StatefulWidget {
  final LearningConfig initialConfig;
  final Function(int? limit, String? lang, int? unitId) onApply;

  const _LearningConfigBottomSheetContent({
    required this.initialConfig,
    required this.onApply,
  });

  @override
  State<_LearningConfigBottomSheetContent> createState() =>
      _LearningConfigBottomSheetContentState();
}

class _LearningConfigBottomSheetContentState
    extends State<_LearningConfigBottomSheetContent> {
  int? _selectedLimit;
  String? _selectedLanguage;
  int? _selectedUnitId;

  bool _isLoading = true;
  List<String> _languages = [];
  List<dynamic> _units = [];
  final TextEditingController _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLimit = widget.initialConfig.limitWords ?? 10;
    _selectedLanguage = widget.initialConfig.language;
    _selectedUnitId = widget.initialConfig.unitId;
    _limitController.text = _selectedLimit!.toString();
    _loadData();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final vocabRepo = context.read<VocabularyRepository>();
      final unitRepo = context.read<UnitRepository>();

      final langs = await vocabRepo.getLanguageTags();
      final units = await unitRepo.watchAllUnitsWithWords().first;

      if (mounted) {
        setState(() {
          _languages = langs;
          _units = units;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: _kAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Tùy chỉnh bài học',
                  style: GoogleFonts.balooBhai2(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: _kAccent),
                ),
              )
            else ...[
              // Section 1: Limit words
              _buildSectionTitle('Giới hạn số từ'),
              const SizedBox(height: 8),
              _buildLimitRow(),
              const SizedBox(height: 20),

              // Section 2: Languages
              _buildSectionTitle('Ngôn ngữ'),
              const SizedBox(height: 8),
              _buildLanguageRow(),
              const SizedBox(height: 20),

              // Section 3: Units
              _buildSectionTitle('Theo Unit'),
              const SizedBox(height: 8),
              _buildUnitRow(),
              const SizedBox(height: 28),

              // Confirm button
              _buildApplyButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.balooBhai2(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: _kDark.withOpacity(0.8),
      ),
    );
  }

  Widget _buildLimitRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số lượng từ (tối đa 50):',
                style: GoogleFonts.balooBhai2(
                  fontSize: 13,
                  color: _kDark.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final currentVal = int.tryParse(_limitController.text) ?? 10;
                      if (currentVal > 1) {
                        final newVal = currentVal - 1;
                        setState(() {
                          _selectedLimit = newVal;
                          _limitController.text = newVal.toString();
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: _kAccent),
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.balooBhai2(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kDark,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: _kAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: _kAccent, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          final clamped = parsed.clamp(1, 50);
                          setState(() {
                            _selectedLimit = clamped;
                          });
                          if (clamped != parsed) {
                            _limitController.text = clamped.toString();
                            _limitController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _limitController.text.length),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final currentVal = int.tryParse(_limitController.text) ?? 10;
                      if (currentVal < 50) {
                        final newVal = currentVal + 1;
                        setState(() {
                          _selectedLimit = newVal;
                          _limitController.text = newVal.toString();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, color: _kAccent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kAccent,
              inactiveTrackColor: _kAccent.withOpacity(0.2),
              thumbColor: _kAccent,
              overlayColor: _kAccent.withOpacity(0.12),
              valueIndicatorColor: _kAccent,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: (_selectedLimit ?? 10).toDouble().clamp(1.0, 50.0),
              min: 1,
              max: 50,
              divisions: 49,
              label: _selectedLimit?.toString(),
              onChanged: (value) {
                final val = value.round();
                setState(() {
                  _selectedLimit = val;
                  _limitController.text = val.toString();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLanguageRow() {
    final options = ['Tất cả', ..._languages];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((lang) {
          final isAll = lang == 'Tất cả';
          final value = isAll ? null : lang;
          final isSelected = isAll ? _selectedLanguage == null : _selectedLanguage == lang;
          final displayLabel = isAll
              ? 'Tất cả'
              : LanguageHelper.getDetectedLanguageLabelTag(lang);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(displayLabel),
              selected: isSelected,
              selectedColor: _kAccent.withOpacity(0.2),
              backgroundColor: _kCard,
              labelStyle: GoogleFonts.balooBhai2(
                color: isSelected ? _kAccent : _kDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? _kAccent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnitRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Tất cả'),
              selected: _selectedUnitId == null,
              selectedColor: _kAccent.withOpacity(0.2),
              backgroundColor: _kCard,
              labelStyle: GoogleFonts.balooBhai2(
                color: _selectedUnitId == null ? _kAccent : _kDark,
                fontWeight: _selectedUnitId == null ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedUnitId == null ? _kAccent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedUnitId = null;
                });
              },
            ),
          ),
          ..._units.map((unitWithWords) {
            final unit = unitWithWords.unit;
            final isSelected = _selectedUnitId == unit.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(unit.title),
                selected: isSelected,
                selectedColor: _kAccent.withOpacity(0.2),
                backgroundColor: _kCard,
                labelStyle: GoogleFonts.balooBhai2(
                  color: isSelected ? _kAccent : _kDark,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? _kAccent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedUnitId = unit.id;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final limit = (_selectedLimit ?? 10).clamp(1, 50);
          widget.onApply(limit, _selectedLanguage, _selectedUnitId);
          Navigator.pop(context);
        },
        icon: const Icon(Icons.check_rounded, size: 20),
        label: Text(
          'Áp dụng',
          style: GoogleFonts.balooBhai2(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: _kAccent.withOpacity(0.35),
        ),
      ),
    );
  }
}

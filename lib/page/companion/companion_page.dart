import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/ultis/extension/label_extension.dart';
import '../../generated/l10n.dart';
import '../../repository/companion_repository.dart';
import 'companion_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants & Theme
// ─────────────────────────────────────────────────────────────────────────────

const _kThemeColors = [Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF2E7D32)];
const _kGreenAccent = Color(0xFF388E3C);
const _kSurface = Colors.white;

// ─────────────────────────────────────────────────────────────────────────────
// Entry point - Tái cấu trúc thành StatefulWidget
// ─────────────────────────────────────────────────────────────────────────────

class CompanionPage extends StatefulWidget {
  final String userKey;
  const CompanionPage({super.key, required this.userKey});

  @override
  State<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends State<CompanionPage> with TickerProviderStateMixin {
  late CompanionCubit _cubit;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();

    // 1. Khởi tạo Cubit
    _cubit = CompanionCubit(
      repository: context.read<CompanionRepository>(),
      userKey: widget.userKey,
    );

    // 2. Khởi tạo AnimationController giống PetPage
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  // 3. Xử lý logic Listener
  void _onStateChanged(BuildContext context, CompanionState state) {
    if (state.justReachedLevel != null) {
      _showLevelUpDialog(context, state.justReachedLevel!);
      _cubit.clearFeedback();
    }
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cubit.clearFeedback();
    }
    if (state.status == CompanionStatus.confirmingDelete) {
      _showDeleteDialog(context, state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<CompanionCubit, CompanionState>(
        listenWhen: (p, c) =>
        c.justReachedLevel != null ||
            c.errorMessage != null ||
            c.status == CompanionStatus.confirmingDelete,
        listener: _onStateChanged,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _kThemeColors,
                stops: [0, 0.5, 1],
              ),
            ),
            child: SafeArea(
              child: BlocBuilder<CompanionCubit, CompanionState>(
                builder: (context, state) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _routeBody(context, state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _routeBody(BuildContext context, CompanionState state) {
    switch (state.status) {
      case CompanionStatus.initial:
      case CompanionStatus.loading:
        return const _LoadingScreen();
      case CompanionStatus.awaitingChoice:
        return _TypeChoiceScreen(cubit: _cubit);
      case CompanionStatus.browsing:
        return _BrowsingScreen(cubit: _cubit, state: state);
      case CompanionStatus.active:
      case CompanionStatus.confirmingDelete:
        return _ActiveView(cubit: _cubit, state: state, bounceAnim: _bounceAnim);
      case CompanionStatus.error:
        return _ErrorScreen(cubit: _cubit, message: state.errorMessage);
    }
  }

  // --- Dialogs ---
  void _showLevelUpDialog(BuildContext ctx, int level) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('Lên cấp!', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Companion đạt cấp $level!\nBonus XP học tập tăng lên.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.6)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tuyệt vời!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext ctx, CompanionState state) {
    final current = state.activeCompanion;
    if (state.pendingDefinitionId == null) return;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Xoá vĩnh viễn?', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (current != null) ...[
                      Text('${current.definition?.iconKey ?? '❓'}  ${current.displayName}  —  Cấp ${current.level}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('${current.totalWordsLearned} từ đã học cùng companion này sẽ bị mất.', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    const Text('Hành động này không thể hoàn tác.', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54, side: const BorderSide(color: Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () { Navigator.of(ctx).pop(); _cubit.cancelSwitch(); },
                    child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () { Navigator.of(ctx).pop(); _cubit.confirmSwitch(); },
                    child: const Text('Xoá & Đổi', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-screens (Widgets stateless sử dụng chung trong flow)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: Colors.white));
}

class _ErrorScreen extends StatelessWidget {
  final CompanionCubit cubit;
  final String? message;
  const _ErrorScreen({required this.cubit, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(message ?? 'Lỗi không xác định', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _kGreenAccent),
              onPressed: () => cubit.clearFeedback(),
              child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChoiceScreen extends StatelessWidget {
  final CompanionCubit cubit;
  const _TypeChoiceScreen({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 52),
          const Text('Chọn người bạn\nđồng hành', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.2, shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
          const SizedBox(height: 10),
          const Text('Mỗi từ bạn học sẽ nuôi dưỡng companion.\nMột khi đã chọn, không thể quay lại.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
          const SizedBox(height: 48),
          Row(children: [
            Expanded(child: _TypeCard(emoji: '🐾', title: 'Thú cưng', bullets: const ['Năng động, lên cấp nhanh', 'Bonus XP cao hơn', 'Nhiều loài để chọn'], colors: const [Color(0xFF4A90D9), Color(0xFF1A4A7A)], onTap: () => cubit.browseType('pet'))),
            const SizedBox(width: 14),
            Expanded(child: _TypeCard(emoji: '🌿', title: 'Cây trồng', bullets: const ['Bền vững, lâu dài', 'Bonus XP ổn định', 'Trực quan & dễ thấy'], colors: const [Color(0xFF81C784), Color(0xFF388E3C)], onTap: () => cubit.browseType('plant'))),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Row(children: const [Icon(Icons.info_outline, color: Colors.white70, size: 16), SizedBox(width: 10), Expanded(child: Text('Đổi companion sẽ XÓA HOÀN TOÀN tiến trình hiện tại. Hãy chọn kỹ!', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)))]),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String emoji, title; final List<String> bullets; final List<Color> colors; final VoidCallback onTap;
  const _TypeCard({required this.emoji, required this.title, required this.bullets, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: colors.last.withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)), const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
            ...bullets.map((b) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(color: Colors.white60, fontSize: 12)), Expanded(child: Text(b, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)))]))),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: const Text('Chọn →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

class _BrowsingScreen extends StatelessWidget {
  final CompanionCubit cubit;
  final CompanionState state;
  const _BrowsingScreen({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final label = state.browsingType == 'pet' ? 'Thú cưng' : 'Cây trồng';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            _circleBtn(onTap: state.hasActiveCompanion ? null : () => cubit.backToTypeChoice(), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Text('Chọn $label', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, shadows: [Shadow(color: Colors.black26, blurRadius: 4)]))),
            if (state.hasActiveCompanion) GestureDetector(onTap: () => cubit.cancelSwitch(), child: const Icon(Icons.close_rounded, color: Colors.white70, size: 26)),
          ]),
        ),
        if (state.hasActiveCompanion)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
            child: Text('⚠️ Chọn companion mới sẽ xóa hoàn toàn "${state.activeCompanion?.displayName}".', style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: state.availableDefinitions.isEmpty
              ? const Center(child: Text('Không có companion nào', style: TextStyle(color: Colors.white70)))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), physics: const BouncingScrollPhysics(), itemCount: state.availableDefinitions.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final def = state.availableDefinitions[i];
              final isPending = state.pendingDefinitionId == def.id;
              return _DefCard(
                def: def, isPending: isPending, hasExisting: state.hasActiveCompanion,
                onTap: () => cubit.setPending(def.id),
                onConfirm: state.hasActiveCompanion ? () => cubit.requestSwitch(def.id) : () => cubit.confirmAdopt(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DefCard extends StatelessWidget {
  final CompanionDefEntity def; final bool isPending; final bool hasExisting; final VoidCallback onTap; final VoidCallback onConfirm;
  const _DefCard({required this.def, required this.isPending, required this.hasExisting, required this.onTap, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isPending ? _kGreenAccent : Colors.transparent, width: isPending ? 2 : 0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)), child: Center(child: Text(def.iconKey, style: const TextStyle(fontSize: 30)))), const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(def.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 4),
                  Text(def.description, style: const TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 8),
                  Row(children: [ _Chip(label: '+${(def.maxXpBonus * 100).round()}% XP', color: const Color(0xFFF9A825)), const SizedBox(width: 6), _Chip(label: '${def.maxLevel} cấp', color: Colors.grey) ]),
                ])),
                AnimatedContainer(duration: const Duration(milliseconds: 200), width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: isPending ? _kGreenAccent : Colors.transparent, border: Border.all(color: isPending ? _kGreenAccent : Colors.grey.shade300, width: 2)), child: isPending ? const Icon(Icons.check, size: 13, color: Colors.white) : null),
              ]),
            ),
          ),
          if (isPending)
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(color: hasExisting ? Colors.redAccent : _kGreenAccent, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))),
                child: Text(hasExisting ? '🗑 Xoá con cũ & Chọn ngay' : '✅ Xác nhận chọn', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color; const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The Active View (Tương đương view chính của PetPage)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveView extends StatelessWidget {
  final CompanionCubit cubit;
  final CompanionState state;
  final Animation<double> bounceAnim;

  const _ActiveView({required this.cubit, required this.state, required this.bounceAnim});

  @override
  Widget build(BuildContext context) {
    final c = state.activeCompanion;
    if (c == null) return const _LoadingScreen();
    final def = c.definition;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _circleBtn(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
              Expanded(child: Text(def?.type == 'plant' ? '🌿 Vườn Sinh Thái' : '🐾 Nhà Thú Cưng', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]))),
              _circleBtn(
                onTap: () => cubit.browseType(def?.type ?? 'pet'),
                child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),

        // Body (Scrollable giống PetPage)
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _CompanionStatsBar(companion: c),
                const SizedBox(height: 16),
                _CompanionScene(companion: c, bounceAnim: bounceAnim),
                const SizedBox(height: 24),
                _LearningCard(companion: c),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _circleBtn({required Widget child, VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedOpacity(
      opacity: onTap != null ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 200),
      child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)), alignment: Alignment.center, child: child),
    ),
  );
}

// ─── Stats Bar ───
class _CompanionStatsBar extends StatelessWidget {
  final ActiveCompanionEntity companion;
  const _CompanionStatsBar({required this.companion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.3))),
      child: Column(
        children: [
          Row(
            children: [
              _LevelBadge(level: companion.level),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(companion.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(companion.isMaxLevel ? 'Trưởng thành 🏆' : 'Đang lớn 🌱', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _ExpBar(progress: companion.levelProgress, current: companion.wordsInCurrentLevel, total: companion.wordsNeededForNextLevel, isMax: companion.isMaxLevel),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InfoChip(icon: '📚', label: S.of(context).word_learn.capitalize(), value: '${companion.totalWordsLearned} từ', color: const Color(0xFF4FC3F7))),
              const SizedBox(width: 8),
              Expanded(child: _InfoChip(icon: '⚡', label: 'XP Bonus', value: '+${(companion.currentXpBonus * 100).toStringAsFixed(1)}%', color: const Color(0xFFFFD54F))),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level; const _LevelBadge({required this.level});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Lv.$level', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF5D4037)))]),
    );
  }
}

class _ExpBar extends StatelessWidget {
  final double progress; final int current, total; final bool isMax;
  const _ExpBar({required this.progress, required this.current, required this.total, required this.isMax});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: isMax ? 1.0 : progress.clamp(0.0, 1.0), minHeight: 6, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700))),
        ),
        const SizedBox(height: 2),
        Text(isMax ? 'Đã đạt cấp tối đa' : '$current / $total Từ', style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon, label, value; final Color color;
  const _InfoChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 14)), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── Scene ───
class _CompanionScene extends StatelessWidget {
  final ActiveCompanionEntity companion;
  final Animation<double> bounceAnim;
  const _CompanionScene({required this.companion, required this.bounceAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220, margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF87CEEB), Color(0xFF98FB98)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            _buildBackground(),
            Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 60, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF66BB6A).withOpacity(0), const Color(0xFF388E3C)])))),
            Positioned(bottom: 0, left: 0, right: 0, child: _GrassRow()),
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, 0),
                child: AnimatedBuilder(
                  animation: bounceAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, bounceAnim.value),
                    child: Text(companion.definition?.iconKey ?? '❓', style: const TextStyle(fontSize: 80)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      height: 160, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB3E5FC), Color(0xFFE8F5E9)])),
      child: const Padding(
        padding: EdgeInsets.only(top: 14, left: 20, right: 20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_Cloud(width: 60, height: 20), _Cloud(width: 80, height: 24), _Cloud(width: 50, height: 16)]),
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  final double width, height; const _Cloud({required this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(height)));
  }
}

class _GrassRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 40, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(20, (i) => Container(width: 3, height: 8.0 + (i % 3) * 4, decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(2))))));
  }
}

// ─── Info Card ───
class _LearningCard extends StatelessWidget {
  final ActiveCompanionEntity companion;
  const _LearningCard({required this.companion});

  @override
  Widget build(BuildContext context) {
    final def = companion.definition;
    final maxBonusPct = ((def?.maxXpBonus ?? 0) * 100).toStringAsFixed(0);
    final isPlant = def?.type == 'plant';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📈 Năng lực học tập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green[800])),
              Icon(Icons.lightbulb_outline, color: Colors.orange[300], size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _StatRow(icon: isPlant ? '💧' : '🍖', label: 'Nguồn cung cấp', value: 'Từ vựng đã học', color: Colors.blue),
          const SizedBox(height: 12),
          _StatRow(icon: '⚡', label: 'Bonus XP hiện tại', value: '+${(companion.currentXpBonus * 100).toStringAsFixed(1)}%', color: Colors.orange),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiến trình Bonus Tối đa', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('Tối đa +$maxBonusPct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (def?.maxXpBonus ?? 0) > 0 ? companion.currentXpBonus / (def!.maxXpBonus) : 0,
                  backgroundColor: Colors.orange.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation(Colors.orange), minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Colors.green, size: 16), const SizedBox(width: 8),
              Expanded(child: Text('Học từ mới để cung cấp thức ăn/nước uống giúp Companion mau lớn nhé!', style: TextStyle(color: Colors.green[800], fontSize: 11, height: 1.4))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String icon, label, value; final MaterialColor color;
  const _StatRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)), child: Text(icon, style: const TextStyle(fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600))),
        Text(value, style: TextStyle(color: color.shade700, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
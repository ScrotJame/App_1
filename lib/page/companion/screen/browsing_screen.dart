import 'package:flutter/material.dart';
import '../../../models/entity/companion_definition_entity.dart';
import '../../../repository/companion_repository.dart';
import '../companion_cubit.dart';
import '../companion_page.dart';

class CompanionBrowsingScreen extends StatelessWidget {
  final CompanionCubit cubit;
  final CompanionState state;

  const CompanionBrowsingScreen({super.key, required this.cubit, required this.state});

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
              return CompanionDefCard(
                def: def, isPending: isPending, hasExisting: state.hasActiveCompanion,
                onTap: () => cubit.setPending(def.id ?? 0),
                onConfirm: state.hasActiveCompanion ? () => cubit.requestSwitch(def.id ?? 0) : () => cubit.confirmAdopt(),
              );
            },
          ),
        ),
      ],
    );
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
}

class CompanionDefCard extends StatelessWidget {
  final CompanionDefinitionEntity def;
  final bool isPending;
  final bool hasExisting;
  final VoidCallback onTap;
  final VoidCallback onConfirm;

  const CompanionDefCard({
    super.key,
    required this.def,
    required this.isPending,
    required this.hasExisting,
    required this.onTap,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isPending ? kGreenAccent : Colors.transparent, width: isPending ? 2 : 0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(def.iconKey  ?? '',
                        style: const TextStyle(fontSize: 30))
                    )
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(def.name ?? '',
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)
                          ),
                          const SizedBox(height: 4),
                          Text(def.description ?? '',
                              style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12)
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            CompanionChip(label: '+${(def.maxXpBonus! * 100).round()}% XP',
                                color: const Color(0xFFF9A825)),
                            const SizedBox(width: 6),
                            CompanionChip(label: '${def.maxLevel} cấp',
                                color: Colors.grey)
                          ]
                          ),
                ])),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPending ? kGreenAccent : Colors.transparent,
                        border: Border.all(
                            color: isPending
                                ? kGreenAccent
                                : Colors.grey.shade300, width: 2)
                    ),
                    child: isPending
                        ? const Icon(Icons.check, size: 13, color: Colors.white) : null),
              ]),
            ),
          ),
          if (isPending)
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(color: hasExisting ? Colors.redAccent : kGreenAccent, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))),
                child: Text(hasExisting ? '🗑 Xoá con cũ & Chọn ngay' : '✅ Xác nhận chọn', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

class CompanionChip extends StatelessWidget {
  final String label;
  final Color color;

  const CompanionChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
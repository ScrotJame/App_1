import 'package:flutter/material.dart';
import '../companion_cubit.dart';

class CompanionTypeChoiceScreen extends StatelessWidget {
  final CompanionCubit cubit;

  const CompanionTypeChoiceScreen({super.key, required this.cubit});

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
            Expanded(child: CompanionTypeCard(emoji: '🐾', title: 'Thú cưng', bullets: const ['Năng động, lên cấp nhanh', 'Bonus XP cao hơn', 'Nhiều loài để chọn'], colors: const [Color(0xFF4A90D9), Color(0xFF1A4A7A)], onTap: () => cubit.browseType('pet'))),
            const SizedBox(width: 14),
            Expanded(child: CompanionTypeCard(emoji: '🌿', title: 'Cây trồng', bullets: const ['Bền vững, lâu dài', 'Bonus XP ổn định', 'Trực quan & dễ thấy'], colors: const [Color(0xFF81C784), Color(0xFF388E3C)], onTap: () => cubit.browseType('plant'))),
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

class CompanionTypeCard extends StatelessWidget {
  final String emoji, title;
  final List<String> bullets;
  final List<Color> colors;
  final VoidCallback onTap;

  const CompanionTypeCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.bullets,
    required this.colors,
    required this.onTap,
  });

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
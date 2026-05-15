import 'package:flutter/material.dart';
import '../../../models/entity/active_companion_entity.dart';
import '../../../repository/companion_repository.dart';

// ── Scene Card ────────────────────────────────────────────────────────────────

class CompanionSceneCard extends StatelessWidget {
  final ActiveCompanionEntity companion;
  final Animation<double> bounceAnim;

  const CompanionSceneCard({
    super.key,
    required this.companion,
    required this.bounceAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3D8B3D), Color(0xFF1A5C1A)],
                ),
              ),
            ),
            ..._buildBubbles(),
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.1),
                child: AnimatedBuilder(
                  animation: bounceAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, bounceAnim.value),
                    child: Text(
                      companion.definition?.iconKey ?? '❓',
                      style: const TextStyle(fontSize: 90),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(companion.displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBubbles() {
    final bubbles = [
      _BubbleData(left: -10, top: 30, size: 90, opacity: 0.25),
      _BubbleData(right: -15, top: 10, size: 110, opacity: 0.20),
      _BubbleData(left: 30, bottom: 20, size: 70, opacity: 0.18),
      _BubbleData(right: 40, bottom: 30, size: 55, opacity: 0.22),
      _BubbleData(left: 90, top: 15, size: 50, opacity: 0.15),
      _BubbleData(right: 80, bottom: 60, size: 80, opacity: 0.17),
      _BubbleData(left: 160, top: 50, size: 40, opacity: 0.20),
    ];
    return bubbles.map((b) => b.toWidget()).toList();
  }
}

class _BubbleData {
  final double? left, right, top, bottom, size, opacity;
  const _BubbleData(
      {this.left,
        this.right,
        this.top,
        this.bottom,
        required this.size,
        required this.opacity});

  Widget toWidget() {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withOpacity(opacity! * 2), width: 2),
          gradient: RadialGradient(
              colors: [Colors.white.withOpacity(opacity!), Colors.transparent],
              stops: const [0.0, 1.0]),
        ),
      ),
    );
  }
}

// ── Stat Chips Row ────────────────────────────────────────────────────────────

class CompanionStatChipsRow extends StatelessWidget {
  final ActiveCompanionEntity companion;

  const CompanionStatChipsRow({super.key, required this.companion});

  @override
  Widget build(BuildContext context) {
    final isPlant = companion.definition?.type == 'plant';
    final xpBonusPct =
    ((companion.currentXpBonus ?? 0) * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: CompanionStatCard(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFE65100),
                  value: '+$xpBonusPct%',
                  label: 'XP Bonus')),
          const SizedBox(width: 10),
          Expanded(
              child: CompanionStatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  value: 'Level ${companion.level}',
                  label: 'Growth')),
          const SizedBox(width: 10),
          Expanded(
              child: CompanionStatCard(
                  icon: isPlant
                      ? Icons.water_drop_rounded
                      : Icons.restaurant_rounded,
                  iconColor: const Color(0xFF1E88E5),
                  value: companion.foodInventoryLabel,
                  label: isPlant ? 'Water' : 'Food')),
        ],
      ),
    );
  }
}

class CompanionStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value, label;

  const CompanionStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}

// ── Food Inventory Bar ────────────────────────────────────────────────────────

class CompanionFoodInventoryBar extends StatelessWidget {
  final ActiveCompanionEntity companion;

  const CompanionFoodInventoryBar({super.key, required this.companion});

  @override
  Widget build(BuildContext context) {
    final def = companion.definition;
    final isPlant = def?.type == 'plant';
    final inventory = companion.foodInventory ?? 0;
    final maxInventory = def?.maxFoodInventory ?? 10;
    final wordsPerFood = def?.wordsPerFood ?? 10;
    final pending = companion.pendingWords ?? 0;
    final wordsUntilNext = companion.wordsUntilNextFood;
    final isFull = companion.isFoodFull;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          Row(
            children: [
              Text(
                isPlant ? '💧 Kho nước' : '🍖 Kho thức ăn',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.black87),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isFull ? '🔥 Đầy kho!' : '$inventory / $maxInventory',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isFull ? Colors.orange[800] : Colors.green[700],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Inventory slots ──────────────────────────────────
          _FoodSlots(
              inventory: inventory,
              maxInventory: maxInventory,
              isPlant: isPlant),

          const SizedBox(height: 14),

          // ── Word progress to next food ───────────────────────
          if (!isFull) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiến trình nhận ${isPlant ? 'nước' : 'thức ăn'} tiếp theo',
                  style:
                  const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  '$pending / $wordsPerFood từ',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: wordsPerFood > 0 ? pending / wordsPerFood : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(
                    isPlant ? Colors.blue : Colors.orange),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.school_outlined,
                    size: 14,
                    color: isPlant ? Colors.blue[400] : Colors.orange[400]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Học thêm $wordsUntilNext từ để nhận 1 ${isPlant ? 'nước' : 'thức ăn'}',
                    style:
                    const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: Colors.orange[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isFull
                        ? 'Kho đầy! Hãy ${isPlant ? 'tưới cây' : 'cho ăn'} để nhận thêm.'
                        : '',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Hiển thị ô tròn cho từng food slot
class _FoodSlots extends StatelessWidget {
  final int inventory;
  final int maxInventory;
  final bool isPlant;

  const _FoodSlots({
    required this.inventory,
    required this.maxInventory,
    required this.isPlant,
  });

  @override
  Widget build(BuildContext context) {
    final filledColor =
    isPlant ? const Color(0xFF1E88E5) : const Color(0xFFE65100);
    final emptyColor = Colors.grey.shade100;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(maxInventory, (i) {
        final filled = i < inventory;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? filledColor.withOpacity(0.15) : emptyColor,
            border: Border.all(
              color: filled ? filledColor : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: filled
              ? Center(
            child: Text(
              isPlant ? '💧' : '🍖',
              style: const TextStyle(fontSize: 12),
            ),
          )
              : null,
        );
      }),
    );
  }
}

// ── Evolution Bar ─────────────────────────────────────────────────────────────

class CompanionEvolutionBar extends StatelessWidget {
  final ActiveCompanionEntity companion;

  const CompanionEvolutionBar({super.key, required this.companion});

  @override
  Widget build(BuildContext context) {
    final progress = companion.levelProgress.clamp(0.0, 1.0);
    final current = companion.foodUsedInCurrentLevel ?? 0;
    final total = companion.foodNeededForNextLevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Next Evolution: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87)),
              if (!companion.isMaxLevel!) ...[
                Text('$current',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFF1565C0))),
                Text(' / $total feeds',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1565C0))),
              ] else
                const Text('Max Level! 🏆',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFFE65100))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (companion.isMaxLevel ?? false) ? 1.0 : progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation(
                  (companion.isMaxLevel ?? false)
                      ? const Color(0xFFE65100)
                      : const Color(0xFF1565C0)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.local_dining_rounded,
                    color: Color(0xFF1E88E5), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (companion.isMaxLevel ?? false)
                      ? 'Your companion has reached its final form!'
                      : 'Feed your companion ${(total - current).clamp(0, total)} more times to evolve!',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Row ──────────────────────────────────────────────────────────────────

class CompanionStatRow extends StatelessWidget {
  final String icon, label, value;
  final MaterialColor color;

  const CompanionStatRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: Text(icon, style: const TextStyle(fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
        Text(value,
            style: TextStyle(
                color: color.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
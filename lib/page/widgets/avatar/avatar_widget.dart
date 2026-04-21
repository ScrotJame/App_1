import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'xp_cubit.dart';

class XpBarWidget extends StatelessWidget {
  final String avatarUrl;
  final double avatarRadius;
  final double barHeight;

  const XpBarWidget({
    super.key,
    required this.avatarUrl,
    this.avatarRadius = 28,
    this.barHeight = 22,
  });

  // ─── PUBLIC BUILD ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<XpCubit, XpState>(
      builder: (context, state) => _buildRoot(state),
    );
  }

  // ─── ROOT ────────────────────────────────────────────────
  Widget _buildRoot(XpState state) {
    final double avatarDiameter = avatarRadius * 2;

    return SizedBox(
      width: 180,
      height: avatarDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          _buildBar(state, avatarDiameter),
          _buildAvatar(avatarDiameter),
        ],
      ),
    );
  }

  Widget _buildBar(XpState state, double avatarDiameter) {
    return Positioned(
      left: avatarRadius,
      right: 0,
      top: (avatarDiameter - barHeight) / 2,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(barHeight / 2),
          border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(barHeight / 2),
          child: Stack(
            children: [
              _buildBarFill(state),
              _buildXpLabel(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarFill(XpState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(barHeight / 2),
      child: FractionallySizedBox(
        widthFactor: state.progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
        ),
      ),
    );
  }

  Widget _buildXpLabel(XpState state) {
    return Center(
      child: Text(
        '${state.currentXp} / ${state.maxXp} XP',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
          shadows: [Shadow(color: Colors.black26, blurRadius: 3)],
        ),
      ),
    );
  }

  // ─── AVATAR ──────────────────────────────────────────────
  Widget _buildAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF43A047), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(child: _buildAvatarImage()),
    );
  }

  Widget _buildAvatarImage() {
    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFF81C784),
        child: Icon(Icons.person, color: Colors.white, size: 28),
      ),
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const ColoredBox(
          color: Color(0xFFE8F5E9),
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF43A047),
              ),
            ),
          ),
        );
      },
    );
  }
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';
import '../../../commons/app_images.dart';
import 'xp_cubit.dart';

class XpBarWidget extends StatelessWidget {
  final String? avatarUrl;
  final double avatarRadius;
  final double barHeight;
  final VoidCallback? onTap;
  final VoidCallback? onTapChange;

  const XpBarWidget({
    super.key,
    this.avatarUrl,
    this.avatarRadius = 28,
    this.barHeight = 22,
    this.onTap,
    this.onTapChange,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<XpCubit, XpState>(
      builder: (context, state) => _buildRoot(context, state),
    );
  }

  Widget _buildRoot(BuildContext context, XpState state) {
    final double avatarDiameter = avatarRadius * 2;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        height: avatarDiameter,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            _buildBar(context, state, avatarDiameter),
            _buildAvatar(avatarDiameter),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context, XpState state, double avatarDiameter) {
    return Positioned(
      left: avatarRadius,
      right: 0,
      top: (avatarDiameter - barHeight) / 2,
      child: GestureDetector(
        onTap: () => context.read<XpCubit>().changeLabel(
          state.tab == Xp.xpTab ? Xp.levelTab : Xp.xpTab,
        ),
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
                _buildActiveLabel(state),
              ],
            ),
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

  Widget _buildActiveLabel(XpState state) {
    final text = state.tab == Xp.levelTab
        ? '${(S.current.level).toUpperCase()}: ${state.level}'
        : '${state.currentXp} / ${state.requiredXp} XP';

    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0x88070707),
          letterSpacing: 0.3,
          shadows: [Shadow(color: Colors.black26, blurRadius: 3)],
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF43A047), width: 3),
        color: Colors.white,
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
    if (avatarUrl == null) {
      return Image.asset(AppImages.icAvatar, fit: BoxFit.cover);
    }

    if (avatarUrl!.startsWith('/')) {
      return Image.file(
        File(avatarUrl!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset(AppImages.icAvatar, fit: BoxFit.cover),
      );
    }

    return Image.asset(avatarUrl!, fit: BoxFit.cover);
  }
}
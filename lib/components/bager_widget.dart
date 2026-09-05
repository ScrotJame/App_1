import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BagerWidget extends StatelessWidget {
  final String? avatarUrl;
  final String? label;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onBarTap;

  //size
  final double? avatarRadius;
  final double? barHeight;
  final double? barWidth;
  final double? barBorderWidth;
  final double? avatarBorderWidth;

  //Color
  final Color? barBackground;
  final Color? barBorder;
  final Color? barShadow;
  final Color? labelColor;
  final Color? avatarBorder;
  final Color? avatarBackground;
  final Color? avatarShadow;
  final Gradient? barGradient;

  const BagerWidget({
    super.key,
    this.avatarUrl,
    this.label,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.onBarTap,

    this.avatarRadius = 18,
    this.barHeight = 22,
    this.barWidth = 100,
    this.barBorderWidth = 1.5,
    this.avatarBorderWidth = 3,

    this.barBackground,
    this.barBorder,
    this.barShadow,
    this.barGradient,
    this.labelColor,
    this.avatarBorder,
    this.avatarBackground,
    this.avatarShadow,
  });


  @override
  Widget build(BuildContext context) {
    final double avatarDiameter = avatarRadius! * 2;
    final double totalWidth = avatarRadius! + barWidth!;

    Widget buildAvatar() {
      return Container(
        width: avatarDiameter,
        height: avatarDiameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: barBorder ?? Colors.transparent,
            width: avatarBorderWidth ?? 12,
          ),
          color: avatarBackground,
          boxShadow: [
            BoxShadow(
              color: avatarShadow ?? Colors.transparent,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: UnconstrainedBox(child: _BagerAvatarImage(avatarUrl: avatarUrl, width: avatarDiameter,height: avatarDiameter)),
      );
    }

    Widget buildProgressBar() {

      return Positioned(
        left: 0,
        right: 0,
        child: GestureDetector(
          onTap: onBarTap,
          child: Container(
            height: avatarDiameter,
            decoration: BoxDecoration(
              color: barBackground ?? Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: barBorder ?? Colors.transparent,
                width: barBorderWidth ?? 12,
              ),
              boxShadow: [
                BoxShadow(
                  color: barShadow ?? Colors.transparent,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Stack(
                children: [
                  // Fill layer
                  FractionallySizedBox(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: barGradient,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  // Label layer
                  if (label != null)
                    Center(
                      child: Text(
                        label!,
                        overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.balooBhai2().copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800
                          )),
                      ),

                ],
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(avatarDiameter / 2),
      child: SizedBox(
        width: totalWidth,
        height: avatarDiameter,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            buildProgressBar(),
            buildAvatar(),
          ],
        ),
      ),
    );
  }
}

class _BagerAvatarImage extends StatelessWidget {
  final String? avatarUrl;
  final double? width;
  final double? height;

  const _BagerAvatarImage({this.avatarUrl, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return const Icon(Icons.person, color: Colors.grey);
    }
    const placeholder = Icon(Icons.broken_image, color: Colors.grey);

    return Image.asset(
      avatarUrl!,
      fit: BoxFit.cover,
      width: width != null ? width! /2 : 12,
      height: height != null ? height! /2 : 12,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

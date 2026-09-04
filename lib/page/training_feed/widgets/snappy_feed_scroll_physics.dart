import 'package:flutter/material.dart';

/// SnappyFeedScrollPhysics provides a responsive, TikTok/Reels-style scrolling experience
/// for full-screen feed cards.
///
/// Unlike Flutter's default [PageScrollPhysics] which requires dragging more than 50%
/// of the entire screen height before it snaps forward, [SnappyFeedScrollPhysics] enables:
/// 1. Low distance threshold ([snapThreshold], default 12%): A gentle thumb drag of ~80-100px
///    is enough to smoothly advance to the next card.
/// 2. Responsive flick gesture: Any flick with velocity > 150 px/s triggers an immediate card transition.
/// 3. Bidirectional support: Both swiping up (forward) and swiping down (backward) are responsive.
/// 4. Overscroll bounce: Combined with [BouncingScrollPhysics] at the feed edges.
/// 5. Tuned spring mechanics: Crisp, high-frame-rate settling animation (60/120fps).
class SnappyFeedScrollPhysics extends ScrollPhysics {
  const SnappyFeedScrollPhysics({
    super.parent,
    this.snapThreshold = 0.12,
  });

  /// Fraction of screen height (0.0 to 0.5) needed to advance when dragging gently.
  final double snapThreshold;

  @override
  SnappyFeedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyFeedScrollPhysics(
      parent: buildParent(ancestor),
      snapThreshold: snapThreshold,
    );
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 22.0,
  );

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // If out of bounds (overscrolling past edges), defer to parent (e.g. BouncingScrollPhysics)
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = toleranceFor(position);
    final double page = position.pixels / position.viewportDimension;
    final int currentPage = page.floor();
    final double fraction = page - currentPage;

    double targetPage;
    if (velocity < -150.0) {
      // Fast flick downwards -> snap down to previous page
      targetPage = currentPage.toDouble();
    } else if (velocity > 150.0) {
      // Fast flick upwards -> snap up to next page
      targetPage = (currentPage + 1).toDouble();
    } else {
      // Gentle thumb drag & release:
      if (fraction <= snapThreshold) {
        // Dragged up < snapThreshold: snap back down to currentPage
        targetPage = currentPage.toDouble();
      } else if (fraction <= 0.5) {
        // Dragged up > snapThreshold: advance forward to next page
        targetPage = (currentPage + 1).toDouble();
      } else if (fraction <= (1.0 - snapThreshold)) {
        // Dragged down > snapThreshold: advance backward to previous page
        targetPage = currentPage.toDouble();
      } else {
        // Dragged down < snapThreshold: snap back to current page
        targetPage = (currentPage + 1).toDouble();
      }
    }

    final double maxPage = position.maxScrollExtent / position.viewportDimension;
    targetPage = targetPage.clamp(0.0, maxPage);
    final double targetPixels = targetPage * position.viewportDimension;

    if (targetPixels != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        targetPixels,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }
}

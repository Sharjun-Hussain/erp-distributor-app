import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fades + slides (optionally scales) a child in once when it first mounts.
///
/// The animation state lives inside [Animate], so rebuilds (e.g. provider
/// refreshes) do not replay it — only a fresh mount (first build, or the
/// widget coming back into view in a scrollable) plays it again.
class EntranceFade extends StatelessWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.slideY = 0.08,
    this.scale = 1.0,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Vertical slide as a fraction of the child's height (0.08 ≈ soft rise).
  final double slideY;

  /// Optional scale-from value, e.g. 0.97 for a subtle pop. 1.0 = no scale.
  final double scale;

  final Curve curve;

  @override
  Widget build(BuildContext context) {
    var animate = child.animate(delay: delay).fadeIn(
          duration: duration,
          curve: curve,
        );

    if (slideY != 0) {
      animate = animate.slideY(
        begin: slideY,
        end: 0,
        duration: duration,
        curve: curve,
      );
    }

    if (scale != 1.0) {
      animate = animate.scale(
        begin: Offset(scale, scale),
        end: const Offset(1, 1),
        duration: duration,
        curve: curve,
      );
    }

    return animate;
  }
}

/// Staggers a list of children with a fixed [step] between each delay.
List<Widget> staggered(
  List<Widget> children, {
  Duration start = Duration.zero,
  Duration step = const Duration(milliseconds: 60),
  double slideY = 0.08,
  double scale = 1.0,
}) {
  return [
    for (var i = 0; i < children.length; i++)
      EntranceFade(
        delay: start + step * i,
        slideY: slideY,
        scale: scale,
        child: children[i],
      ),
  ];
}

/// Gently floats [child] up and down forever (starts after [delay]).
///
/// Wrap it outside an [EntranceFade] if you want a one-time entrance first,
/// then an endless loop.
class FloatingLoop extends StatelessWidget {
  const FloatingLoop({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.distance = 8,
    this.duration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final Duration delay;

  /// Float travel in logical pixels.
  final double distance;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay, onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: 0,
          end: distance,
          duration: duration,
          curve: Curves.easeInOut,
        );
  }
}

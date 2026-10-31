import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:changa_app/features/dashboard/domain/entities/harmony_score.dart';

/// A ring that sweeps up to [value] (0 to 100). A null value draws an empty
/// outline with a dash, which is how the dashboard looks before any data.
///
/// Colours follow the Harmony tier by default. On a dark card, pass [color],
/// [trackColor] and [labelColor] so the ring reads against it.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 72,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
    this.labelColor,
    this.center,
    this.semanticLabel,
  });

  final int? value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Color? labelColor;

  /// Replaces the number in the middle, e.g. an icon.
  final Widget? center;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = value?.clamp(0, 100);

    final arcColor = color ?? _tierColor(scheme, current);
    final track = trackColor ?? scheme.outlineVariant;
    final textColor = labelColor ?? scheme.onSurface;

    // Respect the system "remove animations" setting.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label:
          semanticLabel ??
          (current == null ? 'No score yet' : '$current percent'),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (current ?? 0) / 100),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) {
            return CustomPaint(
              painter: _RingPainter(
                progress: progress,
                arcColor: arcColor,
                trackColor: track,
                // Thin outline when there is nothing to show yet.
                strokeWidth: current == null ? 2 : strokeWidth,
              ),
              child: child,
            );
          },
          child: Center(
            child:
                center ??
                Text(
                  current == null ? '—' : '$current',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Color _tierColor(ColorScheme scheme, int? current) {
    if (current == null) return scheme.outline;
    return switch (HarmonyTier.fromValue(current)) {
      HarmonyTier.needsAttention => scheme.error,
      HarmonyTier.steady => scheme.tertiary,
      HarmonyTier.thriving => scheme.primary,
    };
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.arcColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color arcColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = arcColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'farm_provider.dart';
import 'sampling.dart';
import 'soil_point_modal.dart';

Path _dashPath(Path source, {double dashLength = 6, double gapLength = 4}) {
  final dashed = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    var draw = true;
    while (distance < metric.length) {
      final length = draw ? dashLength : gapLength;
      if (draw) {
        dashed.addPath(metric.extractPath(distance, distance + length), Offset.zero);
      }
      distance += length;
      draw = !draw;
    }
  }
  return dashed;
}

class _DashedShapePainter extends CustomPainter {
  const _DashedShapePainter({required this.color, this.isCircle = false});

  final Color color;
  final bool isCircle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = isCircle
        ? (Path()..addOval(rect))
        : (Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))));

    canvas.drawPath(
      _dashPath(path),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedShapePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isCircle != isCircle;
}

Map<String, Offset> _positionsFor(List<String> labels) {
  if (labels.length == 1) {
    return {'center': const Offset(0.5, 0.5)};
  }
  if (labels.contains('corner_1') && !labels.contains('corner_3')) {
    return {
      'corner_1': const Offset(0.15, 0.15),
      'corner_2': const Offset(0.85, 0.85),
      'center': const Offset(0.5, 0.5),
    };
  }
  if (labels.contains('corner_1')) {
    return {
      'corner_1': const Offset(0.15, 0.15),
      'corner_2': const Offset(0.85, 0.15),
      'corner_3': const Offset(0.15, 0.85),
      'corner_4': const Offset(0.85, 0.85),
      'center': const Offset(0.5, 0.5),
    };
  }
  return {
    'quadrant_1': const Offset(0.3, 0.3),
    'quadrant_2': const Offset(0.7, 0.3),
    'quadrant_3': const Offset(0.3, 0.7),
    'quadrant_4': const Offset(0.7, 0.7),
    'center': const Offset(0.5, 0.5),
  };
}

class SoilReadingCard extends StatelessWidget {
  const SoilReadingCard({super.key, required this.farmId, required this.sizeAcres, required this.recommendation});

  final String farmId;
  final double sizeAcres;
  final Recommendation? recommendation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final required = requiredPointsForArea(sizeAcres);
    final positions = _positionsFor(required);
    final filledPoints = {for (final pt in recommendation?.points ?? const <SoilPoint>[]) pt.pointLabel: pt};
    final isComplete = required.every(filledPoints.containsKey) && (recommendation?.isComplete ?? false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.soilReadingTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  return CustomPaint(
                    painter: _DashedShapePainter(color: Theme.of(context).colorScheme.outline),
                    child: Stack(
                      children: [
                        for (final label in required)
                          Positioned(
                            left: positions[label]!.dx * width - 22,
                            top: positions[label]!.dy * height - 22,
                            child: _PointButton(
                              filled: filledPoints.containsKey(label),
                              onTap: () => showSoilPointModal(
                                context,
                                pointLabel: label,
                                existingPoint: filledPoints[label],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: isComplete
                  ? Text(
                      'N ${recommendation!.compositeN!.toStringAsFixed(1)} · '
                      'P ${recommendation!.compositeP!.toStringAsFixed(1)} · '
                      'K ${recommendation!.compositeK!.toStringAsFixed(1)} · '
                      'pH ${recommendation!.compositePh!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    )
                  : Text(
                      l10n.compositePendingMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointButton extends StatelessWidget {
  const _PointButton({required this.filled, required this.onTap});

  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: filled
            ? Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
                child: Icon(Icons.check, color: colorScheme.onPrimary),
              )
            : CustomPaint(
                painter: _DashedShapePainter(color: colorScheme.outline, isCircle: true),
                child: Icon(Icons.add, color: colorScheme.outline),
              ),
      ),
    );
  }
}

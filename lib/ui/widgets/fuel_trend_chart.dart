import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/health_status.dart';
import '../../theme/app_theme.dart';

class FuelTrendChart extends StatelessWidget {
  const FuelTrendChart({
    super.key,
    required this.analytics,
    required this.strings,
  });

  final FuelAnalytics analytics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final points = analytics.trendPoints;
    final trendInfo = _trendStyle(analytics.trend, strings);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded,
                  color: AppColors.racingOrange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.fuelTrendTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (analytics.trend != EfficiencyTrend.none)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendInfo.color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: trendInfo.color.withOpacity(0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendInfo.icon, size: 14, color: trendInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        trendInfo.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: trendInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (points.length < 2)
            Container(
              height: 130,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppColors.textMuted,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.needMoreFuelPoints,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              height: 156,
              width: double.infinity,
              child: CustomPaint(
                painter: _FuelChartPainter(
                  points: points.length > 8
                      ? points.sublist(points.length - 8)
                      : points,
                  avgKmPerL: analytics.avgKmPerLiter ?? 0,
                  accentColor: trendInfo.color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.formatShortDate(
                    (points.length > 8
                            ? points[points.length - 8]
                            : points.first)
                        .entry
                        .date,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                if (analytics.avgKmPerLiter != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 2,
                        color: AppColors.sky.withOpacity(0.75),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Avg ${strings.formatNumber(analytics.avgKmPerLiter!)} km/L',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sky,
                        ),
                      ),
                    ],
                  ),
                Text(
                  strings.formatShortDate(points.last.entry.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  ({String label, Color color, IconData icon}) _trendStyle(
    EfficiencyTrend trend,
    AppStrings s,
  ) {
    switch (trend) {
      case EfficiencyTrend.efficient:
        return (
          label: s.trendEfficient,
          color: AppColors.emerald,
          icon: Icons.trending_up_rounded,
        );
      case EfficiencyTrend.heavy:
        return (
          label: s.trendHeavy,
          color: AppColors.amber,
          icon: Icons.trending_down_rounded,
        );
      case EfficiencyTrend.steady:
        return (
          label: s.trendSteady,
          color: AppColors.sky,
          icon: Icons.trending_flat_rounded,
        );
      case EfficiencyTrend.none:
        return (
          label: '',
          color: AppColors.sky,
          icon: Icons.show_chart_rounded,
        );
    }
  }
}

class _FuelChartPainter extends CustomPainter {
  _FuelChartPainter({
    required this.points,
    required this.avgKmPerL,
    required this.accentColor,
  });

  final List<FuelComputedEntry> points;
  final double avgKmPerL;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((e) => e.kmPerLiter ?? 0.0).toList();
    if (values.length < 2) return;

    const topPad = 24.0;
    const bottomPad = 14.0;
    const sidePad = 18.0;
    final chartW = size.width - sidePad * 2;
    final chartH = size.height - topPad - bottomPad;

    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final spread = math.max(2.0, rawMax - rawMin);
    final minVal = math.max(0.0, rawMin - spread * 0.25);
    final maxVal = rawMax + spread * 0.25;

    double yFor(double v) {
      final norm = (v - minVal) / (maxVal - minVal);
      return topPad + chartH * (1.0 - norm);
    }

    // Subtle horizontal grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.55)
      ..strokeWidth = 1;
    for (int i = 0; i <= 2; i++) {
      final y = topPad + (chartH / 2) * i;
      canvas.drawLine(
        Offset(sidePad, y),
        Offset(size.width - sidePad, y),
        gridPaint,
      );
    }

    // Dashed average reference line
    if (avgKmPerL >= minVal && avgKmPerL <= maxVal) {
      final avgY = yFor(avgKmPerL);
      final avgPaint = Paint()
        ..color = AppColors.sky.withOpacity(0.55)
        ..strokeWidth = 1.2;
      const dashW = 5.0;
      const gapW = 4.0;
      double x = sidePad;
      while (x < size.width - sidePad) {
        final endX = math.min(x + dashW, size.width - sidePad);
        canvas.drawLine(Offset(x, avgY), Offset(endX, avgY), avgPaint);
        x += dashW + gapW;
      }
    }

    // Compute coordinates
    final coords = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = sidePad + (chartW * i / (values.length - 1));
      coords.add(Offset(x, yFor(values[i])));
    }

    // Build smooth line path
    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (int i = 1; i < coords.length; i++) {
      final prev = coords[i - 1];
      final curr = coords[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    // Area gradient fill
    final fillPath = Path.from(linePath)
      ..lineTo(coords.last.dx, topPad + chartH)
      ..lineTo(coords.first.dx, topPad + chartH)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withOpacity(0.32),
          accentColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, strokePaint);

    // Draw points + value labels
    for (int i = 0; i < coords.length; i++) {
      final pt = coords[i];
      final val = values[i];
      final pointColor = val >= avgKmPerL ? AppColors.emerald : AppColors.amber;

      canvas.drawCircle(
        pt,
        5.0,
        Paint()..color = AppColors.surface,
      );
      canvas.drawCircle(
        pt,
        3.5,
        Paint()..color = pointColor,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(1),
          style: TextStyle(
            color: i == coords.length - 1
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: 10,
            fontWeight:
                i == coords.length - 1 ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = (pt.dx - textPainter.width / 2)
          .clamp(0.0, size.width - textPainter.width);
      final labelY = math.max(0.0, pt.dy - 18);
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant _FuelChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.avgKmPerL != avgKmPerL ||
        oldDelegate.accentColor != accentColor;
  }
}

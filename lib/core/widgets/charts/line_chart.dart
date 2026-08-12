import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// One line on a [LineChart].
///
/// Points carry data coordinates, not pixels: `dx` is the value along the
/// bottom — a gestational week, here — and `dy` the measurement. The chart maps
/// them, so a series can be handed straight from a record without knowing how
/// big it will be drawn.
@immutable
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.points,
    required this.color,
    this.dashed = false,
    this.strokeWidth = 3,
  });

  /// Names the line in the legend. Empty keeps it out of the legend — for a
  /// reference band that the axis already explains.
  final String label;

  /// Ordered by `dx`. Fewer than two points draws nothing: one measurement is
  /// not a trend, and a lone dot on an empty grid reads as an error.
  final List<Offset> points;

  final Color color;

  /// Dashed lines read as "expected" against a solid measured one.
  final bool dashed;

  final double strokeWidth;
}

/// A small multi-series line chart: gridlines, the lines, the labels under them.
///
/// Deliberately not a charting library. There are no axes to configure, no
/// tooltips and no zoom — the growth cards show a shape and a direction, and
/// everything precise is in the visit list above them.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.series,
    this.xLabels = const <String>[],
    this.height = 180,
    this.bands = 4,
    this.emptyLabel,
  });

  final List<ChartSeries> series;

  /// Spread evenly under the plot. Four is the usual count — enough to read the
  /// span, few enough not to collide on a narrow phone.
  final List<String> xLabels;

  /// Height of the plot itself, labels and legend excluded.
  final double height;

  /// How many horizontal slices the gridlines cut the plot into.
  final int bands;

  /// Shown in place of the plot when nothing can be drawn yet.
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final List<ChartSeries> drawable = series
        .where((ChartSeries line) => line.points.length > 1)
        .toList();

    if (drawable.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            emptyLabel ?? '',
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final List<ChartSeries> legend = drawable
        .where((ChartSeries line) => line.label.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _LineChartPainter(series: drawable, bands: bands),
          ),
        ),
        if (xLabels.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final String label in xLabels)
                Text(label, style: AppTextStyles.labelCaps),
            ],
          ),
        ],
        if (legend.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.stackMd),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.componentGap,
            runSpacing: AppSpacing.stackSm,
            children: <Widget>[
              for (final ChartSeries line in legend) _LegendEntry(series: line),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.series});

  final ChartSeries series;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: series.color,
            shape: BoxShape.circle,
          ),
          child: const SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: AppSpacing.stackSm),
        Text(series.label, style: AppTextStyles.bodySm),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.series, required this.bands});

  final List<ChartSeries> series;
  final int bands;

  /// A hint of the information blue, not the full token: gridlines are there to
  /// be measured against, not read.
  static final Color _grid = AppColors.tertiary.withValues(alpha: 0.14);

  static const double _dash = 6;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final ChartSeries line in series) {
      for (final Offset point in line.points) {
        minX = point.dx < minX ? point.dx : minX;
        maxX = point.dx > maxX ? point.dx : maxX;
        minY = point.dy < minY ? point.dy : minY;
        maxY = point.dy > maxY ? point.dy : maxY;
      }
    }

    // A single distinct value on either axis would divide by zero; give it a
    // span of one so the line lands mid-plot instead.
    final double spanX = maxX - minX == 0 ? 1 : maxX - minX;
    final double rawSpanY = maxY - minY;
    // Breathing room top and bottom, so a rising curve does not touch the frame.
    final double padY = rawSpanY == 0 ? 1 : rawSpanY * 0.12;
    final double lowY = minY - padY;
    final double spanY = rawSpanY == 0 ? 2 : rawSpanY + padY * 2;

    Offset toPixel(Offset point) => Offset(
      (point.dx - minX) / spanX * size.width,
      size.height - (point.dy - lowY) / spanY * size.height,
    );

    final Paint grid = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    for (int i = 1; i < bands; i++) {
      final double y = size.height * i / bands;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // The frame: left and bottom only. A full box would fence the data in.
    final Paint axis = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(0, size.height), axis);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axis,
    );

    for (final ChartSeries line in series) {
      final Paint stroke = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final Path path = _smoothPath(
        line.points.map(toPixel).toList(),
      );
      canvas.drawPath(line.dashed ? _dashed(path) : path, stroke);
    }
  }

  /// Curves through the points by drawing each segment as a quadratic bent
  /// around the point it passes, which reads as growth rather than as a series
  /// of measurements joined by rulers.
  Path _smoothPath(List<Offset> points) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length - 1; i++) {
      final Offset mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }

    final Offset last = points.last;
    final Offset beforeLast = points[points.length - 2];
    path.quadraticBezierTo(beforeLast.dx, beforeLast.dy, last.dx, last.dy);
    return path;
  }

  /// Walks the curve and keeps every other stretch of it, so the dashes follow
  /// the bend instead of being laid out straight.
  Path _dashed(Path source) {
    final Path out = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double start = 0;
      while (start < metric.length) {
        final double end = (start + _dash).clamp(0, metric.length);
        out.addPath(metric.extractPath(start, end), Offset.zero);
        start = end + _gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    // Series are rebuilt into a fresh list on every build, so this is usually
    // true. Repainting a handful of strokes is cheaper than deep-comparing them.
    return oldDelegate.series != series || oldDelegate.bands != bands;
  }
}

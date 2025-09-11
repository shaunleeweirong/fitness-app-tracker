import 'package:flutter/material.dart';
import 'dart:math';

/// Custom line chart widget that replaces fl_chart for better layout control
class SimpleLineChart extends StatelessWidget {
  final List<ChartPoint> data;
  final String yAxisLabel;
  final List<String> xAxisLabels;
  final Color lineColor;
  final Color fillColor;
  final Color backgroundColor;

  const SimpleLineChart({
    super.key,
    required this.data,
    this.yAxisLabel = 'Volume (kg)',
    this.xAxisLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    this.lineColor = const Color(0xFFFFB74D),
    this.fillColor = const Color(0x4DFFB74D),
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: LineChartPainter(
          data: data,
          yAxisLabel: yAxisLabel,
          xAxisLabels: xAxisLabels,
          lineColor: lineColor,
          fillColor: fillColor,
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white54,
            fontSize: 10,
          ) ?? const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        child: Container(), // Takes full available size
      ),
    );
  }
}

/// Data point for the chart
class ChartPoint {
  final double x;
  final double y;

  const ChartPoint(this.x, this.y);
}

/// Custom painter for drawing the line chart
class LineChartPainter extends CustomPainter {
  final List<ChartPoint> data;
  final String yAxisLabel;
  final List<String> xAxisLabels;
  final Color lineColor;
  final Color fillColor;
  final TextStyle textStyle;

  LineChartPainter({
    required this.data,
    required this.yAxisLabel,
    required this.xAxisLabels,
    required this.lineColor,
    required this.fillColor,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Define chart area with padding
    const double leftPadding = 40;
    const double rightPadding = 16;
    const double topPadding = 16;
    const double bottomPadding = 32;

    final chartRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    // Find data bounds
    final minY = data.map((p) => p.y).reduce(min).toDouble();
    final maxY = data.map((p) => p.y).reduce(max).toDouble();
    final minX = data.map((p) => p.x).reduce(min).toDouble();
    final maxX = data.map((p) => p.x).reduce(max).toDouble();

    // Add some padding to Y axis
    final yRange = maxY - minY;
    final adjustedMinY = max(0.0, minY - yRange * 0.1);
    final adjustedMaxY = maxY + yRange * 0.1;

    // Draw chart elements
    _drawYAxisLabel(canvas, chartRect);
    _drawXAxisLabels(canvas, chartRect);
    _drawLineAndFill(canvas, chartRect, adjustedMinY, adjustedMaxY, minX, maxX);
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: 'No data yet', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawYAxisLabel(Canvas canvas, Rect chartRect) {
    final textPainter = TextPainter(
      text: TextSpan(text: yAxisLabel, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Rotate and position Y-axis label
    canvas.save();
    canvas.translate(16, chartRect.center.dy + textPainter.width / 2);
    canvas.rotate(-pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawXAxisLabels(Canvas canvas, Rect chartRect) {
    if (xAxisLabels.isEmpty) return;

    final labelWidth = chartRect.width / xAxisLabels.length;
    
    for (int i = 0; i < xAxisLabels.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: xAxisLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      final x = chartRect.left + (i + 0.5) * labelWidth - textPainter.width / 2;
      final y = chartRect.bottom + 8;
      
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  void _drawLineAndFill(Canvas canvas, Rect chartRect, double minY, double maxY, double minX, double maxX) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    // Create line path
    final linePath = Path();
    final fillPath = Path();
    final points = <Offset>[];

    // Convert data points to screen coordinates
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = chartRect.left + (point.x - minX) / (maxX - minX) * chartRect.width;
      final y = chartRect.bottom - (point.y - minY) / (maxY - minY) * chartRect.height;
      
      points.add(Offset(x, y));
      
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, chartRect.bottom);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    if (points.isNotEmpty) {
      fillPath.lineTo(points.last.dx, chartRect.bottom);
      fillPath.close();
    }

    // Draw fill area
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(linePath, linePaint);

    // Draw data points
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
      // Draw stroke around dot
      canvas.drawCircle(point, 3, Paint()
        ..color = const Color(0xFF2A2A2A)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return data != oldDelegate.data ||
           lineColor != oldDelegate.lineColor ||
           fillColor != oldDelegate.fillColor;
  }
}
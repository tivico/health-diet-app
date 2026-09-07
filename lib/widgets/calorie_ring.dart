/// 熱量圓環：自繪的進度環，取代原本用圓餅圖硬湊出來的環。
///
/// 自己畫的好處是可以有圓頭線帽、端點光點與「超標再繞一圈」的效果，
/// 也少一層圖表套件的開銷。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class CalorieRing extends StatelessWidget {
  final double consumed;
  final double target;

  /// 環的直徑與線寬。
  final double size;
  final double stroke;

  /// 軌道與進度色。放在漸層卡片上時通常給半透明白與純白。
  final Color trackColor;
  final Color progressColor;

  /// 超出目標的那一段用色（會疊在滿環之上再繞一圈）。
  final Color overColor;

  /// 環中央的內容（通常是數字）。
  final Widget? center;

  const CalorieRing({
    super.key,
    required this.consumed,
    required this.target,
    this.size = 176,
    this.stroke = 14,
    required this.trackColor,
    required this.progressColor,
    required this.overColor,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = target <= 0 ? 0.0 : consumed / target;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        // 進場時讓環轉出來，數字才不會憑空冒出
        tween: Tween(begin: 0, end: ratio.clamp(0.0, 2.0)),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => CustomPaint(
          painter: _RingPainter(
            ratio: animated,
            stroke: stroke,
            trackColor: trackColor,
            progressColor: progressColor,
            overColor: overColor,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double ratio;
  final double stroke;
  final Color trackColor;
  final Color progressColor;
  final Color overColor;

  _RingPainter({
    required this.ratio,
    required this.stroke,
    required this.trackColor,
    required this.progressColor,
    required this.overColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2; // 從 12 點鐘方向開始

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (ratio <= 0) return;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;

    // 第一圈：0–100%
    final firstSweep = math.min(ratio, 1.0) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, firstSweep, false, base);

    // 超標的部分再疊一圈，一眼看得出來超出多少
    if (ratio > 1.0) {
      final over = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = overColor;
      final overSweep = math.min(ratio - 1.0, 1.0) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, overSweep, false, over);
    }

    // 進度端點加一個亮點，讓環看起來「還在動」
    final endAngle = startAngle + (ratio > 1.0 ? (ratio - 1.0) : ratio) * 2 * math.pi;
    final dot = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    canvas.drawCircle(
      dot,
      stroke * 0.28,
      Paint()..color = ratio > 1.0 ? Colors.white : progressColor,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio ||
      old.stroke != stroke ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.overColor != overColor;
}

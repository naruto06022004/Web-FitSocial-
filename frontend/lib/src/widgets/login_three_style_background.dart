import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Nền động phong cách scene 3D: mesh, lưới phối cảnh, hạt — chuyển động liên tục, mượt.
class LoginThreeStyleBackground extends StatefulWidget {
  const LoginThreeStyleBackground({super.key, required this.child});

  final Widget child;

  @override
  State<LoginThreeStyleBackground> createState() => _LoginThreeStyleBackgroundState();
}

class _LoginThreeStyleBackgroundState extends State<LoginThreeStyleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Một vòng ~14s — đủ chậm để không gắt, vẫn thấy rõ chuyển động.
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              painter: _ThreeStyleScenePainter(t: _ctrl.value),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _ThreeStyleScenePainter extends CustomPainter {
  _ThreeStyleScenePainter({required this.t});

  /// 0..1 mỗi vòng AnimationController
  final double t;

  static const _c1 = Color(0xFF0B1220);
  static const _c2 = Color(0xFF0F2847);
  static const _c3 = Color(0xFF1E1B4B);

  /// Chu kỳ góc để sin/cos — nhiều nhịp trên một vòng 0..1
  double get _a => t * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Nền gradient hơi xoay / trôi theo thời gian
    final dx = 0.4 * math.sin(_a * 0.7);
    final dy = 0.35 * math.cos(_a * 0.5);
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment(dx - 0.8, dy - 1.0),
        end: Alignment(dx + 0.9, dy + 1.0),
        colors: [
          Color.lerp(_c1, _c3, 0.35 + 0.15 * math.sin(_a))!,
          _c3,
          Color.lerp(_c2, _c1, 0.4 + 0.2 * math.cos(_a * 1.1))!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Blob sáng — biên độ lớn hơn, tần số cao hơn để thấy rõ đang chạy
    _blob(canvas, size, 0, const Color(0xFF0E7490), 0.5);
    _blob(canvas, size, 1, const Color(0xFF38BDF8), 0.38);
    _blob(canvas, size, 2, const Color(0xFF6366F1), 0.32);
    _blob(canvas, size, 3, const Color(0xFF22D3EE), 0.26);

    _orbitRings(canvas, size);

    _drawPerspectiveGrid(canvas, size);

    _particles(canvas, size);
  }

  void _blob(Canvas canvas, Size size, int seed, Color color, double baseAlpha) {
    // Nhiều sóng chồng → chuyển động hữu cơ
    final p = _a * (1.2 + seed * 0.15) + seed * 1.9;
    final cx = size.width *
        (0.48 +
            0.22 * math.sin(p * 0.9) +
            0.12 * math.sin(p * 1.7 + 2) +
            0.08 * math.cos(p * 2.3));
    final cy = size.height *
        (0.38 +
            0.18 * math.cos(p * 0.85) +
            0.12 * math.sin(p * 1.4 + 1) +
            0.06 * math.sin(p * 2.1));
    final pulse = 0.92 + 0.08 * math.sin(_a * 3 + seed);
    final r = size.shortestSide * (0.32 + 0.12 * math.sin(p + seed) + 0.06 * math.sin(_a * 2)) * pulse;

    final a = (baseAlpha * (0.85 + 0.15 * math.sin(_a * 2 + seed))).clamp(0.12, 0.62);
    final c = color.withValues(alpha: a);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [c, c.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  void _orbitRings(Canvas canvas, Size size) {
    final cx = size.width * (0.5 + 0.08 * math.sin(_a * 1.1));
    final cy = size.height * (0.28 + 0.05 * math.cos(_a * 0.9));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var r = 0; r < 3; r++) {
      final rot = _a * (0.4 + r * 0.15) + r;
      final radius = size.shortestSide * (0.12 + r * 0.055) + 6 * math.sin(_a * 2 + r);
      final opacity = (0.07 + 0.06 * math.sin(_a * 3 + r)).clamp(0.04, 0.16);
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      canvas.translate(-cx, -cy);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: radius * 2.2, height: radius * 1.1),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawPerspectiveGrid(Canvas canvas, Size size) {
    final horizonY = size.height * (0.4 + 0.03 * math.sin(_a * 1.2));
    final vanishX = size.width * 0.5 + size.width * 0.12 * math.sin(_a * 1.4);
    const lineCount = 16;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05 + 0.04 * math.sin(_a * 2));

    for (var i = 0; i <= lineCount; i++) {
      final u = i / lineCount;
      final xBottom = u * size.width;
      final spread = 0.32 + 0.14 * math.sin(_a * 2 + u * 6.2);
      final xTop = vanishX + (xBottom - vanishX) * spread;
      canvas.drawLine(Offset(xBottom, size.height), Offset(xTop, horizonY), linePaint);
    }

    final horizPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.04 + 0.035 * math.cos(_a * 1.8));
    for (var h = 0; h < 11; h++) {
      final v = h / 11;
      final y = horizonY + (size.height - horizonY) * (v * v);
      final sway = size.width * 0.04 * math.sin(_a * 1.3 + v * 4);
      final drift = _a * 18 * (0.5 + v);
      canvas.drawLine(Offset(sway + math.sin(drift) * 6, y), Offset(size.width + sway + math.cos(drift) * 6, y), horizPaint);
    }
  }

  void _particles(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final p = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 64; i++) {
      final gx = rnd.nextDouble();
      final gy = rnd.nextDouble();
      final speed = 0.35 + rnd.nextDouble() * 1.15;
      final vx = 120 + rnd.nextDouble() * 160;
      final vy = 25 + rnd.nextDouble() * 55;
      // Trôi chéo + sóng — luôn đổi theo t
      var x = (gx * size.width + t * vx * speed + math.sin(_a * 2 + i * 0.5) * 24) % (size.width + 60) - 30;
      var y = (gy * size.height - t * vy * speed * 0.4 + math.cos(_a * 1.5 + i) * 18);
      y = y % (size.height + 20);
      if (y < 0) y += size.height + 20;

      final s = 1.2 + rnd.nextDouble() * 2.8;
      final tw = 0.5 + 0.5 * math.sin(_a * 4 + i * 0.7);
      final o = (0.06 + rnd.nextDouble() * 0.22) * (0.65 + 0.35 * tw);
      p.color = Colors.white.withValues(alpha: o.clamp(0.04, 0.35));
      canvas.drawCircle(Offset(x, y), s, p);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreeStyleScenePainter oldDelegate) => oldDelegate.t != t;
}

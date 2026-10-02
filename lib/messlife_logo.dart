import 'dart:math' as math;
import 'package:flutter/material.dart';

/// appIcon    -> messlife_appicon.png   (gradient background)
/// foreground -> messlife_foreground.png (transparent background, adaptive-icon safe zone)
enum MessLifeLogoVariant { appIcon, foreground }

class MessLifeLogo extends StatelessWidget {
  const MessLifeLogo({
    super.key,
    this.size = 280,
    this.variant = MessLifeLogoVariant.appIcon,
    this.rounded = false,
  });

  final double size;
  final MessLifeLogoVariant variant;

  /// Only for the appIcon variant. The PNG itself is a full square
  /// (the OS applies its own mask), but inside the app a rounded square looks nicer.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MessLifeLogoPainter(variant: variant, rounded: rounded),
    );
  }
}

class _MessLifeLogoPainter extends CustomPainter {
  _MessLifeLogoPainter({required this.variant, required this.rounded});

  final MessLifeLogoVariant variant;
  final bool rounded;

  // Palette sampled from the PNGs
  static const ink = Color(0xFF2B2D8A); // fork, spoon, plate ring, outlines
  static const gradStart = Color(0xFF3F4BA8);
  static const gradEnd = Color(0xFF261C66);
  static const cream = Color(0xFFF5F2EA);
  static const red = Color(0xFFD42026);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final isFg = variant == MessLifeLogoVariant.foreground;

    double x(double v) => v * s;
    double rad(double deg) => deg * math.pi / 180;
    Paint fill(Color c) => Paint()..color = c;
    Paint line(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ---------- Background (app icon only) ----------
    if (!isFg) {
      final bg = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradStart, gradEnd],
        ).createShader(Offset.zero & size);
      if (rounded) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(x(.18))),
          bg,
        );
      } else {
        canvas.drawRect(Offset.zero & size, bg);
      }
    }

    // ---------- Foreground: shrink into adaptive-icon safe zone ----------
    canvas.save();
    if (isFg) {
      canvas.translate(s / 2, s / 2);
      canvas.scale(.80);
      canvas.translate(-s / 2, -s / 2);
    }

    // ---------- Side arcs ----------
    final arcRect = Rect.fromCenter(
      center: Offset(x(.538), x(.49)),
      width: x(.666),
      height: x(.64),
    );
    canvas.drawArc(arcRect, rad(180), rad(68), false, line(cream, x(.014)));
    canvas.drawArc(arcRect, rad(292), rad(68), false, line(cream, x(.014)));

    // ---------- Chat bubbles ----------
    _drawBubble(canvas, Rect.fromLTWH(x(.425), x(.113), x(.14), x(.09)), false, x(.014));
    _drawBubble(canvas, Rect.fromLTWH(x(.525), x(.148), x(.13), x(.09)), true, x(.014));

    // ---------- Pin shadow ----------
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x(.538), x(.825)), width: x(.20), height: x(.068)),
      fill(cream),
    );

    // ---------- Pin ----------
    final pin = Path()
      ..moveTo(x(.538), x(.786))
      ..cubicTo(x(.455), x(.685), x(.338), x(.575), x(.338), x(.45))
      ..cubicTo(x(.338), x(.340), x(.425), x(.262), x(.538), x(.262))
      ..cubicTo(x(.651), x(.262), x(.738), x(.340), x(.738), x(.45))
      ..cubicTo(x(.738), x(.575), x(.621), x(.685), x(.538), x(.786))
      ..close();

    if (isFg) {
      canvas.drawPath(pin, fill(cream));
      canvas.drawPath(pin, line(ink, x(.008)));
    } else {
      // soft dark halo around the pin
      canvas.drawPath(pin, line(ink.withValues(alpha: .55), x(.024)));
      canvas.drawPath(pin, fill(cream));
    }

    // ---------- Plate ----------
    final c = Offset(x(.537), x(.459));
    canvas.drawCircle(c, x(.174), fill(ink));
    canvas.drawCircle(c, x(.152), fill(cream));
    canvas.drawCircle(
      c,
      x(.142),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = x(.006),
    );

    // ---------- Fork ----------
    for (final dx in [.476, .498, .520]) {
      canvas.drawLine(Offset(x(dx), x(.358)), Offset(x(dx), x(.418)), line(ink, x(.013)));
    }
    final forkHead = Path()
      ..moveTo(x(.476), x(.418))
      ..quadraticBezierTo(x(.476), x(.455), x(.498), x(.455))
      ..quadraticBezierTo(x(.520), x(.455), x(.520), x(.418));
    canvas.drawPath(forkHead, line(ink, x(.013)));
    canvas.drawLine(Offset(x(.498), x(.455)), Offset(x(.498), x(.59)), line(ink, x(.020)));

    // ---------- Spoon ----------
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x(.581), x(.383)), width: x(.063), height: x(.085)),
      fill(ink),
    );
    canvas.drawLine(Offset(x(.578), x(.42)), Offset(x(.583), x(.59)), line(ink, x(.022)));

    // small highlight stripe
    canvas.drawLine(Offset(x(.502), x(.535)), Offset(x(.530), x(.497)), line(cream, x(.009)));

    // ---------- TO LET sign ----------
    // post
    canvas.drawRect(Rect.fromLTRB(x(.262), x(.68), x(.300), x(.887)), fill(red));

    final signRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(x(.129), x(.566), x(.435), x(.690)),
      Radius.circular(x(.020)),
    );
    if (isFg) {
      // solid ink border
      canvas.drawRRect(signRect.inflate(x(.009)), fill(ink));
    } else {
      // soft dark halo
      canvas.drawRRect(signRect.inflate(x(.015)), fill(ink.withValues(alpha: .55)));
    }
    canvas.drawRRect(signRect, fill(red));

    final tp = TextPainter(
      text: TextSpan(
        text: 'TO LET',
        style: TextStyle(
          color: cream,
          fontSize: x(.074),
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x(.282) - tp.width / 2, x(.628) - tp.height / 2));

    canvas.restore();
  }

  void _drawBubble(Canvas canvas, Rect r, bool flip, double strokeWidth) {
    final paint = Paint()
      ..color = cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = r.width, h = r.height;
    final p = Path()..moveTo(r.left + w * .25, r.bottom);
    if (flip) {
      p
        ..lineTo(r.left + w * .55, r.bottom)
        ..lineTo(r.right - w * .22, r.bottom + h * .30)
        ..lineTo(r.right - w * .25, r.bottom);
    } else {
      p
        ..lineTo(r.left + w * .22, r.bottom + h * .30)
        ..lineTo(r.left + w * .45, r.bottom)
        ..lineTo(r.right - w * .25, r.bottom);
    }
    p
      ..quadraticBezierTo(r.right, r.bottom, r.right, r.center.dy)
      ..quadraticBezierTo(r.right, r.top, r.right - w * .25, r.top)
      ..lineTo(r.left + w * .25, r.top)
      ..quadraticBezierTo(r.left, r.top, r.left, r.center.dy)
      ..quadraticBezierTo(r.left, r.bottom, r.left + w * .25, r.bottom);

    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _MessLifeLogoPainter old) =>
      old.variant != variant || old.rounded != rounded;
}
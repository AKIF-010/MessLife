// MessLife BD splash screen (cold start, about 4.3 s).
//
// Same sequence as section 7 of the brand kit:
//   0.15 s roof drawn, 0.65 s walls, 0.8 s chimney, 1.2 s pin plants + ripples,
//   1.75 s fork, 2.3 s wordmark, 2.55 s loader fills, 2.65 s tagline, 3.5 s fade out.
//
// Differences from the kit file, as requested:
//   * No icon tile / border. The drawn house + pin + fork stays on screen as the
//     final logo (no PNG is faded in), so it is sharp at every screen size.
//   * Optional [waitFor] so Firebase / auth checks can run while the splash plays.
//   * Tap to skip after 1.5 s, reduced-motion support, light status bar icons.
//
// Usage:
//   MessLifeSplash(
//     waitFor: _bootstrap,                       // optional Future<void>
//     progress: _progress,                       // optional ValueListenable<double> 0..1
//     onFinished: () => Navigator.of(context).pushReplacement(...),
//   )
//
// Flow: Android system splash (icon) -> this animation -> the logo holds on
// screen until the real work ([waitFor]) is done, the loader bar follows the
// real [progress] -> fade out -> [onFinished].
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _mint = Color(0xFFEAF8F1);
const _ripple = Color(0xFF9FE6C5);
const _green = Color(0xFF11CE7E);
const _bg = Color(0xFF04222C);

class MessLifeSplash extends StatefulWidget {
  const MessLifeSplash({
    super.key,
    required this.onFinished,
    this.waitFor,
    this.progress,
  });

  /// Called once, after the animation has ended and [waitFor] (if any) is done.
  final VoidCallback onFinished;

  /// Work to finish before leaving the splash (Firebase init, auth check...).
  /// If it throws, the splash still finishes so the app never hangs here;
  /// handle the error in your own bootstrap code.
  final Future<void>? waitFor;

  /// Real loading progress 0..1. The loader bar fills according to it.
  final ValueListenable<double>? progress;

  @override
  State<MessLifeSplash> createState() => _MessLifeSplashState();
}

class _MessLifeSplashState extends State<MessLifeSplash>
    with TickerProviderStateMixin {
  static const double _total = 4.3; // seconds (full timeline)
  static const double _holdAt = 3.5; // seconds: logo holds here until ready
  static const double _hold = _holdAt / _total; // controller value
  static const double _logo = 180; // logical px
  static const double _skipAfter = 1.5; // seconds

  /// Timeline controller (0..4.3 s). Plays to the hold point, waits for the
  /// real work, then plays the fade-out.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4300),
  )..addStatusListener(_onStatus);

  /// Loader bar value: follows the real progress.
  late final AnimationController _bar = AnimationController(vsync: this);

  bool _holding = false; // reached the hold point, waiting for the real work
  bool _leaving = false; // fade-out started
  bool _done = false;
  bool _reducedChecked = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    widget.progress?.addListener(_syncBar);
    _syncBar();
    // Two frames, so the first frames are stable before the clock starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_reduced) _playToHold();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedChecked) return;
    _reducedChecked = true;
    // Reduced motion: show the final logo and wordmark, then continue.
    if (MediaQuery.disableAnimationsOf(context)) {
      _reduced = true;
      _c.value = 3.49 / _total;
      Future<void>.delayed(const Duration(milliseconds: 700), _awaitReady);
    }
  }

  void _playToHold({Duration? duration}) {
    _c.animateTo(
      _hold,
      duration: duration ?? const Duration(milliseconds: 3500),
      curve: Curves.linear,
    );
  }

  void _syncBar() {
    final p = (widget.progress?.value ?? 0).clamp(0.0, 1.0);
    _bar.animateTo(
      p,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
    );
  }

  void _onStatus(AnimationStatus st) {
    if (st != AnimationStatus.completed) return;
    if (_leaving) {
      _finish();
    } else {
      _awaitReady();
    }
  }

  /// Logo is fully drawn. Wait for the real work, fill the bar, then leave.
  Future<void> _awaitReady() async {
    if (_holding) return;
    _holding = true;
    try {
      await widget.waitFor;
    } catch (_) {
      // Bootstrap errors are handled by the caller; never stay stuck here.
    }
    if (!mounted) return;
    await _bar.animateTo(
      1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _leaving = true;
    _c.forward(); // fade out, then _onStatus -> _finish
  }

  void _finish() {
    if (_done) return;
    _done = true;
    if (mounted) widget.onFinished();
  }

  void _onTap() {
    if (_holding || _leaving) return;
    if (_c.value * _total >= _skipAfter) {
      // Jump to the finished logo; the real work still has to complete.
      _playToHold(duration: const Duration(milliseconds: 250));
    }
  }

  @override
  void dispose() {
    widget.progress?.removeListener(_syncBar);
    _c.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MediaQuery(
        // Brand splash: never scale with the system font size.
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Scaffold(
          backgroundColor: _bg,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final s = _c.value * _total;
                final fadeOut = 1 - _w(s, 3.5, 0.7, Curves.easeIn);
                return Opacity(
                  opacity: fadeOut,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Transform.translate(
                          offset: const Offset(0, -40),
                          child: SizedBox(
                            width: _logo,
                            height: _logo,
                            child: CustomPaint(
                              size: const Size(_logo, _logo),
                              painter: _LogoPainter(s),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: size.height * 0.5 + 40,
                        child: Opacity(
                          opacity: _w(s, 2.3, 0.5, Curves.easeOut),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Mess', style: _wordmark),
                              Text('Life', style: _wordmarkGreen),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: size.height * 0.5 + 82,
                        child: Opacity(
                          opacity: _w(s, 2.65, 0.5, Curves.easeOut),
                          child: const Text(
                            'Find and manage a mess',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13,
                              color: _ripple,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 64 + bottomInset,
                        child: Opacity(
                          opacity: _w(s, 2.3, 0.4, Curves.easeOut),
                          child: SizedBox(
                            width: 110,
                            height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: AnimatedBuilder(
                                animation: _bar,
                                builder: (context, _) => LinearProgressIndicator(
                                  value: _bar.value,
                                  backgroundColor: const Color(0x338AA6C7),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF0FA670),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

const _wordmark = TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontSize: 28,
  fontWeight: FontWeight.w800,
  color: Colors.white,
);
const _wordmarkGreen = TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontSize: 28,
  fontWeight: FontWeight.w800,
  color: _green,
);

/// Progress 0..1 of a window that starts at [start] seconds and lasts [dur].
double _w(double s, double start, double dur, [Curve curve = Curves.linear]) =>
    curve.transform(((s - start) / dur).clamp(0.0, 1.0));

// ---- logo geometry (600 x 600, same as the icon) ----
final Path _roof = Path()
  ..moveTo(94, 277)
  ..lineTo(299, 112)
  ..lineTo(504, 277);
final Path _wallL = Path()
  ..moveTo(131.5, 247)
  ..lineTo(131.5, 424)
  ..arcToPoint(const Offset(171.5, 464), radius: const Radius.circular(40), clockwise: false)
  ..lineTo(250, 464);
final Path _wallR = Path()
  ..moveTo(467.5, 247)
  ..lineTo(467.5, 424)
  ..arcToPoint(const Offset(427.5, 464), radius: const Radius.circular(40))
  ..lineTo(349, 464);
// Even-odd: the big rect minus the diagonal gap polygon. No Path.combine, so it
// behaves the same on Android, iOS and Web.
final Path _gapClip = Path()
  ..fillType = PathFillType.evenOdd
  ..addRect(const Rect.fromLTWH(-100, -100, 800, 800))
  ..moveTo(185.2, 430)
  ..lineTo(248.2, 500)
  ..lineTo(350.8, 500)
  ..lineTo(413.8, 430)
  ..close();
// Pin with the ring hole cut out using the even-odd rule (same as the SVG).
final Path _pin = Path()
  ..fillType = PathFillType.evenOdd
  ..moveTo(292, 522)
  ..cubicTo(252, 470, 178, 412, 178, 335.3)
  ..arcTo(
    Rect.fromCircle(center: const Offset(298.5, 335.3), radius: 120.5),
    math.pi,
    math.pi,
    false,
  )
  ..cubicTo(419, 412, 345, 470, 305, 522)
  ..quadraticBezierTo(298.5, 529.6, 292, 522)
  ..close()
  ..addOval(Rect.fromCircle(center: const Offset(298.5, 335.3), radius: 87.5));
// Fork outline traced from the icon file itself (600 x 600 space).
final Path _forkPath = Path()
  ..moveTo(293.3, 397.8)
  ..lineTo(292.3, 395.0)
  ..lineTo(290.4, 391.6)
  ..lineTo(286.8, 388.2)
  ..lineTo(274.9, 381.7)
  ..lineTo(271.1, 378.9)
  ..lineTo(267.0, 374.9)
  ..lineTo(263.8, 370.6)
  ..lineTo(260.7, 365.3)
  ..lineTo(257.4, 355.7)
  ..lineTo(256.2, 348.1)
  ..lineTo(256.1, 342.3)
  ..lineTo(258.1, 284.9)
  ..lineTo(258.6, 282.5)
  ..lineTo(259.8, 280.6)
  ..lineTo(261.0, 279.6)
  ..lineTo(263.4, 278.7)
  ..lineTo(269.6, 278.6)
  ..lineTo(271.1, 279.0)
  ..lineTo(273.4, 280.7)
  ..lineTo(274.9, 283.7)
  ..lineTo(280.6, 342.8)
  ..lineTo(281.5, 346.2)
  ..lineTo(284.0, 349.7)
  ..lineTo(287.3, 351.4)
  ..lineTo(290.7, 351.6)
  ..lineTo(291.7, 351.0)
  ..lineTo(292.8, 349.0)
  ..lineTo(293.2, 346.2)
  ..lineTo(284.9, 273.0)
  ..lineTo(286.2, 269.6)
  ..lineTo(288.8, 268.0)
  ..lineTo(296.4, 268.0)
  ..lineTo(298.6, 269.6)
  ..lineTo(299.9, 272.0)
  ..lineTo(309.7, 332.8)
  ..lineTo(310.9, 336.6)
  ..lineTo(313.6, 337.9)
  ..lineTo(317.0, 337.4)
  ..lineTo(319.1, 335.6)
  ..lineTo(320.6, 331.8)
  ..lineTo(320.5, 327.5)
  ..lineTo(313.1, 282.1)
  ..lineTo(314.5, 278.2)
  ..lineTo(316.5, 276.6)
  ..lineTo(318.4, 276.0)
  ..lineTo(325.1, 276.3)
  ..lineTo(327.5, 277.8)
  ..lineTo(329.2, 280.1)
  ..lineTo(341.5, 332.3)
  ..lineTo(342.4, 340.9)
  ..lineTo(342.1, 346.7)
  ..lineTo(341.1, 352.9)
  ..lineTo(339.2, 359.1)
  ..lineTo(336.8, 364.4)
  ..lineTo(332.9, 370.6)
  ..lineTo(322.1, 383.0)
  ..lineTo(320.2, 386.8)
  ..lineTo(319.3, 390.7)
  ..lineTo(319.6, 400.0)
  ..lineTo(323.6, 440.0)
  ..lineTo(297.6, 440.0)
  ..lineTo(293.5, 400.0)
  ..close();

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.s);
  final double s; // seconds since start

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 600;
    canvas.scale(k);

    // ripple rings from the pin tip
    for (final d in const [1.4, 1.58]) {
      final p = _w(s, d, 0.9, Curves.easeOut);
      if (p > 0 && p < 1) {
        canvas.drawCircle(
          const Offset(298.5, 522),
          100 * (0.15 + 3.05 * p),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / k
            ..color = _ripple.withValues(alpha: 0.75 * (1 - p)),
        );
      }
    }

    // The drawn logo stays as the final logo (no icon tile is faded in).
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _mint;
    canvas.save();
    canvas.clipPath(_gapClip);
    _partial(canvas, _roof, _w(s, 0.15, 0.6, Curves.easeInOut), line);
    _partial(canvas, _wallL, _w(s, 0.65, 0.55, Curves.easeInOut), line);
    _partial(canvas, _wallR, _w(s, 0.65, 0.55, Curves.easeInOut), line);
    canvas.restore();

    final ch = _w(s, 0.8, 0.35, Curves.easeOutBack);
    if (ch > 0) {
      canvas.save();
      canvas.translate(426, 215);
      canvas.scale(1, 0.2 + 0.8 * ch);
      canvas.translate(-426, -215);
      canvas.drawRRect(
        RRect.fromLTRBR(403, 135, 449, 215, const Radius.circular(8)),
        Paint()..color = _mint,
      );
      canvas.restore();
    }

    final pp = _w(s, 1.2, 0.55, Curves.easeOutBack);
    if (pp > 0) {
      canvas.save();
      canvas.translate(298.5, 526);
      canvas.scale(0.2 + 0.8 * pp);
      canvas.translate(-298.5, -526);
      final fp = _w(s, 1.75, 0.35, Curves.easeOut);
      if (fp > 0) _fork(canvas, fp); // under the ring, so no clipping is needed
      canvas.drawPath(_pin, Paint()..color = _green);
      canvas.restore();
    }
  }

  void _fork(Canvas c, double p) {
    // Fade and rise only: no scaling or rotation, so the edges stay crisp.
    c.save();
    c.translate(0, 14 * (1 - p));
    c.drawPath(_forkPath, Paint()..color = _mint.withValues(alpha: p));
    c.restore();
  }

  void _partial(Canvas c, Path p, double f, Paint paint) {
    if (f <= 0) return;
    for (final m in p.computeMetrics()) {
      c.drawPath(m.extractPath(0, m.length * f), paint);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.s != s;
}
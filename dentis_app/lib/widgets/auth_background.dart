import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final double overlayOpacity;

  const AuthBackground({
    super.key,
    this.overlayOpacity = .18,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(
          painter: AuthBackgroundPainter(),
        ),
        Container(
          color: Colors.black.withValues(alpha: overlayOpacity),
        ),
      ],
    );
  }
}

class AuthBrandMark extends StatelessWidget {
  final double size;
  final Color toothColor;
  final Color shineColor;

  const AuthBrandMark({
    super.key,
    this.size = 95,
    required this.toothColor,
    this.shineColor = Colors.white54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * .86,
            height: size * .86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .10),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: .22),
                  blurRadius: size * .25,
                  spreadRadius: size * .03,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size(size * .69, size * .80),
            painter: ToothPainter(
              color: toothColor,
              shineColor: shineColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthBackgroundPainter extends CustomPainter {
  const AuthBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xff000106),
          Color(0xff030616),
          Color(0xff001E1B),
        ],
        stops: [0, .48, 1],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final lowerGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.15, .72),
        radius: 1.25,
        colors: [
          const Color(0xff0A5F43).withValues(alpha: .62),
          const Color(0xff073D35).withValues(alpha: .18),
          Colors.transparent,
        ],
        stops: const [0, .46, 1],
      ).createShader(rect);
    canvas.drawRect(rect, lowerGlow);

    final upperGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(.72, -.95),
        radius: .95,
        colors: [
          const Color(0xff173A56).withValues(alpha: .38),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, upperGlow);

    final mainBand = Path()
      ..moveTo(size.width * -.10, size.height * -.08)
      ..lineTo(size.width * .09, size.height * -.08)
      ..lineTo(size.width * .66, size.height * 1.08)
      ..lineTo(size.width * .43, size.height * 1.08)
      ..close();
    _drawSoftBand(
      canvas,
      mainBand,
      const Color(0xff0E6B4A).withValues(alpha: .55),
    );

    final tealBand = Path()
      ..moveTo(size.width * .02, size.height * -.08)
      ..lineTo(size.width * .22, size.height * -.08)
      ..lineTo(size.width * .78, size.height * 1.08)
      ..lineTo(size.width * .56, size.height * 1.08)
      ..close();
    _drawSoftBand(
      canvas,
      tealBand,
      const Color(0xff1F6472).withValues(alpha: .28),
    );

    final darkCut = Path()
      ..moveTo(size.width * .14, size.height * -.08)
      ..lineTo(size.width * .28, size.height * -.08)
      ..lineTo(size.width * .85, size.height * 1.08)
      ..lineTo(size.width * .70, size.height * 1.08)
      ..close();
    _drawSoftBand(
      canvas,
      darkCut,
      Colors.black.withValues(alpha: .34),
    );

    final edgeBand = Path()
      ..moveTo(size.width * -.02, size.height * -.08)
      ..lineTo(size.width * .04, size.height * -.08)
      ..lineTo(size.width * .62, size.height * 1.08)
      ..lineTo(size.width * .56, size.height * 1.08)
      ..close();
    _drawSoftBand(
      canvas,
      edgeBand,
      const Color(0xff4C8F72).withValues(alpha: .34),
    );

    _drawTexture(canvas, size, mainBand);
    _drawTexture(canvas, size, tealBand);

    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: .88,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: .55),
        ],
        stops: const [.48, 1],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  void _drawSoftBand(Canvas canvas, Path path, Color color) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: .22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bandPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path.shift(const Offset(8, 0)), shadowPaint);
    canvas.drawPath(path, bandPaint);
  }

  void _drawTexture(Canvas canvas, Size size, Path clipPath) {
    canvas.save();
    canvas.clipPath(clipPath);

    final fleckPaint = Paint()
      ..color = const Color(0xff86D8BC).withValues(alpha: .055)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (var i = 0; i < 170; i++) {
      final x = (((i * 37) % 100) / 100) * size.width;
      final y = (((i * 61) % 100) / 100) * size.height;
      final length = 5 + (i % 9).toDouble();
      canvas.drawLine(
        Offset(x, y),
        Offset(x + length, y + 1),
        fleckPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AuthBackgroundPainter oldDelegate) => false;
}

class ToothPainter extends CustomPainter {
  final Color color;
  final Color shineColor;

  ToothPainter({
    required this.color,
    required this.shineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final toothPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: .18)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shinePaint = Paint()
      ..color = shineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    final tooth = Path()
      ..moveTo(w * .30, h * .12)
      ..cubicTo(w * .18, h * .15, w * .11, h * .28, w * .13, h * .43)
      ..cubicTo(w * .15, h * .56, w * .25, h * .64, w * .30, h * .75)
      ..cubicTo(w * .35, h * .87, w * .36, h * .97, w * .45, h * .97)
      ..cubicTo(w * .51, h * .97, w * .49, h * .79, w * .50, h * .70)
      ..cubicTo(w * .51, h * .79, w * .49, h * .97, w * .56, h * .97)
      ..cubicTo(w * .64, h * .97, w * .66, h * .87, w * .70, h * .75)
      ..cubicTo(w * .75, h * .64, w * .85, h * .56, w * .87, h * .43)
      ..cubicTo(w * .89, h * .28, w * .82, h * .15, w * .70, h * .12)
      ..cubicTo(w * .61, h * .10, w * .56, h * .20, w * .50, h * .20)
      ..cubicTo(w * .44, h * .20, w * .39, h * .10, w * .30, h * .12)
      ..close();

    canvas.drawPath(tooth.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(tooth, toothPaint);

    final shine = Path()
      ..moveTo(w * .32, h * .30)
      ..cubicTo(w * .39, h * .24, w * .46, h * .32, w * .50, h * .32)
      ..cubicTo(w * .54, h * .32, w * .61, h * .24, w * .68, h * .30);

    canvas.drawPath(shine, shinePaint);
  }

  @override
  bool shouldRepaint(covariant ToothPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shineColor != shineColor;
  }
}

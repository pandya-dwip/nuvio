import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;

  // Staggered entrance animations
  late Animation<double> _bgFade;
  late Animation<double> _doodlesFade;
  late Animation<double> _stickyNotesFade;
  late Animation<double> _logoFade;
  late Animation<double> _nameFade;
  late Animation<double> _pencilFade;

  @override
  void initState() {
    super.initState();

    // Entrance choreography controller (2.5 seconds total)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _doodlesFade = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _stickyNotesFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );

    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _pencilFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFE5DEC9), // Color behind curled sheets
      body: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return Opacity(
            opacity: _bgFade.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8F5), // Ivory Paper canvas background
          ),
          child: Stack(
            children: [
              // 1. PAPER TEXTURE GRAIN
              const Positioned.fill(
                child: CustomPaint(
                  painter: PaperTexturePainter(),
                ),
              ),

              // 2. PAPER CORNER CURLS
              Positioned.fill(
                child: CustomPaint(
                  painter: PaperDetailsPainter(),
                ),
              ),

              // 3. PENCIL SKETCHES (fade-in)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _doodlesFade.value,
                      child: child,
                    );
                  },
                  child: const CustomPaint(
                    painter: PencilSketchesPainter(),
                  ),
                ),
              ),

              // 4. BOTTOM LEFT NOTES SHEET & PENCIL
              Positioned(
                bottom: -20,
                left: -20,
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _doodlesFade.value,
                      child: Transform.rotate(
                        angle: 0.12,
                        child: child,
                      ),
                    );
                  },
                  child: const BottomLeftNotesSheet(),
                ),
              ),

              // 5. FLOATING STICKY NOTES
              // Sticky Note 1: Orange-Yellow "Idea!" at top left
              Positioned(
                top: size.height * 0.08,
                left: size.width * 0.08,
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _stickyNotesFade.value,
                      child: Transform.rotate(
                        angle: 0.15,
                        child: child,
                      ),
                    );
                  },
                  child: const StickyNoteWidget(
                    color: Color(0xFFF5A25D),
                    text: 'Idea!',
                    width: 96,
                    height: 96,
                    showUnderline: true,
                  ),
                ),
              ),

              // Sticky Note 2: Beige/Tan "Idea!" at middle left
              Positioned(
                top: size.height * 0.17,
                left: -15,
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _stickyNotesFade.value,
                      child: Transform.rotate(
                        angle: -0.08,
                        child: child,
                      ),
                    );
                  },
                  child: const StickyNoteWidget(
                    color: Color(0xFFEAD8C2),
                    text: 'Idea!',
                    width: 104,
                    height: 90,
                    textRotation: -0.05,
                    showUnderline: true,
                  ),
                ),
              ),

              // Sticky Note 3: Lined Warm Tan at bottom right
              Positioned(
                bottom: size.height * 0.16,
                right: -10,
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _stickyNotesFade.value,
                      child: Transform.rotate(
                        angle: 0.06,
                        child: child,
                      ),
                    );
                  },
                  child: const StickyNoteWidget(
                    color: Color(0xFFEAD8C2),
                    text: '',
                    width: 90,
                    height: 98,
                    showLines: true,
                  ),
                ),
              ),

              // 6. CENTER BRAND CONTENT
              Center(
                child: SizedBox(
                  width: 320,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cursive Swash Underline
                      Positioned(
                        top: 105,
                        child: AnimatedBuilder(
                          animation: _entranceController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoFade.value,
                              child: child,
                            );
                          },
                          child: CustomPaint(
                            size: const Size(180, 20),
                            painter: UnderlineSwashPainter(),
                          ),
                        ),
                      ),

                      // Cursive Name: "Nuvio"
                      Positioned(
                        top: 15,
                        child: AnimatedBuilder(
                          animation: _entranceController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _nameFade.value,
                              child: child,
                            );
                          },
                          child: Text(
                            'Nuvio',
                            style: GoogleFonts.greatVibes(
                              fontSize: 78,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF2C2A29), // Deep warm charcoal
                            ).copyWith(
                              fontFamilyFallback: ['Segoe Script', 'Lucida Handwriting', 'cursive'],
                            ),
                          ),
                        ),
                      ),

                      // Subtitle Name: "Organize.Imagine.Create."
                      Positioned(
                        top: 135,
                        child: AnimatedBuilder(
                          animation: _entranceController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _nameFade.value,
                              child: child,
                            );
                          },
                          child: Text(
                            'Organize.Imagine.Create.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 4.5,
                              color: const Color(0xFF6B665E), // Warm muted grey
                            ),
                          ),
                        ),
                      ),

                      // Mechanical Pencil lying next to Nuvio
                      Positioned(
                        left: 265,
                        top: 45,
                        child: AnimatedBuilder(
                          animation: _entranceController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _pencilFade.value,
                              child: Transform.translate(
                                offset: Offset((1.0 - _pencilFade.value) * 15.0, (1.0 - _pencilFade.value) * -15.0),
                                child: child,
                              ),
                            );
                          },
                          child: const MechanicalPencilWidget(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// CUSTOM PAINTER FOR PAPER TEXTURE (GRAIN & NOISE)
// ----------------------------------------------------
class PaperTexturePainter extends CustomPainter {
  const PaperTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5DEC9).withAlpha(20) // Very faint beige dots
      ..style = PaintingStyle.fill;
    
    // Deterministic random generator for consistent texture
    final random = math.Random(12345);
    
    // 1. Draw tiny paper fiber flecks
    for (int i = 0; i < 500; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 0.8 + 0.3;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // 2. Draw soft vertical background lines representing pulp grain
    final grainPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha(35)
      ..strokeWidth = 0.6;
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x + random.nextDouble() * 10 - 5, size.height), grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// CUSTOM PAINTER FOR PAGE CURLS
// ----------------------------------------------------
class PaperDetailsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. TOP RIGHT CURL
    final pathTopCurlBg = Path()
      ..moveTo(size.width - 120, 0)
      ..lineTo(size.width, 120)
      ..lineTo(size.width, 0)
      ..close();
    final bgPaint = Paint()..color = const Color(0xFFE5DEC9);
    canvas.drawPath(pathTopCurlBg, bgPaint);

    // Top Right Curl Shadow
    final shadowPaint1 = Paint()
      ..color = Colors.black.withAlpha(20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final shadowPath1 = Path()
      ..moveTo(size.width - 126, 0)
      ..quadraticBezierTo(size.width - 60, 60, size.width, 126)
      ..quadraticBezierTo(size.width - 30, 30, size.width - 126, 0)
      ..close();
    canvas.drawPath(shadowPath1, shadowPaint1);

    // Top Right Curl Flap
    final pathTopFlap = Path()
      ..moveTo(size.width - 120, 0)
      ..quadraticBezierTo(size.width - 55, 55, size.width, 120)
      ..cubicTo(size.width - 20, 85, size.width - 35, 15, size.width - 120, 0)
      ..close();

    final paintFlap1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFAF8F5), Color(0xFFDFD7C7)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(size.width - 120, 0, 120, 120));
    canvas.drawPath(pathTopFlap, paintFlap1);

    final foldEdgePaint = Paint()
      ..color = const Color(0xFFEBE5D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(pathTopFlap, foldEdgePaint);

    // 2. BOTTOM RIGHT CURL
    final pathBottomCurlBg = Path()
      ..moveTo(size.width - 130, size.height)
      ..lineTo(size.width, size.height - 130)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(pathBottomCurlBg, bgPaint);

    // Bottom Right Curl Shadow
    final shadowPath2 = Path()
      ..moveTo(size.width - 136, size.height)
      ..quadraticBezierTo(size.width - 65, size.height - 65, size.width, size.height - 136)
      ..quadraticBezierTo(size.width - 30, size.height - 30, size.width - 136, size.height)
      ..close();
    canvas.drawPath(shadowPath2, shadowPaint1);

    // Bottom Right Curl Flap
    final pathBottomFlap = Path()
      ..moveTo(size.width - 130, size.height)
      ..quadraticBezierTo(size.width - 60, size.height - 60, size.width, size.height - 130)
      ..cubicTo(size.width - 20, size.height - 90, size.width - 35, size.height - 15, size.width - 130, size.height)
      ..close();

    final paintFlap2 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFAF8F5), Color(0xFFDFD7C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(size.width - 130, size.height - 130, 130, 130));
    canvas.drawPath(pathBottomFlap, paintFlap2);
    canvas.drawPath(pathBottomFlap, foldEdgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// CUSTOM PAINTER FOR BACKGROUND PENCIL SKETCHES
// ----------------------------------------------------
class PencilSketchesPainter extends CustomPainter {
  const PencilSketchesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pencilPaint = Paint()
      ..color = const Color(0xFF8F887F).withAlpha(97) // Soft graphite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // 1. Top Doodle Arrow (Pointing down-left to the orange sticky note)
    final arrowPath = Path()
      ..moveTo(size.width * 0.32, 22)
      ..quadraticBezierTo(size.width * 0.26, 24, size.width * 0.22, 44);
    canvas.drawPath(arrowPath, pencilPaint);

    // Arrow Head pointing down-left
    final arrowHead = Path()
      ..moveTo(size.width * 0.22, 44)
      ..lineTo(size.width * 0.26, 38)
      ..moveTo(size.width * 0.22, 44)
      ..lineTo(size.width * 0.18, 41);
    canvas.drawPath(arrowHead, pencilPaint);

    // 2. Top-Middle Text Doodle: "Inamy." with a double underline
    final textPainterInamy = TextPainter(
      text: TextSpan(
        text: 'Inamy.',
        style: GoogleFonts.cedarvilleCursive(
          fontSize: 22,
          color: const Color(0xFF8F887F).withAlpha(140),
        ).copyWith(
          fontFamilyFallback: ['Segoe Script', 'cursive'],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterInamy.paint(canvas, Offset(size.width * 0.35, 12));

    // Double Underline for Inamy
    canvas.drawLine(Offset(size.width * 0.35, 38), Offset(size.width * 0.52, 36), pencilPaint);
    canvas.drawLine(Offset(size.width * 0.35 + 2, 41), Offset(size.width * 0.52 - 2, 39), pencilPaint);

    // 3. Right Side Doodle (Wavy cursive signature loop trail)
    final pathRightScribble = Path()
      ..moveTo(size.width * 0.94, size.height * 0.18)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.22, size.width * 0.96, size.height * 0.24)
      ..quadraticBezierTo(size.width * 0.99, size.height * 0.26, size.width * 0.90, size.height * 0.29)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.32, size.width * 0.97, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.99, size.height * 0.38, size.width * 0.94, size.height * 0.41);
    canvas.drawPath(pathRightScribble, pencilPaint);

    // 4. Middle-Left Doodle (Signature scribble like "Thy.")
    final textPainterThy = TextPainter(
      text: TextSpan(
        text: 'Thy.',
        style: GoogleFonts.cedarvilleCursive(
          fontSize: 24,
          color: const Color(0xFF8F887F).withAlpha(130),
        ).copyWith(
          fontFamilyFallback: ['Segoe Script', 'cursive'],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterThy.paint(canvas, Offset(12, size.height * 0.35));

    // Stroke crossing the signature
    canvas.drawLine(Offset(10, size.height * 0.41), Offset(80, size.height * 0.38), pencilPaint);

    // 5. Bottom Right concentric ring cup stain (Coffee ring)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.92, size.height * 0.69), radius: 36),
      0.1,
      1.85 * math.pi,
      false,
      pencilPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.93, size.height * 0.69), radius: 32),
      -0.3,
      1.65 * math.pi,
      false,
      pencilPaint,
    );

    // 6. Flower doodle above bottom-right sticky note
    final flowerPaint = Paint()
      ..color = const Color(0xFF8F887F).withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    
    final flowerCenter = Offset(size.width * 0.93, size.height * 0.61);
    canvas.drawCircle(flowerCenter, 3, flowerPaint);
    for (int i = 0; i < 5; i++) {
      final double angle = i * 2 * math.pi / 5;
      final petalCenter = Offset(
        flowerCenter.dx + 6 * math.cos(angle),
        flowerCenter.dy + 6 * math.sin(angle),
      );
      canvas.drawCircle(petalCenter, 4, flowerPaint);
    }
    // Leaf / Stem
    final stemPath = Path()
      ..moveTo(flowerCenter.dx, flowerCenter.dy + 10)
      ..quadraticBezierTo(flowerCenter.dx - 4, flowerCenter.dy + 16, flowerCenter.dx - 1, flowerCenter.dy + 22);
    canvas.drawPath(stemPath, flowerPaint);

    // 7. Four-pointed sparkle star in the bottom-right corner next to curl
    final starPaint = Paint()
      ..color = const Color(0xFFFAF9F6)
      ..style = PaintingStyle.fill;
    
    final starCenter = Offset(size.width - 45, size.height - 45);
    final starPath = Path()
      ..moveTo(starCenter.dx, starCenter.dy - 12)
      ..quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx + 12, starCenter.dy)
      ..quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx, starCenter.dy + 12)
      ..quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx - 12, starCenter.dy)
      ..quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx, starCenter.dy - 12)
      ..close();
    
    canvas.drawPath(starPath, starPaint);
    canvas.drawPath(starPath, Paint()
      ..color = const Color(0xFFDFD7C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// STICKY NOTE WIDGET
// ----------------------------------------------------
class StickyNoteWidget extends StatelessWidget {
  final Color color;
  final String text;
  final double width;
  final double height;
  final double textRotation;
  final bool showLines;
  final bool showUnderline;

  const StickyNoteWidget({
    super.key,
    required this.color,
    required this.text,
    required this.width,
    required this.height,
    this.textRotation = 0.06,
    this.showLines = false,
    this.showUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: StickyNotePainter(
          baseColor: color,
          showLines: showLines,
          showUnderline: showUnderline,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: text.isNotEmpty
              ? Transform.rotate(
                  angle: textRotation,
                  child: Text(
                    text,
                    style: GoogleFonts.caveat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF554B3E),
                    ).copyWith(
                      fontFamilyFallback: ['Comic Sans MS', 'Ink Free', 'cursive'],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class StickyNotePainter extends CustomPainter {
  final Color baseColor;
  final bool showLines;
  final bool showUnderline;

  StickyNotePainter({
    required this.baseColor,
    required this.showLines,
    required this.showUnderline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sticky Note Main Body with soft page curl shadow on the bottom-right
    final paperPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // Soft drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final bodyPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 12)
      ..quadraticBezierTo(size.width - 6, size.height - 6, size.width - 12, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(bodyPath.shift(const Offset(2, 4)), shadowPaint);
    canvas.drawPath(bodyPath, paperPaint);

    // 2. Draw Curl at bottom-right
    final curlShadow = Paint()
      ..color = Colors.black.withAlpha(20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    final curlShadowPath = Path()
      ..moveTo(size.width - 15, size.height)
      ..quadraticBezierTo(size.width - 8, size.height - 8, size.width, size.height - 15)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(curlShadowPath, curlShadow);

    final curlPath = Path()
      ..moveTo(size.width - 14, size.height)
      ..quadraticBezierTo(size.width - 6, size.height - 6, size.width, size.height - 14)
      ..quadraticBezierTo(size.width - 7, size.height - 3, size.width - 14, size.height)
      ..close();
    final curlPaint = Paint()..color = baseColor.withAlpha(220); // slightly shaded
    canvas.drawPath(curlPath, curlPaint);

    // 3. Draw mock text lines on note if requested
    if (showLines) {
      final linePaint = Paint()
        ..color = const Color(0xFF635645).withAlpha(76)
        ..strokeWidth = 1.0;
      
      canvas.drawLine(const Offset(12, 24), Offset(size.width - 12, 24), linePaint);
      canvas.drawLine(const Offset(12, 38), Offset(size.width - 12, 38), linePaint);
      canvas.drawLine(const Offset(12, 52), Offset(size.width - 20, 52), linePaint);
      canvas.drawLine(const Offset(12, 66), Offset(size.width - 24, 66), linePaint);
    }

    // 4. Draw hand-drawn underline under the text if requested
    if (showUnderline) {
      final underlinePaint = Paint()
        ..color = const Color(0xFF554B3E).withAlpha(128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(12, size.height * 0.72)
        ..quadraticBezierTo(size.width * 0.45, size.height * 0.78, size.width - 16, size.height * 0.7);
      canvas.drawPath(path, underlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// BOTTOM LEFT NOTES SHEET & WOOD PENCIL
// ----------------------------------------------------
class BottomLeftNotesSheet extends StatelessWidget {
  const BottomLeftNotesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        border: Border.all(color: const Color(0xFFE5E2D8), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Notepad Ruling Lines (Pink margin, Blue horizontal)
          Positioned.fill(
            child: CustomPaint(
              painter: NotepadRulingPainter(),
            ),
          ),

          // Notepad handwritten notes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thoughts',
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A453F),
                  ).copyWith(
                    fontFamilyFallback: ['Comic Sans MS', 'Ink Free', 'cursive'],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Capture ideas instantly\n• Secure & offline-first\n• Organized folders',
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    height: 1.6,
                    color: const Color(0xFF6B655E),
                  ).copyWith(
                    fontFamilyFallback: ['Comic Sans MS', 'Ink Free', 'cursive'],
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'nuvio.',
                    style: GoogleFonts.cedarvilleCursive(
                      fontSize: 16,
                      color: const Color(0xFF4A453F),
                    ).copyWith(
                      fontFamilyFallback: ['Segoe Script', 'cursive'],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Diagonal wood pencil lying next to memo sheet
          Positioned(
            right: -32,
            bottom: 25,
            child: Transform.rotate(
              angle: -0.4,
              child: const WoodPencilWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class NotepadRulingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Spiral notepad holes at the top edge
    final holesPaint = Paint()
      ..color = const Color(0xFFE5DEC9) // matches underlying desk sheet color
      ..style = PaintingStyle.fill;
    
    final holeBorder = Paint()
      ..color = const Color(0xFFE5E2D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 8; i++) {
      final double x = 18.0 + i * 20.0;
      canvas.drawCircle(Offset(x, 6), 3, holesPaint);
      canvas.drawCircle(Offset(x, 6), 3, holeBorder);
    }

    // Soft light blue ruling lines
    final linePaint = Paint()
      ..color = const Color(0xFFD4E2F0)
      ..strokeWidth = 0.8;
    
    double startY = 55.0;
    double spacing = 22.0;
    for (int i = 0; i < 7; i++) {
      double y = startY + i * spacing;
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), linePaint);
    }

    // Left margin line
    final marginPaint = Paint()
      ..color = const Color(0xFFF0A0A0) // Soft pink margin
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(28, 0), Offset(28, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Wood Pencil vector drawing
class WoodPencilWidget extends StatelessWidget {
  const WoodPencilWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 130),
      painter: WoodPencilPainter(),
    );
  }
}

class WoodPencilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = const Color(0xFFDF9E5A); // Yellow-orange body
    final graphitePaint = Paint()..color = const Color(0xFF333333); // Lead tip
    final eraserPaint = Paint()..color = const Color(0xFFFCA5A5); // Pink eraser
    final ferrulePaint = Paint()..color = const Color(0xFF9CA3AF); // Silver band

    // 1. Draw pencil body
    canvas.drawRect(Rect.fromLTWH(0, 16, size.width, size.height - 30), bodyPaint);
    
    // Stripe ridges
    final stripePaint = Paint()..color = const Color(0xFFC27B38);
    canvas.drawRect(Rect.fromLTWH(3, 16, 2, size.height - 30), stripePaint);
    canvas.drawRect(Rect.fromLTWH(8, 16, 2, size.height - 30), stripePaint);

    // 2. Draw pencil tip (shaved wood cone)
    final tipPath = Path()
      ..moveTo(0, 16)
      ..lineTo(size.width, 16)
      ..lineTo(size.width / 2, 0)
      ..close();
    final conePaint = Paint()..color = const Color(0xFFF6E8D6); // Wood texture
    canvas.drawPath(tipPath, conePaint);

    // Graphite lead tip
    final leadPath = Path()
      ..moveTo(size.width * 0.35, 6)
      ..lineTo(size.width * 0.65, 6)
      ..lineTo(size.width / 2, 0)
      ..close();
    canvas.drawPath(leadPath, graphitePaint);

    // 3. Draw eraser & silver band
    canvas.drawRect(Rect.fromLTWH(0, size.height - 14, size.width, 6), ferrulePaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 8, size.width, 8), eraserPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// HAND-DRAWN SWASH UNDERLINE PAINTER
// ----------------------------------------------------
class UnderlineSwashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final swashPaint = Paint()
      ..color = const Color(0xFFC7B198).withAlpha(217) // Sand swash
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path1 = Path()
      ..moveTo(6, 6)
      ..quadraticBezierTo(size.width * 0.4, 12, size.width * 0.72, 8);

    final path2 = Path()
      ..moveTo(size.width * 0.42, 10)
      ..quadraticBezierTo(size.width * 0.7, 11, size.width - 6, 12)
      ..quadraticBezierTo(size.width * 0.8, 13, size.width * 0.68, 15);

    canvas.drawPath(path1, swashPaint);
    canvas.drawPath(path2, swashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// SLANTED MECHANICAL PENCIL WIDGET NEXT TO LOGO
// ----------------------------------------------------
class MechanicalPencilWidget extends StatelessWidget {
  const MechanicalPencilWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -2.4, // Rotated to point down-left next to 'o'
      child: CustomPaint(
        size: const Size(4.5, 90),
        painter: MechanicalPencilPainter(),
      ),
    );
  }
}

class MechanicalPencilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final clipPaint = Paint()..color = const Color(0xFF6B7280); // Dark grey clip
    final metalPaint = Paint()..color = const Color(0xFFD1D5DB); // Silver metal
    final bodyPaint = Paint()..color = const Color(0xFF374151); // Matte black body
    final leadPaint = Paint()..color = const Color(0xFF4B5563); // Graphite lead

    // 1. Silver tip cone (height = 8)
    final tipPath = Path()
      ..moveTo(size.width * 0.1, 8)
      ..lineTo(size.width * 0.9, 8)
      ..lineTo(size.width / 2, 0)
      ..close();
    canvas.drawPath(tipPath, metalPaint);

    // Graphite lead tip (height = 2)
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 0.4, 0, 0.8, 2), leadPaint);

    // 2. Main body barrel (from y = 8 to y = size.height - 15)
    canvas.drawRect(Rect.fromLTWH(0, 8, size.width, size.height - 23), bodyPaint);

    // Ridged metal grip lines (thinner to fit the smaller size)
    final gripPaint = Paint()..color = const Color(0xFF9CA3AF);
    canvas.drawRect(Rect.fromLTWH(0, 11, size.width, 2), gripPaint);
    canvas.drawRect(Rect.fromLTWH(0, 15, size.width, 2), gripPaint);
    canvas.drawRect(Rect.fromLTWH(0, 19, size.width, 2), gripPaint);

    // 3. Top silver cap & metal ring
    canvas.drawRect(Rect.fromLTWH(0, size.height - 15, size.width, 3), metalPaint);
    canvas.drawRect(Rect.fromLTWH(0.5, size.height - 12, size.width - 1, 12), metalPaint);

    // 4. Metal clip extending down
    canvas.drawRect(Rect.fromLTWH(size.width - 1.2, size.height - 28, 1.2, 16), clipPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 2.0, size.height - 28, 2.0, 2.0), clipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

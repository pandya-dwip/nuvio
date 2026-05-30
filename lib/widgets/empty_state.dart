import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Illustrated Sketch of a Canvas
            CustomPaint(
              size: const Size(120, 120),
              painter: EmptyStateIllustrationPainter(),
            ),
            const SizedBox(height: 28),
            // 2. Bold Title
            Text(
              'A blank canvas',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C2A29), // Deep warm charcoal
              ),
            ),
            const SizedBox(height: 10),
            // 3. Subtitle Description
            Text(
              'Tap the + button below to create your first note or folder and organize your thoughts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: const Color(0xFF6B665E), // Muted warm grey
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pencilPaint = Paint()
      ..color = const Color(0xFFC7B198).withAlpha(150) // Soft sand color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final solidPaint = Paint()
      ..color = const Color(0xFFFFFFFF) // Clean white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFE5DEC9) // Soft beige border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Draw a slanted notepad sheet in the background
    final sheetPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.25)
      ..lineTo(size.width * 0.8, size.height * 0.15)
      ..lineTo(size.width * 0.9, size.height * 0.75)
      ..lineTo(size.width * 0.25, size.height * 0.85)
      ..close();
    canvas.drawPath(sheetPath, solidPaint);
    canvas.drawPath(sheetPath, borderPaint);

    // Drawing ruling lines on sheet
    final rulingPaint = Paint()
      ..color = const Color(0xFFD4E2F0).withAlpha(180)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.38),
      Offset(size.width * 0.75, size.height * 0.32),
      rulingPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.50),
      Offset(size.width * 0.77, size.height * 0.44),
      rulingPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.62),
      Offset(size.width * 0.79, size.height * 0.56),
      rulingPaint,
    );

    // 2. Draw a folder outline overlapping
    final folderPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.45)
      ..lineTo(size.width * 0.45, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.50)
      ..lineTo(size.width * 0.85, size.height * 0.50)
      ..lineTo(size.width * 0.85, size.height * 0.85)
      ..lineTo(size.width * 0.3, size.height * 0.85)
      ..close();
    canvas.drawPath(folderPath, Paint()..color = const Color(0xFFEAD8C2).withAlpha(180));
    canvas.drawPath(folderPath, borderPaint);

    // 3. Draw a sketchy pencil drawing a star
    final starCenter = Offset(size.width * 0.55, size.height * 0.55);
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final double angle = i * 4 * math.pi / 5 - math.pi / 2;
      final x = starCenter.dx + 12 * math.cos(angle);
      final y = starCenter.dy + 12 * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, pencilPaint);

    // Faint circular sketch loops around the canvas
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.5), radius: 48),
      0,
      1.7 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFFC7B198).withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

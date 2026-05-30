import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FolderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final tabWidth = size.width * 0.35 > 120.0 ? 120.0 : size.width * 0.35;
    final tabHeight = 12.0;
    final radius = 12.0;
    
    // Start top-left of the tab
    path.moveTo(0, tabHeight);
    
    // Tab top shape
    path.lineTo(radius, tabHeight);
    path.quadraticBezierTo(radius * 1.5, 0, radius * 2.5, 0); // curve up to tab top
    path.lineTo(tabWidth - radius * 2.5, 0);
    path.quadraticBezierTo(tabWidth - radius * 1.5, 0, tabWidth - radius, tabHeight); // curve down to body top
    
    // Body top line
    path.lineTo(size.width - radius, tabHeight);
    path.quadraticBezierTo(size.width, tabHeight, size.width, tabHeight + radius);
    
    // Right side
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    
    // Bottom
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    
    // Left side
    path.lineTo(0, tabHeight + radius);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class FolderShadowPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  FolderShadowPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final path = FolderClipper().getClip(size);
    
    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.3 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);
    
    // Draw subtle border
    final borderPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FolderWidget extends StatelessWidget {
  final String name;
  final int noteCount;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isPinned;

  const FolderWidget({
    super.key,
    required this.name,
    required this.noteCount,
    required this.color,
    required this.onTap,
    required this.onLongPress,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // In dark mode, if the folder has white color, use a darker surface color.
    final folderColor = (color.value == 0xFFFFFFFF && isDark)
        ? Theme.of(context).colorScheme.surface
        : color;

    final isFolderColorDark = ThemeData.estimateBrightnessForColor(folderColor) == Brightness.dark;
    final textColor = isFolderColorDark ? Colors.white : const Color(0xFF2C2A29);
    final textMuted = isFolderColorDark ? Colors.white70 : const Color(0xFF6B665E);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: CustomPaint(
          painter: FolderShadowPainter(color: folderColor, isDark: isDark),
          child: ClipPath(
            clipper: FolderClipper(),
            child: Container(
              width: double.infinity,
              height: 80, // total height including tab
              color: folderColor,
              padding: const EdgeInsets.only(top: 18.0, left: 16.0, right: 16.0, bottom: 10.0), // offset top padding for the tab
              child: Row(
                children: [
                  Icon(
                    isPinned ? Icons.push_pin : Icons.folder_rounded,
                    color: isPinned ? Theme.of(context).primaryColor : textColor.withOpacity(0.8),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFolderColorDark ? Colors.white24 : Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      noteCount == 1 ? '1 note' : '$noteCount notes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

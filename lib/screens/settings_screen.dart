import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const SettingsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack ?? () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                  Text(
                    'Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF1C1E22) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search settings...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: subtleColor),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Theme.of(context).primaryColor, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: false,
                  ),
                ),
              ),
            ),

            Divider(
              color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
              height: 1,
            ),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        Icons.construction_rounded,
                        size: 48,
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Coming Soon',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Settings are being crafted with care.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: subtleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

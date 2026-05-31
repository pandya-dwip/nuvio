import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumColor {
  final String name;
  final Color color;
  const PremiumColor(this.name, this.color);
}

class AppTheme {
  AppTheme._();

  static const List<PremiumColor> premiumColors = [
    PremiumColor('Royal Blue (Default)', Color(0xFF5B67F1)),
    PremiumColor('Indigo Mist', Color(0xFF6C63FF)),
    PremiumColor('Electric Violet', Color(0xFF7C4DFF)),
    PremiumColor('Deep Purple', Color(0xFF8E44AD)),
    PremiumColor('Cyber Lavender', Color(0xFF9B59B6)),
    PremiumColor('Sky Blue', Color(0xFF4A90E2)),
    PremiumColor('Ocean Blue', Color(0xFF007AFF)),
    PremiumColor('Azure Glow', Color(0xFF3A86FF)),
    PremiumColor('Neon Blue', Color(0xFF2563EB)),
    PremiumColor('Sapphire', Color(0xFF0F52BA)),
    PremiumColor('Aqua Cyan', Color(0xFF00BCD4)),
    PremiumColor('Turquoise', Color(0xFF1ABC9C)),
    PremiumColor('Mint Green', Color(0xFF2ECC71)),
    PremiumColor('Emerald', Color(0xFF27AE60)),
    PremiumColor('Lime Green', Color(0xFF84CC16)),
    PremiumColor('Soft Olive', Color(0xFF6B8E23)),
    PremiumColor('Golden Yellow', Color(0xFFF4B400)),
    PremiumColor('Amber', Color(0xFFFFB300)),
    PremiumColor('Orange Glow', Color(0xFFFF9800)),
    PremiumColor('Sunset Orange', Color(0xFFFF7043)),
    PremiumColor('Coral Red', Color(0xFFFF6B6B)),
    PremiumColor('Crimson', Color(0xFFDC3545)),
    PremiumColor('Rose Pink', Color(0xFFFF4D8D)),
    PremiumColor('Hot Pink', Color(0xFFE91E63)),
    PremiumColor('Magenta', Color(0xFFD633FF)),
    PremiumColor('Soft Peach', Color(0xFFFF9E80)),
    PremiumColor('Blush Pink', Color(0xFFF78FB3)),
    PremiumColor('Lavender', Color(0xFFB388FF)),
    PremiumColor('Periwinkle', Color(0xFF8FA8FF)),
    PremiumColor('Ice Blue', Color(0xFFA7C7FF)),
    PremiumColor('Arctic Cyan', Color(0xFF7FDBFF)),
    PremiumColor('Teal Blue', Color(0xFF008080)),
    PremiumColor('Sea Green', Color(0xFF2E8B57)),
    PremiumColor('Forest Green', Color(0xFF228B22)),
    PremiumColor('Neon Mint', Color(0xFF00E5A8)),
    PremiumColor('Lemon Lime', Color(0xFFCDDC39)),
    PremiumColor('Soft Gold', Color(0xFFD4AF37)),
    PremiumColor('Bronze', Color(0xFFCD7F32)),
    PremiumColor('Burnt Orange', Color(0xFFD97706)),
    PremiumColor('Ruby Red', Color(0xFFC2185B)),
    PremiumColor('Wine Purple', Color(0xFF722F37)),
    PremiumColor('Plum', Color(0xFF8E4585)),
    PremiumColor('Midnight Blue', Color(0xFF1E3A8A)),
    PremiumColor('Slate Blue', Color(0xFF5A67D8)),
    PremiumColor('Graphite', Color(0xFF4B5563)),
    PremiumColor('Charcoal', Color(0xFF36454F)),
    PremiumColor('Steel Blue', Color(0xFF4682B4)),
    PremiumColor('Frost Violet', Color(0xFFA78BFA)),
    PremiumColor('Soft Cyan', Color(0xFF67E8F9)),
    PremiumColor('Neon Purple', Color(0xFF9333EA)),
  ];


  // Dark Colors (Default)
  static const Color darkBg = Color(0xFF0D0E10);
  static const Color darkSurface = Color(0xFF15171A);
  static const Color darkCard = Color(0xFF1E2124);
  static const Color darkBorder = Color(0xFF2D3136);
  static const Color darkPrimary = Color(0xFFFFFFFF); // Clean white primary for B&W in Dark mode
  static const Color darkPrimaryLight = Color(0xFFE5E7EB);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // Light Colors
  static const Color lightBg = Color(0xFFF3F3F8); // premium cool grey background
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightPrimary = Color(0xFF000000); // Clean black primary for B&W in Light mode
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // Accent Colors for Folders / Tags
  static const Color tagBlue = Color(0xFF2563EB);
  static const Color tagGreen = Color(0xFF059669);
  static const Color tagYellow = Color(0xFFD97706);
  static const Color tagRed = Color(0xFFDC2626);
  static const Color tagPurple = Color(0xFF7C3AED);

  // 50 Preset Colors requested by the user
  static const Map<String, int> presetColors = {
    'Red': 0xFFEF5350,
    'Blue': 0xFF42A5F5,
    'Green': 0xFF66BB6A,
    'Yellow': 0xFFFFEE58,
    'Orange': 0xFFFFA726,
    'Purple': 0xFFAB47BC,
    'Pink': 0xFFEC407A,
    'Brown': 0xFF8D6E63,
    'Black': 0xFF212121,
    'White': 0xFFFFFFFF,
    'Gray': 0xFF9E9E9E,
    'Cyan': 0xFF26C6DA,
    'Magenta': 0xFFE040FB,
    'Lime': 0xFFD4E157,
    'Maroon': 0xFF800000,
    'Navy': 0xFF000080,
    'Olive': 0xFF808000,
    'Teal': 0xFF26A69A,
    'Silver': 0xFFC0C0C0,
    'Gold': 0xFFFFD700,
    'Beige': 0xFFF5F5DC,
    'Coral': 0xFFFF7F50,
    'Crimson': 0xFFDC143C,
    'Indigo': 0xFF3F51B5,
    'Ivory': 0xFFFFFFF0,
    'Khaki': 0xFFF0E68C,
    'Lavender': 0xFFE6E6FA,
    'Mint': 0xFFA5D6A7,
    'Mustard': 0xFFFFDB58,
    'Peach': 0xFFFFD1A9,
    'Plum': 0xFFDDA0DD,
    'Salmon': 0xFFFFA07A,
    'Tan': 0xFFD2B48C,
    'Turquoise': 0xFF40E0D0,
    'Violet': 0xFFEE82EE,
    'Amber': 0xFFFFBF00,
    'Azure': 0xFFF0FFFF,
    'Burgundy': 0xFF800020,
    'Charcoal': 0xFF36454F,
    'Chocolate': 0xFF7B3F00,
    'Emerald': 0xFF50C878,
    'Jade': 0xFF00A86B,
    'Lilac': 0xFFC8A2C8,
    'Mauve': 0xFFE0B0FF,
    'Ochre': 0xFFCC7722,
    'Periwinkle': 0xFFCCCCFF,
    'Rose': 0xFFFF007F,
    'Sapphire': 0xFF0F52BA,
    'Scarlet': 0xFFFF2400,
    'Vermilion': 0xFFE34234,
  };

  static Color getSoftBg(Color color, bool isDark) {
    return color.withAlpha(isDark ? 38 : 20);
  }

  // Dark Theme Data with customizable primary color
  static ThemeData darkTheme(Color primaryColor) {
    // If the primary color is black, in dark theme let's default to white for visibility
    final activePrimary = primaryColor.value == Colors.black.value ? Colors.white : primaryColor;
    
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: activePrimary,
      colorScheme: ColorScheme.dark(
        primary: activePrimary,
        secondary: activePrimary,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: darkTextPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activePrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextMuted),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: activePrimary,
        selectionColor: activePrimary.withOpacity(0.3),
        selectionHandleColor: activePrimary,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: activePrimary,
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: activePrimary,
        foregroundColor: activePrimary.value == Colors.white.value ? Colors.black : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Light Theme Data with customizable primary color
  static ThemeData lightTheme(Color primaryColor) {
    // If the primary color is white, in light theme let's default to black for visibility
    final activePrimary = primaryColor.value == Colors.white.value ? Colors.black : primaryColor;
    
    final base = ThemeData.light();
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: activePrimary,
      colorScheme: ColorScheme.light(
        primary: activePrimary,
        secondary: activePrimary,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        outline: lightBorder,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activePrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextMuted),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: activePrimary, // Set caret to selected primary color (black by default)
        selectionColor: activePrimary.withOpacity(0.2),
        selectionHandleColor: activePrimary,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: activePrimary,
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: activePrimary,
        foregroundColor: activePrimary.value == Colors.white.value ? Colors.black : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class PremiumColor {
  final String name;
  final Color color;
  const PremiumColor(this.name, this.color);
}

class AccentColorScreen extends ConsumerStatefulWidget {
  const AccentColorScreen({super.key});

  @override
  ConsumerState<AccentColorScreen> createState() => _AccentColorScreenState();
}

class _AccentColorScreenState extends ConsumerState<AccentColorScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  static const List<PremiumColor> _allColors = [
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = ref.watch(customThemeColorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final scaffoldBg = isDark ? const Color(0xFF0D0E10) : const Color(0xFFF3F3F8);
    final cardBg = isDark ? const Color(0xFF1E2124) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E2E7);

    final filteredColors = _allColors.where((item) {
      return item.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                  Text(
                    'Accent Color',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E22) : const Color(0xFFE8E8ED),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search 50 premium colors...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: subtleColor),
                    prefixIcon: Icon(Icons.search_rounded, color: activeColor, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: subtleColor, size: 18),
                            onPressed: () => setState(() {
                              _query = '';
                              _searchCtrl.clear();
                            }),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: false,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),

            // Color list
            Expanded(
              child: filteredColors.isEmpty
                  ? Center(
                      child: Text(
                        'No matching colors found.',
                        style: GoogleFonts.plusJakartaSans(color: subtleColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredColors.length,
                      itemBuilder: (context, index) {
                        final premium = filteredColors[index];
                        final isSelected = premium.color.value == activeColor.value;
                        final isColorLight = premium.color.computeLuminance() > 0.6;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? premium.color : borderCol,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              ref.read(customThemeColorProvider.notifier).updateColor(premium.color);
                              Navigator.pop(context); // Go back to settings page
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  // Colored circle
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: premium.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: isColorLight ? Colors.black87 : Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      premium.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

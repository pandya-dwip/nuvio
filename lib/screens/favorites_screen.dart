import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../screens/note_detail_screen.dart';
import '../widgets/note_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF8F887F);
    final scaffoldBg = isDark ? const Color(0xFF0D0E10) : const Color(0xFFF3F3F8);

    final allNotes = ref.watch(notesProvider);
    List<Note> favorites = allNotes.where((n) => n.isFavorite).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      favorites = favorites
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFE8E8ED),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Favorites',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${favorites.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E22) : const Color(0xFFE8E8ED),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search favorites...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: subtleColor),
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: subtleColor, size: 18),
                            onPressed: () => setState(() {
                              _search = '';
                              _searchController.clear();
                            }),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: false,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: favorites.isEmpty
                  ? _buildEmpty(isDark, subtleColor)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: favorites.length,
                      itemBuilder: (_, i) => NoteCard(
                        note: favorites[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteDetailScreen(noteId: favorites[i].id),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color subtleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded,
              size: 56,
              color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text('No favorites yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: subtleColor)),
          const SizedBox(height: 4),
          Text('Star notes to save them here',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: subtleColor)),
        ],
      ),
    );
  }
}

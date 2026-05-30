import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../screens/note_detail_screen.dart';
import '../widgets/note_card.dart';

class PinnedNotesScreen extends ConsumerStatefulWidget {
  const PinnedNotesScreen({super.key});

  @override
  ConsumerState<PinnedNotesScreen> createState() => _PinnedNotesScreenState();
}

class _PinnedNotesScreenState extends ConsumerState<PinnedNotesScreen> {
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
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    final allNotes = ref.watch(notesProvider);
    List<Note> pinned = allNotes.where((n) => n.isPinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      pinned = pinned
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Pinned Notes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pinned.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
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
                  controller: _searchController,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search pinned notes...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: subtleColor),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: primaryColor, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: subtleColor, size: 18),
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

            Divider(
                color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
                height: 1),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: pinned.isEmpty
                  ? _buildEmpty(isDark, subtleColor)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: pinned.length,
                      itemBuilder: (_, i) => NoteCard(
                        note: pinned[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  NoteDetailScreen(noteId: pinned[i].id)),
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
          Icon(Icons.push_pin_outlined,
              size: 56,
              color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text('No pinned notes',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: subtleColor)),
          const SizedBox(height: 4),
          Text('Pin notes to access them quickly',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: subtleColor)),
        ],
      ),
    );
  }
}

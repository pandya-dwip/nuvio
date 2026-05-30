import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/theme_provider.dart';
import '../models/note_model.dart';
import '../models/folder_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';
import '../screens/note_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/pinned_notes_screen.dart';
import '../screens/favorites_screen.dart';
import '../themes/app_theme.dart';

// ── Tab indices ──────────────────────────────────────────────────────────────
// 0=Calendar  1=Notes  2=Home(default)  3=Folders  4=Settings(push)
const int _kDefaultTab = 2;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentTab = _kDefaultTab;
  late PageController _pageController;

  // Search
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Folders
  String? _selectedFolderId;

  // Calendar
  late DateTime _calendarMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: _kDefaultTab);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_currentTab == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentTab = index;
      _search = '';
      _searchCtrl.clear();
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // Sorted for Home tab sections
    final sorted = List<Note>.from(allNotes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final pinned = sorted.where((n) => n.isPinned).toList();
    final favorites = sorted.where((n) => n.isFavorite).toList();
    final recent = sorted.toList(); // All notes sorted by recency

    // Folders tab
    final rootFolders =
        folders.where((f) => f.parentId == _selectedFolderId).toList();
    List<Folder> displayFolders = rootFolders;
    List<Note> folderNotes = _selectedFolderId == null
        ? []
        : allNotes.where((n) => n.folderId == _selectedFolderId).toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      if (_currentTab == 1) {
        // Notes tab search
      } else if (_currentTab == 3) {
        displayFolders = rootFolders
            .where((f) => f.name.toLowerCase().contains(q))
            .toList();
        folderNotes = folderNotes
            .where((n) =>
                n.title.toLowerCase().contains(q) ||
                n.content.toLowerCase().contains(q))
            .toList();
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // FAB on Home tab (2) and Folders tab (3)
      floatingActionButton: (_currentTab == 1 || _currentTab == 2 || _currentTab == 3)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  if (_currentTab == 3) {
                    if (_selectedFolderId == null) {
                      _showCreateFolderSheet();
                    } else {
                      final newNote = ref.read(notesProvider.notifier).addNote(
                            title: '',
                            content: '',
                            colorValue: 0xFFFFFFFF,
                            checklist: [],
                            folderId: _selectedFolderId,
                          );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => NoteDetailScreen(noteId: newNote.id)),
                      );
                    }
                  } else {
                    final newNote = ref.read(notesProvider.notifier).addNote(
                          title: '',
                          content: '',
                          colorValue: 0xFFFFFFFF,
                          checklist: [],
                          folderId: null,
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NoteDetailScreen(noteId: newNote.id)),
                    );
                  }
                },
                backgroundColor: primaryColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Tab content ────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  if (_currentTab != index) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentTab = index;
                      _search = '';
                      _searchCtrl.clear();
                    });
                  }
                },
                children: [
                  _buildCalendarTab(allNotes, isDark, primaryColor),
                  _buildNotesTab(allNotes, isDark, primaryColor),
                  _buildHomeTab(isDark, primaryColor, pinned, favorites, recent, allNotes),
                  _buildFoldersTab(isDark, primaryColor, folders, displayFolders, folderNotes, allNotes),
                  SettingsScreen(onBack: () => _switchTab(2)),
                ],
              ),
            ),

            // ── Navigation Bar ─────────────────────────────────────────
            _buildNavBar(context, isDark, primaryColor),
          ],
        ),
      ),
    );
  }



  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED: Standard Tab Header (no back icon)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabHeader(
    String title,
    bool isDark,
    Color primaryColor, {
    String searchHint = 'Search...',
    Widget? trailing,
    VoidCallback? onBack,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 20, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack ?? () => _switchTab(2),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: textColor,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
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
              controller: _searchCtrl,
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: subtleColor),
                prefixIcon:
                    Icon(Icons.search_rounded, color: primaryColor, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: subtleColor, size: 18),
                        onPressed: () => setState(() {
                          _search = '';
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
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
        Divider(
            color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
            height: 1),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 0 – CALENDAR (Full Month View)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCalendarTab(
      List<Note> allNotes, bool isDark, Color primaryColor) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final totalDays = DateTime(year, month + 1, 0).day;
    // Monday-first offset (1=Mon→0, 7=Sun→6)
    final startOffset = (firstDay.weekday - 1) % 7;

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Notes on selected day
    var dayNotes = _selectedDay == null
        ? <Note>[]
        : allNotes.where((n) {
            final d = n.updatedAt;
            return d.year == _selectedDay!.year &&
                d.month == _selectedDay!.month &&
                d.day == _selectedDay!.day;
          }).toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      dayNotes = dayNotes
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q))
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (with back button and search bar)
        _buildTabHeader('Calendar', isDark, primaryColor,
            searchHint: 'Search notes on this day...'),

        // Month nav
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${monthNames[month - 1]} $year',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _calendarMonth =
                    DateTime(year, month - 1)),
                icon: Icon(Icons.chevron_left_rounded, color: subtleColor),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () => setState(() => _calendarMonth =
                    DateTime(year, month + 1)),
                icon: Icon(Icons.chevron_right_rounded, color: subtleColor),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),

        Divider(
            color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
            height: 1),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Day-of-week headers
                  Row(
                    children: dayLabels
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: subtleColor,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Calendar grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.35,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 0,
                    ),
                    itemCount: startOffset + totalDays,
                    itemBuilder: (_, idx) {
                      if (idx < startOffset) return const SizedBox.shrink();
                      final day = idx - startOffset + 1;
                      final date = DateTime(year, month, day);
                      final isToday = date.year == DateTime.now().year &&
                          date.month == DateTime.now().month &&
                          date.day == DateTime.now().day;
                      final isSelected = _selectedDay != null &&
                          date.year == _selectedDay!.year &&
                          date.month == _selectedDay!.month &&
                          date.day == _selectedDay!.day;
                      final hasNotes = allNotes.any((n) =>
                          n.updatedAt.year == year &&
                          n.updatedAt.month == month &&
                          n.updatedAt.day == day);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDay = date),
                        child: AnimatedContainer(
                           duration: const Duration(milliseconds: 180),
                           margin: const EdgeInsets.all(2),
                           decoration: BoxDecoration(
                             color: isSelected
                                 ? primaryColor
                                 : isToday
                                     ? primaryColor.withOpacity(0.12)
                                     : Colors.transparent,
                             borderRadius: BorderRadius.circular(10),
                           ),
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Text(
                                 '$day',
                                 style: GoogleFonts.plusJakartaSans(
                                   fontSize: 13,
                                   fontWeight: isSelected || isToday
                                       ? FontWeight.w700
                                       : FontWeight.w500,
                                   color: isSelected
                                       ? Colors.white
                                       : isToday
                                           ? primaryColor
                                           : textColor,
                                 ),
                               ),
                               if (hasNotes)
                                 Container(
                                   width: 4,
                                   height: 4,
                                   margin: const EdgeInsets.only(top: 2),
                                   decoration: BoxDecoration(
                                     color: isSelected
                                         ? Colors.white.withOpacity(0.8)
                                         : primaryColor,
                                     shape: BoxShape.circle,
                                   ),
                                 ),
                             ],
                           ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  Divider(
                      color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
                      height: 1),
                  const SizedBox(height: 16),

                  // Notes for selected day
                  if (_selectedDay != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dayNotes.isEmpty
                            ? 'No notes on ${_shortDate(_selectedDay!)}'
                            : '${dayNotes.length} note${dayNotes.length == 1 ? '' : 's'} on ${_shortDate(_selectedDay!)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: subtleColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  ...dayNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildNoteListRow(note, isDark, primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 – NOTES (All Notes)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNotesTab(
      List<Note> allNotes, bool isDark, Color primaryColor) {
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);
    List<Note> notes = List.from(allNotes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      notes = notes
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q) ||
              n.checklist.any((c) => c.text.toLowerCase().contains(q)))
          .toList();
    }

    return Column(
      children: [
        _buildTabHeader('Notes', isDark, primaryColor,
            searchHint: 'Search all notes...'),
        Expanded(
          child: notes.isEmpty
              ? _buildNoResults(isDark, subtleColor)
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (_, i) => NoteCard(
                    note: notes[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              NoteDetailScreen(noteId: notes[i].id)),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 – HOME (Sections + FAB)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeTab(
    bool isDark,
    Color primaryColor,
    List<Note> pinned,
    List<Note> favorites,
    List<Note> recent,
    List<Note> allNotes,
  ) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    if (allNotes.isEmpty) return const EmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Home header (special — has title + dark mode toggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuvio',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Your notes, beautifully organized.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dark mode toggle
                GestureDetector(
                  onTap: () =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1E22)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isDarkMode
                            ? Icons.wb_sunny_rounded
                            : Icons.nightlight_round,
                        key: ValueKey(isDarkMode),
                        color: isDarkMode
                            ? const Color(0xFFFACC15)
                            : const Color(0xFF6B7280),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
              color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
              height: 1),
          const SizedBox(height: 8),

          // ── Pinned section ────────────────────────────────────────────
          if (pinned.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Pinned',
              count: pinned.length,
              isDark: isDark,
              primaryColor: primaryColor,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PinnedNotesScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _buildHorizontalNoteCards(pinned),
            const SizedBox(height: 20),
          ],

          // ── Favorites section ─────────────────────────────────────────
          if (favorites.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Favorites',
              count: favorites.length,
              isDark: isDark,
              primaryColor: primaryColor,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FavoritesScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _buildHorizontalNoteCards(favorites),
            const SizedBox(height: 20),
          ],

          // ── Recent section ────────────────────────────────────────────
          if (recent.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Recent',
              count: recent.length,
              isDark: isDark,
              primaryColor: primaryColor,
              onViewAll: () => _switchTab(1), // → Notes tab
            ),
            const SizedBox(height: 10),
            _buildHorizontalNoteCards(recent),
          ],
        ],
      ),
    );
  }

  // ── Redesigned Section Header ─────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required int count,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onViewAll,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    return GestureDetector(
      onTap: onViewAll,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // Accent bar
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Redesigned Horizontal Note Cards ─────────────────────────────────────
  Widget _buildHorizontalNoteCards(List<Note> notes) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: notes.length,
        itemBuilder: (_, i) {
          final note = notes[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 172,
              child: NoteCard(
                note: note,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NoteDetailScreen(noteId: note.id)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 – FOLDERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFoldersTab(
    bool isDark,
    Color primaryColor,
    List<Folder> allFolders,
    List<Folder> displayFolders,
    List<Note> folderNotes,
    List<Note> allNotes,
  ) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    String title = 'Folders';
    VoidCallback onBack = () => _switchTab(2);

    if (_selectedFolderId != null) {
      final folder = allFolders.firstWhere(
        (f) => f.id == _selectedFolderId,
        orElse: () =>
            Folder(id: '', name: '', createdAt: DateTime.now(), colorValue: 0),
      );
      title = folder.name;
      onBack = () => setState(() {
        _selectedFolderId = folder.parentId;
        _search = '';
        _searchCtrl.clear();
      });
    }

    return Column(
      children: [
        _buildTabHeader(
          title,
          isDark,
          primaryColor,
          searchHint: _selectedFolderId == null
              ? 'Search folders...'
              : 'Search notes...',
          onBack: onBack,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                const SizedBox(height: 8),
                if (displayFolders.isEmpty && _selectedFolderId == null)
                  _buildNoFolders(isDark, subtleColor)
                else ...[
                  ...displayFolders.map((folder) {
                    final noteCount =
                        allNotes.where((n) => n.folderId == folder.id).length;
                    return _buildFolderRow(
                        folder, noteCount, isDark, primaryColor);
                  }),
                  if (folderNotes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            'Notes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${folderNotes.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: subtleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...folderNotes.map((n) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          child: _buildNoteListRow(n, isDark, primaryColor),
                        )),
                  ],
                  if (_selectedFolderId != null &&
                      displayFolders.isEmpty &&
                      folderNotes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Text('This folder is empty',
                            style: GoogleFonts.plusJakartaSans(
                                color: subtleColor)),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildFolderRow(
      Folder folder, int noteCount, bool isDark, Color primaryColor) {
    final folderColor = Color(folder.colorValue);
    final isLight = folderColor.computeLuminance() > 0.7 ||
        folder.colorValue == 0xFFFFFFFF ||
        folder.colorValue == 0xFFFFFFF0;
    final folderIconColor = isLight ? Colors.grey.shade600 : folderColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFolderId = folder.id),
        onLongPress: () => _showFolderOptionsSheet(folder),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E22) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: folderColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  folder.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.folder_rounded,
                  color: folderIconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$noteCount note${noteCount == 1 ? '' : 's'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: folderColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color:
                      isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED: Note List Row (calendar / folder)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNoteListRow(Note note, bool isDark, Color primaryColor) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => NoteDetailScreen(noteId: note.id)),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E22) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color(note.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note.content.isNotEmpty)
                    Text(
                      note.content,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: subtleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color:
                    isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EMPTY STATES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNoResults(bool isDark, Color subtleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56,
              color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text('No results found',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: subtleColor)),
        ],
      ),
    );
  }

  Widget _buildNoFolders(bool isDark, Color subtleColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded,
              size: 56,
              color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text('No folders yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: subtleColor)),
          const SizedBox(height: 4),
          Text('Tap + to create your first folder',
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 13, color: subtleColor)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  NAVIGATION BAR (5 items: Calendar, Notes, Home, Folders, Settings)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNavBar(BuildContext context, bool isDark, Color primaryColor) {
    final items = [
      _NavItem(0, Icons.calendar_month_outlined, Icons.calendar_month_rounded,
          'Calendar'),
      _NavItem(1, Icons.description_outlined, Icons.description_rounded,
          'Notes'),
      _NavItem(2, Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(
          3, Icons.folder_open_outlined, Icons.folder_rounded, 'Folders'),
      _NavItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
    ];

    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15171A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final isActive = _currentTab == item.index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(item.index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive
                          ? primaryColor
                          : (isDark
                              ? Colors.white38
                              : const Color(0xFFB0B8C1)),
                      size: isActive ? 24 : 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isActive
                          ? primaryColor
                          : (isDark
                              ? Colors.white38
                              : const Color(0xFFB0B8C1)),
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FOLDER ACTIONS (long-press)
  // ═══════════════════════════════════════════════════════════════════════════
  void _showFolderOptionsSheet(Folder folder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF15171A) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text(folder.name,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
              const SizedBox(height: 16),
              _sheetOption(
                icon: folder.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                label: folder.isPinned ? 'Unpin' : 'Pin',
                color: isDark ? Colors.white : const Color(0xFF374151),
                isDark: isDark,
                onTap: () {
                  ref.read(foldersProvider.notifier).togglePin(folder.id);
                  Navigator.pop(context);
                },
              ),
              _sheetOption(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: isDark ? Colors.white : const Color(0xFF374151),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showEditFolderSheet(folder);
                },
              ),
              _sheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: Colors.redAccent,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteFolderSheet(folder);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
      onTap: onTap,
    );
  }

  // ── Create Folder ──────────────────────────────────────────────────────────
  void _showCreateFolderSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        int selectedColor = 0xFF2563EB;
        final colors = AppTheme.presetColors.values.toList();
        return StatefulBuilder(builder: (ctx, setS) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF15171A) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Text('New Folder',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'Folder name...',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1C1E22)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length,
                      itemBuilder: (_, i) {
                        final cv = colors[i];
                        final isSel = cv == selectedColor;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setS(() => selectedColor = cv),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: isSel ? 44 : 36,
                              height: isSel ? 44 : 36,
                              decoration: BoxDecoration(
                                color: Color(cv),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSel
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : Colors.black12,
                                    width: isSel ? 2.5 : 1),
                              ),
                              child: isSel
                                  ? Icon(Icons.check_rounded,
                                      color:
                                          Color(cv).computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                      size: 16)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel',
                            style: GoogleFonts.plusJakartaSans(
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isNotEmpty) {
                            // Create folder BUT do NOT navigate into it
                            ref.read(foldersProvider.notifier).addFolder(
                                name, selectedColor,
                                parentId: _selectedFolderId);
                            Navigator.pop(ctx);
                            // Stay on folders tab — no setState for selectedFolderId
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Create',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showEditFolderSheet(Folder folder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final nameCtrl = TextEditingController(text: folder.name);
        int selectedColor = folder.colorValue;
        final colors = AppTheme.presetColors.values.toList();
        return StatefulBuilder(builder: (ctx, setS) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF15171A) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Text('Edit Folder',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'Folder name...',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1C1E22)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length,
                      itemBuilder: (_, i) {
                        final cv = colors[i];
                        final isSel = cv == selectedColor;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setS(() => selectedColor = cv),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: isSel ? 44 : 36,
                              height: isSel ? 44 : 36,
                              decoration: BoxDecoration(
                                color: Color(cv),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSel
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : Colors.black12,
                                    width: isSel ? 2.5 : 1),
                              ),
                              child: isSel
                                  ? Icon(Icons.check_rounded,
                                      color:
                                          Color(cv).computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                      size: 16)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel',
                            style: GoogleFonts.plusJakartaSans(
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isNotEmpty) {
                            ref
                                .read(foldersProvider.notifier)
                                .updateFolder(folder.id, name, selectedColor);
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Save',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showDeleteFolderSheet(Folder folder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF15171A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color:
                          isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Delete "${folder.name}"?',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Notes inside will be unlinked but not deleted.',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFF9CA3AF)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.white12 : const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.plusJakartaSans(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF374151),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(foldersProvider.notifier)
                          .deleteFolder(folder.id);
                      ref
                          .read(notesProvider.notifier)
                          .removeFolderLink(folder.id);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Delete',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav item data ────────────────────────────────────────────────────────────
class _NavItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.index, this.icon, this.activeIcon, this.label);
}

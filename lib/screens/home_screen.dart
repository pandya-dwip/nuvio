import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../models/note_model.dart';
import '../models/folder_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';
import '../screens/note_detail_screen.dart';
import '../themes/app_theme.dart';
import '../providers/theme_provider.dart';

// ─── Tab indices ───────────────────────────────────────────────────────────────
// 0 = Calendar  1 = Todo  2 = Home(notes)  3 = Folders  4 = Settings
const int _kHomeTab = 2;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  String? selectedFolderId;
  String searchQuery = '';
  int _currentTab = _kHomeTab; // Default: Home (notes)
  final TextEditingController _searchController = TextEditingController();

  // Animation controller for nav-bar
  late AnimationController _navBubbleController;

  // Weekly calendar state
  late DateTime _calendarWeekStart;
  DateTime? _selectedCalendarDay;

  @override
  void initState() {
    super.initState();
    _navBubbleController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Start week from last Monday
    final now = DateTime.now();
    final diff = now.weekday - 1; // Monday = 1
    _calendarWeekStart = now.subtract(Duration(days: diff));
    _selectedCalendarDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _navBubbleController.dispose();
    super.dispose();
  }

  void _switchTab(int newTab) {
    if (newTab == _currentTab) return;
    setState(() => _currentTab = newTab);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // Filter notes based on current tab and search
    List<Note> filteredNotes = allNotes;
    if (_currentTab == 3 && selectedFolderId != null) {
      filteredNotes =
          filteredNotes.where((n) => n.folderId == selectedFolderId).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filteredNotes = filteredNotes.where((note) {
        return note.title.toLowerCase().contains(q) ||
            note.content.toLowerCase().contains(q) ||
            note.checklist.any((item) => item.text.toLowerCase().contains(q));
      }).toList();
    }

    final filteredFolders =
        folders.where((f) => f.parentId == selectedFolderId).toList();
    List<Folder> displayFolders = filteredFolders;
    if (searchQuery.isNotEmpty && _currentTab == 3) {
      final q = searchQuery.toLowerCase();
      displayFolders =
          filteredFolders.where((f) => f.name.toLowerCase().contains(q)).toList();
    }

    final sortedNotes = List<Note>.from(filteredNotes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final pinnedNotes = sortedNotes.where((n) => n.isPinned).toList();
    final favoriteNotes = sortedNotes.where((n) => n.isFavorite).toList();
    final recentNotes = sortedNotes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header (Search + dark-mode toggle) ──────────────────────
            _buildHeader(context, isDark, primaryColor),

            // ── Main Content ─────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_currentTab),
                  child: _buildTabContent(
                    allNotes: allNotes,
                    folders: folders,
                    displayFolders: displayFolders,
                    pinnedNotes: pinnedNotes,
                    favoriteNotes: favoriteNotes,
                    recentNotes: recentNotes,
                    filteredNotes: filteredNotes,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Custom Floating Navigation Bar ────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildCustomNavBar(context, isDark, primaryColor,
          allNotes: allNotes),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(
      BuildContext context, bool isDark, Color primaryColor) {
    final themeModeVal = ref.watch(themeProvider);
    final isCurrentlyDark = themeModeVal == ThemeMode.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFFB0A99F);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1E22) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: subtleColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              color: subtleColor, size: 18),
                          onPressed: () => setState(() {
                            searchQuery = '';
                            _searchController.clear();
                          }),
                        )
                      : null,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15),
                  filled: false,
                ),
                onChanged: (v) => setState(() => searchQuery = v),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Dark-mode toggle button
          GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1E22) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isCurrentlyDark
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
                  key: ValueKey(isCurrentlyDark),
                  color: isCurrentlyDark
                      ? const Color(0xFFFACC15)
                      : const Color(0xFF6B7280),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _searchHint {
    switch (_currentTab) {
      case 0:
        return 'Search by date...';
      case 1:
        return 'Search tasks...';
      case 3:
        return 'Search folders...';
      default:
        return 'Search notes...';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB CONTENT ROUTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabContent({
    required List<Note> allNotes,
    required List<Folder> folders,
    required List<Folder> displayFolders,
    required List<Note> pinnedNotes,
    required List<Note> favoriteNotes,
    required List<Note> recentNotes,
    required List<Note> filteredNotes,
  }) {
    switch (_currentTab) {
      case 0:
        return _buildCalendarTab(allNotes);
      case 1:
        return _buildTodoTab(allNotes);
      case 2:
        return _buildHomeTab(
          allNotes: allNotes,
          pinnedNotes: pinnedNotes,
          favoriteNotes: favoriteNotes,
          recentNotes: recentNotes,
          filteredNotes: filteredNotes,
        );
      case 3:
        return _buildFoldersTab(
          folders: folders,
          displayFolders: displayFolders,
          allNotes: allNotes,
          filteredNotes: filteredNotes,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 0 – CALENDAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCalendarTab(List<Note> allNotes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor =
        isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor =
        isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    // Build 7-day week strip
    final weekDays = List.generate(
        7, (i) => _calendarWeekStart.add(Duration(days: i)));

    // Notes on selected day
    final selectedDay = _selectedCalendarDay;
    final dayNotes = selectedDay == null
        ? <Note>[]
        : allNotes.where((n) {
            final d = n.updatedAt;
            return d.year == selectedDay.year &&
                d.month == selectedDay.month &&
                d.day == selectedDay.day;
          }).toList();

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month label + arrows
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${months[_calendarWeekStart.month - 1]} ${_calendarWeekStart.year}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _calendarWeekStart =
                        _calendarWeekStart.subtract(const Duration(days: 7));
                  }),
                  icon: Icon(Icons.chevron_left_rounded,
                      color: subtleColor),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _calendarWeekStart =
                        _calendarWeekStart.add(const Duration(days: 7));
                  }),
                  icon: Icon(Icons.chevron_right_rounded,
                      color: subtleColor),
                ),
              ],
            ),
          ),

          // Week strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(7, (i) {
                final day = weekDays[i];
                final dateOnly =
                    DateTime(day.year, day.month, day.day);
                final isSelected = _selectedCalendarDay != null &&
                    dateOnly == _selectedCalendarDay;
                final notesOnDay = allNotes
                    .where((n) =>
                        n.updatedAt.year == day.year &&
                        n.updatedAt.month == day.month &&
                        n.updatedAt.day == day.day)
                    .length;
                final isToday = day.year == DateTime.now().year &&
                    day.month == DateTime.now().month &&
                    day.day == DateTime.now().day;

                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCalendarDay = dateOnly),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : isDark
                                ? const Color(0xFF1C1E22)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayLabels[i],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : subtleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.day}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? primaryColor
                                      : textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (notesOnDay > 0)
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : primaryColor,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Notes on selected day
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              selectedDay == null
                  ? 'Select a day'
                  : dayNotes.isEmpty
                      ? 'No notes on this day'
                      : '${dayNotes.length} note${dayNotes.length == 1 ? '' : 's'} on ${_shortDate(selectedDay)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: subtleColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...dayNotes.map((note) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: _buildFullWidthNoteRow(note, isDark, primaryColor),
              )),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Widget _buildFullWidthNoteRow(
      Note note, bool isDark, Color primaryColor) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteDetailScreen(noteId: note.id),
        ),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E22) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                border: Border.all(
                    color: Colors.black12, width: 0.5),
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
                      color:
                          isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note.content.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF9CA3AF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? Colors.white24
                    : const Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 – TODO (aggregated checklists across all notes)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTodoTab(List<Note> allNotes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor =
        isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor =
        isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    // Collect all task blocks from all notes
    final List<_TodoEntry> todos = [];
    for (final note in allNotes) {
      for (final block in note.safeBlocks) {
        if (block.type == BlockType.task) {
          if (block.text.isEmpty) continue;
          // Filter by search
          if (searchQuery.isNotEmpty &&
              !block.text.toLowerCase().contains(searchQuery.toLowerCase())) {
            continue;
          }
          todos.add(_TodoEntry(
            noteId: note.id,
            noteTitle: note.title.isEmpty ? 'Untitled' : note.title,
            noteColor: note.colorValue,
            blockId: block.id,
            text: block.text,
            isChecked: block.isChecked,
          ));
        }
      }
    }

    final pending = todos.where((t) => !t.isChecked).toList();
    final done = todos.where((t) => t.isChecked).toList();

    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 56,
                color: isDark
                    ? Colors.white24
                    : const Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: subtleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add checklist items in your notes',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: subtleColor),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('Pending', pending.length),
            ...pending.map((t) =>
                _buildTodoRow(t, isDark, primaryColor, textColor, subtleColor)),
            const SizedBox(height: 8),
          ],
          if (done.isNotEmpty) ...[
            _buildSectionHeader('Completed', done.length),
            ...done.map((t) =>
                _buildTodoRow(t, isDark, primaryColor, textColor, subtleColor)),
          ],
        ],
      ),
    );
  }

  Widget _buildTodoRow(_TodoEntry entry, bool isDark, Color primaryColor,
      Color textColor, Color subtleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => NoteDetailScreen(noteId: entry.noteId)),
        ),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E22) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: entry.isChecked
                      ? primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: entry.isChecked
                        ? primaryColor
                        : (isDark ? Colors.white30 : const Color(0xFFD1D5DB)),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: entry.isChecked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: entry.isChecked
                            ? subtleColor
                            : textColor,
                        decoration: entry.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: subtleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Color(entry.noteColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.noteTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: subtleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? Colors.white24
                      : const Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 – HOME (Notes)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeTab({
    required List<Note> allNotes,
    required List<Note> pinnedNotes,
    required List<Note> favoriteNotes,
    required List<Note> recentNotes,
    required List<Note> filteredNotes,
  }) {
    if (allNotes.isEmpty) return const EmptyState();
    if (filteredNotes.isEmpty && searchQuery.isNotEmpty) {
      return _buildNoResultsState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinnedNotes.isNotEmpty) ...[
            _buildSectionHeader('Pinned', pinnedNotes.length),
            const SizedBox(height: 4),
            _buildNotesHorizontalList(pinnedNotes),
            const SizedBox(height: 16),
          ],
          if (favoriteNotes.isNotEmpty) ...[
            _buildSectionHeader('Favorites', favoriteNotes.length),
            const SizedBox(height: 4),
            _buildNotesHorizontalList(favoriteNotes),
            const SizedBox(height: 16),
          ],
          if (recentNotes.isNotEmpty) ...[
            _buildSectionHeader('Recent', recentNotes.length),
            const SizedBox(height: 4),
            _buildNotesHorizontalList(recentNotes),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 – FOLDERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFoldersTab({
    required List<Folder> folders,
    required List<Folder> displayFolders,
    required List<Note> allNotes,
    required List<Note> filteredNotes,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedFolderId != null)
          _buildFolderBreadcrumb(folders, isDark),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayFolders.isNotEmpty) ...[
                  _buildSectionHeader(
                      selectedFolderId == null ? 'Folders' : 'Subfolders',
                      displayFolders.length),
                  const SizedBox(height: 8),
                  ...displayFolders.map((folder) {
                    final noteCount =
                        allNotes.where((n) => n.folderId == folder.id).length;
                    return _buildFolderRow(folder, noteCount, isDark);
                  }),
                  const SizedBox(height: 16),
                ],

                if (selectedFolderId != null &&
                    filteredNotes.isNotEmpty) ...[
                  _buildSectionHeader('Notes', filteredNotes.length),
                  const SizedBox(height: 8),
                  ...filteredNotes.map((note) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        child: _buildFullWidthNoteRow(
                            note,
                            isDark,
                            Theme.of(context).primaryColor),
                      )),
                ],

                if (selectedFolderId != null &&
                    filteredNotes.isEmpty &&
                    displayFolders.isEmpty)
                  _buildEmptyFolder(isDark),

                if (selectedFolderId == null && displayFolders.isEmpty)
                  _buildNoFoldersYet(isDark),

                if (searchQuery.isNotEmpty &&
                    displayFolders.isEmpty &&
                    (selectedFolderId == null || filteredNotes.isEmpty))
                  _buildNoResultsState(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Full-width Folder Row with long-press options ───────────────────────
  Widget _buildFolderRow(Folder folder, int noteCount, bool isDark) {
    final folderColor = Color(folder.colorValue);
    final isLight = folderColor.computeLuminance() > 0.7 ||
        folder.colorValue == 0xFFFFFFFF ||
        folder.colorValue == 0xFFFFFFF0;
    final folderIconColor = isLight ? Colors.grey.shade600 : folderColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () => setState(() => selectedFolderId = folder.id),
        onLongPress: () =>
            _showFolderOptionsSheet(context, ref, folder),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E22) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Folder icon in folder color
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: folderColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  folder.isPinned
                      ? Icons.push_pin
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
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
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
              // Color dot accent
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: folderColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? Colors.white24
                      : const Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderBreadcrumb(List<Folder> folders, bool isDark) {
    final currentFolder = folders.firstWhere(
      (f) => f.id == selectedFolderId,
      orElse: () =>
          Folder(id: '', name: 'Folder', createdAt: DateTime.now(), colorValue: 0),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () =>
                setState(() => selectedFolderId = currentFolder.parentId),
          ),
          Expanded(
            child: Text(
              currentFolder.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFolder(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Text(
          'No contents in this folder',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Widget _buildNoFoldersYet(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded,
                size: 56,
                color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No folders yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the + button to create one',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.white24 : const Color(0xFFB0B8C1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesHorizontalList(List<Note> notes) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: notes.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (_, i) {
          final note = notes[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 176,
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

  Widget _buildNoResultsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56,
              color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CUSTOM 5-TAB FLOATING NAVIGATION BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCustomNavBar(
    BuildContext context,
    bool isDark,
    Color primaryColor, {
    required List<Note> allNotes,
  }) {
    return Container(
      height: 84 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15171A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Calendar ──────────────────────────────────────────────────
          _buildNavItem(
            index: 0,
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today_rounded,
            label: 'Calendar',
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          // ── Todo ──────────────────────────────────────────────────────
          _buildNavItem(
            index: 1,
            icon: Icons.checklist_outlined,
            activeIcon: Icons.checklist_rounded,
            label: 'Todo',
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          // ── CENTER CREATE BUTTON ───────────────────────────────────────
          _buildCenterCreateButton(
              context, isDark, primaryColor, allNotes),
          // ── Folders ───────────────────────────────────────────────────
          _buildNavItem(
            index: 3,
            icon: Icons.folder_open_outlined,
            activeIcon: Icons.folder_rounded,
            label: 'Folders',
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          // ── Settings ─────────────────────────────────────────────────
          _buildNavSettingsItem(isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
    required Color primaryColor,
  }) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isActive ? 44 : 40,
              height: isActive ? 44 : 40,
              decoration: BoxDecoration(
                color: isActive
                    ? primaryColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? primaryColor
                    : (isDark ? Colors.white38 : const Color(0xFFB0B8C1)),
                size: isActive ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? primaryColor
                    : (isDark ? Colors.white38 : const Color(0xFFB0B8C1)),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavSettingsItem(bool isDark, Color primaryColor) {
    return GestureDetector(
      onTap: () => _showSettingsBottomSheet(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: isDark ? Colors.white38 : const Color(0xFFB0B8C1),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Settings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : const Color(0xFFB0B8C1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterCreateButton(BuildContext context, bool isDark,
      Color primaryColor, List<Note> allNotes) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (_currentTab == 3) {
          _showCreateFolderBottomSheet(context, ref);
        } else {
          // Create note and navigate
          final newNote = ref.read(notesProvider.notifier).addNote(
                title: '',
                content: '',
                colorValue: 0xFFFFFFFF,
                checklist: [],
                folderId: (_currentTab == 3) ? selectedFolderId : null,
              );
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => NoteDetailScreen(noteId: newNote.id)),
          );
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FOLDER LONG-PRESS OPTIONS SHEET (Pin / Edit / Delete)
  // ═══════════════════════════════════════════════════════════════════════════
  void _showFolderOptionsSheet(
      BuildContext context, WidgetRef ref, Folder folder) {
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
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                folder.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),

              // Pin
              _buildSheetOption(
                icon: folder.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                label:
                    folder.isPinned ? 'Unpin Folder' : 'Pin Folder',
                color: isDark ? Colors.white : const Color(0xFF374151),
                isDark: isDark,
                onTap: () {
                  ref
                      .read(foldersProvider.notifier)
                      .togglePin(folder.id);
                  Navigator.pop(context);
                },
              ),

              // Edit
              _buildSheetOption(
                icon: Icons.edit_outlined,
                label: 'Edit Folder',
                color: isDark ? Colors.white : const Color(0xFF374151),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showEditFolderBottomSheet(context, ref, folder);
                },
              ),

              // Delete
              _buildSheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Folder',
                color: Colors.redAccent,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteFolderBottomSheet(context, ref, folder);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
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
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
      onTap: onTap,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SETTINGS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final themeModeVal = ref.watch(themeProvider);
        final customColor = ref.watch(customThemeColorProvider);
        final isDark = themeModeVal == ThemeMode.dark;

        final availableThemeColors = [
          Colors.black,
          const Color(0xFF7C3AED),
          const Color(0xFF059669),
          const Color(0xFF2563EB),
          const Color(0xFFDC2626),
          const Color(0xFFD97706),
        ];

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
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
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Settings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFFFACC15)
                                  : const Color(0xFF6B7280))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          color: isDark
                              ? const Color(0xFFFACC15)
                              : const Color(0xFF6B7280),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        isDark ? 'Light Mode' : 'Dark Mode',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A1A)),
                      ),
                      subtitle: Text(
                        isDark ? 'Switch to light theme' : 'Switch to dark theme',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF9CA3AF)),
                      ),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) {
                          ref.read(themeProvider.notifier).toggleTheme();
                          setSheetState(() {});
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Accent Color',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: availableThemeColors.map((color) {
                        final displayColor =
                            (color.value == Colors.black.value && isDark)
                                ? Colors.white
                                : color;
                        final isSelected =
                            customColor.value == color.value;
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(customThemeColorProvider.notifier)
                                .updateColor(color);
                            setSheetState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 44 : 38,
                            height: isSelected ? 44 : 38,
                            decoration: BoxDecoration(
                              color: displayColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            displayColor.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? Icon(Icons.check_rounded,
                                    color: displayColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                    size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    const Divider(color: Color(0xFFE5E7EB), height: 1),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Nuvio v1.0.0',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFD1D5DB)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CREATE FOLDER BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showCreateFolderBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final nameController = TextEditingController();
        int selectedColorVal = 0xFF2563EB;
        final folderColors = AppTheme.presetColors.values.toList();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'New Folder',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Folder Name',
                      hintText: 'e.g. Work, Ideas',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1C1E22)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Color',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: folderColors.length,
                      itemBuilder: (_, idx) {
                        final cv = folderColors[idx];
                        final isSel = cv == selectedColorVal;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedColorVal = cv),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSel ? 44 : 38,
                              height: isSel ? 44 : 38,
                              decoration: BoxDecoration(
                                color: Color(cv),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.black12,
                                  width: isSel ? 2.5 : 1.0,
                                ),
                              ),
                              child: isSel
                                  ? Icon(Icons.check_rounded,
                                      color: Color(cv).computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                      size: 18)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            if (name.isNotEmpty) {
                              final newFolder = ref
                                  .read(foldersProvider.notifier)
                                  .addFolder(name, selectedColorVal,
                                      parentId: selectedFolderId);
                              Navigator.pop(context);
                              if (_currentTab == 3) {
                                setState(
                                    () => selectedFolderId = newFolder.id);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Create',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EDIT FOLDER BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showEditFolderBottomSheet(
      BuildContext context, WidgetRef ref, Folder folder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final nameController = TextEditingController(text: folder.name);
        int selectedColorVal = folder.colorValue;
        final folderColors = AppTheme.presetColors.values.toList();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Folder',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Folder Name',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1C1E22)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: folderColors.length,
                      itemBuilder: (_, idx) {
                        final cv = folderColors[idx];
                        final isSel = cv == selectedColorVal;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedColorVal = cv),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSel ? 44 : 38,
                              height: isSel ? 44 : 38,
                              decoration: BoxDecoration(
                                color: Color(cv),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.black12,
                                  width: isSel ? 2.5 : 1.0,
                                ),
                              ),
                              child: isSel
                                  ? Icon(Icons.check_rounded,
                                      color: Color(cv).computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                      size: 18)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            if (name.isNotEmpty) {
                              ref
                                  .read(foldersProvider.notifier)
                                  .updateFolder(
                                      folder.id, name, selectedColorVal);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Save',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DELETE FOLDER BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showDeleteFolderBottomSheet(
      BuildContext context, WidgetRef ref, Folder folder) {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete "${folder.name}"?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Notes inside will be unlinked but not deleted.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          backgroundColor: isDark
                              ? Colors.white12
                              : const Color(0xFFF3F4F6),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF374151),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Data model for aggregated to-dos ─────────────────────────────────────────
class _TodoEntry {
  final String noteId;
  final String noteTitle;
  final int noteColor;
  final String blockId;
  final String text;
  final bool isChecked;

  const _TodoEntry({
    required this.noteId,
    required this.noteTitle,
    required this.noteColor,
    required this.blockId,
    required this.text,
    required this.isChecked,
  });
}

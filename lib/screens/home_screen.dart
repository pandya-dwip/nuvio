import 'dart:ui';
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

  // Calendar selected day
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
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

  // --- Dynamic Category Icons for Mockup Replicas ---
  IconData _getNoteIcon(Note note) {
    if (note.checklist.isNotEmpty) {
      return Icons.check_box_outlined;
    }
    if (note.blocks.any((b) => b.type == BlockType.quote)) {
      return Icons.format_quote_outlined;
    }
    final titleLower = note.title.toLowerCase();
    if (titleLower.contains('groceries') || titleLower.contains('shop') || titleLower.contains('cart')) {
      return Icons.shopping_cart_outlined;
    }
    if (titleLower.contains('idea') || titleLower.contains('inspiration') || titleLower.contains('light')) {
      return Icons.lightbulb_outline;
    }
    if (titleLower.contains('read') || titleLower.contains('book') || titleLower.contains('list')) {
      return Icons.menu_book_outlined;
    }
    if (titleLower.contains('design') || titleLower.contains('art') || titleLower.contains('palette')) {
      return Icons.palette_outlined;
    }
    return Icons.description_outlined;
  }

  // --- Helper to get name of week day ---
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'MON';
      case 2: return 'TUE';
      case 3: return 'WED';
      case 4: return 'THU';
      case 5: return 'FRI';
      case 6: return 'SAT';
      case 7: return 'SUN';
      default: return '';
    }
  }

  // --- Time Formatter Helper ---
  String _formatTimeEdited(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Edited just now';
    } else if (difference.inHours < 1) {
      return 'Edited ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Edited ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Edited Yesterday';
    } else {
      return 'Edited ${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Custom brand theme color
    final customColor = ref.watch(customThemeColorProvider);
    final brandColor = (customColor.value == Colors.black.value && isDark)
        ? Colors.white
        : (customColor.value == Colors.white.value ? Colors.black : customColor);

    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // Filter notes by search query
    List<Note> searchedNotes = allNotes;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      searchedNotes = searchedNotes.where((note) {
        return note.title.toLowerCase().contains(q) ||
            note.content.toLowerCase().contains(q) ||
            note.checklist.any((item) => item.text.toLowerCase().contains(q));
      }).toList();
    }

    // Sort notes by updatedAt descending to show recent changes first
    final sortedNotes = List<Note>.from(searchedNotes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final pinned = sortedNotes.where((note) => note.isPinned).toList();
    final favorites = sortedNotes.where((note) => note.isFavorite).toList();
    final recent = sortedNotes.where((note) => !note.isPinned).toList();

    // Folders tab data logic
    final rootFolders = folders.where((f) => f.parentId == _selectedFolderId).toList();
    List<Folder> displayFolders = rootFolders;
    List<Note> folderNotes = _selectedFolderId == null
        ? []
        : allNotes.where((n) => n.folderId == _selectedFolderId).toList();

    if (_search.isNotEmpty && _currentTab == 3) {
      final q = _search.toLowerCase();
      displayFolders = rootFolders.where((f) => f.name.toLowerCase().contains(q)).toList();
      folderNotes = folderNotes.where((n) => n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      backgroundColor: bgColor,
      // FAB on Home tab (2) and Folders tab (3) and Notes tab (1)
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
                backgroundColor: brandColor,
                foregroundColor: (brandColor == Colors.white || brandColor.value == 0xFFFFFFFF) ? Colors.black : Colors.white,
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
                  _buildCalendarTab(sortedNotes, brandColor, isDark),
                  _buildNotesTab(sortedNotes, folders, brandColor, isDark),
                  _buildHomeTab(sortedNotes, folders, brandColor, isDark, pinned, favorites, recent),
                  _buildFoldersTab(isDark, brandColor, folders, displayFolders, folderNotes, allNotes),
                  _buildSettingsTab(brandColor, isDark),
                ],
              ),
            ),

            // ── Navigation Bar ─────────────────────────────────────────
            _buildBottomNavigationBar(context, brandColor),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED: Standard Tab Header (Notes/Folders search bar layout)
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

  // --- Dynamic Mockup Header (Brand title + theme toggle) ---
  Widget _buildHeader(BuildContext context, String title, String subtitle, Color brandColor) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: brandColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF6B665E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Theme Toggle Button
          GestureDetector(
            onTap: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFE8E8ED),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                size: 20,
                color: isDark ? Colors.white70 : const Color(0xFF2C2A29),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable Section Title ---
  Widget _buildSectionTitle(String title, VoidCallback onViewAll, Color brandColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1a1c1f),
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'VIEW ALL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: brandColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 0 – CALENDAR (Week View selector)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCalendarTab(
    List<Note> sortedNotes,
    Color brandColor,
    bool isDark,
  ) {
    // Generate dates of current week (Monday to Sunday)
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final monday = now.subtract(Duration(days: currentWeekday - 1));
    final weekDates = List<DateTime>.generate(7, (i) => monday.add(Duration(days: i)));

    // Filter notes edited on the selected date
    final calendarNotes = sortedNotes.where((note) {
      return note.updatedAt.year == _selectedDay.year &&
          note.updatedAt.month == _selectedDay.month &&
          note.updatedAt.day == _selectedDay.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, 'Calendar', 'View notes chronologically', brandColor),
        
        // Horizontal Day Selector
        Container(
          height: 90,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 7,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              final date = weekDates[index];
              final isSelected = date.year == _selectedDay.year &&
                  date.month == _selectedDay.month &&
                  date.day == _selectedDay.day;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getDayName(date.weekday),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8F887F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = date;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? brandColor
                              : (isDark ? const Color(0xFF1E2124) : Colors.white),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : const Color(0xFFE2E2E7)),
                            width: 1.0,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: brandColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? ((brandColor == Colors.white || brandColor.value == 0xFFFFFFFF) ? Colors.black : Colors.white)
                                  : (isDark ? Colors.white70 : const Color(0xFF1a1c1f)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: calendarNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_note, size: 48, color: Color(0xFF8F887F)),
                      const SizedBox(height: 12),
                      Text(
                        'No notes updated on this day.',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF8F887F),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: calendarNotes.length,
                  itemBuilder: (context, index) {
                    final note = calendarNotes[index];
                    final noteIcon = _getNoteIcon(note);
                    final itemBgColor = isDark ? const Color(0xFF1E2124) : Colors.white;
                    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E2E7);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: itemBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderCol, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteDetailScreen(noteId: note.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: brandColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  noteIcon,
                                  color: brandColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title.isNotEmpty ? note.title : 'Untitled',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1a1c1f),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Last edited ${_formatTimeEdited(note.updatedAt)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF8F887F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Color(0xFF8F887F), size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 – NOTES (All Notes Search & Chips)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNotesTab(
    List<Note> sortedNotes,
    List<Folder> folders,
    Color brandColor,
    bool isDark,
  ) {
    List<Note> filteredNotes = sortedNotes;
    if (_selectedFolderId != null) {
      filteredNotes = filteredNotes.where((note) => note.folderId == _selectedFolderId).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabHeader('Notes', isDark, brandColor, searchHint: 'Search all notes...'),
        
        // Horizontal Folders choice chips
        if (folders.isNotEmpty) ...[
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: folders.length + 1,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isAllSelected = _selectedFolderId == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        'All Notes',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: isAllSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF2C2A29)),
                        ),
                      ),
                      selected: isAllSelected,
                      selectedColor: brandColor,
                      backgroundColor: isDark ? const Color(0xFF1E2124) : const Color(0xFFFAF2E6),
                      onSelected: (_) {
                        setState(() {
                          _selectedFolderId = null;
                        });
                      },
                    ),
                  );
                }
                final folder = folders[index - 1];
                final isSelected = folder.id == _selectedFolderId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.folder_open,
                      size: 16,
                      color: isSelected ? Colors.white : Color(folder.colorValue),
                    ),
                    label: Text(
                      folder.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF2C2A29)),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: brandColor,
                    backgroundColor: isDark ? const Color(0xFF1E2124) : const Color(0xFFFAF2E6),
                    onSelected: (_) {
                      setState(() {
                        _selectedFolderId = folder.id;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        Expanded(
          child: filteredNotes.isEmpty
              ? _buildNoResults(isDark, const Color(0xFF8F887F))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredNotes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.90,
                  ),
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteDetailScreen(noteId: note.id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 – HOME (Premium Mockup UI exact replica)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeTab(
    List<Note> sortedNotes,
    List<Folder> folders,
    Color brandColor,
    bool isDark,
    List<Note> pinnedNotes,
    List<Note> favoriteNotes,
    List<Note> recentNotes,
  ) {
    final isWorkspaceEmpty = sortedNotes.isEmpty && folders.isEmpty;

    if (isWorkspaceEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, 'Nuvio', 'Your notes, Beautifully Organized', brandColor),
          const Expanded(child: EmptyState()),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Header
          _buildHeader(context, 'Nuvio', 'Your notes, Beautifully Organized', brandColor),

          // --- Pinned Section ---
          if (pinnedNotes.isNotEmpty) ...[
            _buildSectionTitle('Pinned', () => _switchTab(1), brandColor),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: pinnedNotes.length,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemBuilder: (context, index) {
                  final note = pinnedNotes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 14.0),
                    child: SizedBox(
                      width: 280,
                      child: NoteCard(
                        note: note,
                        showThickLeftBorder: index == 0,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteDetailScreen(noteId: note.id),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // --- Favorites Section ---
          if (favoriteNotes.isNotEmpty) ...[
            _buildSectionTitle('Favorites', () => _switchTab(1), brandColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: favoriteNotes.take(4).length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final note = favoriteNotes[index];
                  final noteIcon = _getNoteIcon(note);
                  final cardColor = isDark ? const Color(0xFF1E2124) : Colors.white;
                  final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E2E7);

                  return Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: borderCol, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteDetailScreen(noteId: note.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: brandColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    noteIcon,
                                    color: brandColor,
                                    size: 20,
                                  ),
                                ),
                                Icon(
                                  Icons.star,
                                  color: brandColor,
                                  size: 18,
                                ),
                              ],
                            ),
                            Text(
                              note.title.isNotEmpty ? note.title : 'Untitled',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1a1c1f),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // --- Recent Section ---
          if (recentNotes.isNotEmpty) ...[
            _buildSectionTitle('Recent', () => _switchTab(1), brandColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentNotes.take(5).length,
                itemBuilder: (context, index) {
                  final note = recentNotes[index];
                  final noteIcon = _getNoteIcon(note);
                  final itemBgColor = isDark ? const Color(0xFF1E2124) : Colors.white;
                  final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E2E7);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: itemBgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderCol, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteDetailScreen(noteId: note.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: brandColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                noteIcon,
                                color: brandColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title.isNotEmpty ? note.title : 'Untitled',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1a1c1f),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatTimeEdited(note.updatedAt),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF8F887F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF8F887F),
                              size: 20,
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
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 – FOLDERS (Nesting Subfolders & Notes list)
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
  //  TAB 4 – SETTINGS (Theme Config & System Info inline)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSettingsTab(
    Color brandColor,
    bool isDark,
  ) {
    final colors = [
      0xFF0058BC, // Blue
      0xFF000000, // Black
      0xFFEF5350, // Red
      0xFF059669, // Green
      0xFF7C3AED, // Purple
      0xFFFFA726, // Orange
    ];

    final customColor = ref.watch(customThemeColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, 'Settings', 'Personalize your workspace theme', brandColor),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 100.0),
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                'APPEARANCE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8F887F),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Dark Theme Mode',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1a1c1f),
                  ),
                ),
                subtitle: Text(
                  'Enable comfortable viewing at night',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF8F887F),
                  ),
                ),
                value: isDark,
                activeColor: brandColor,
                onChanged: (_) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
              const Divider(height: 32, color: Colors.white10),

              Text(
                'BRAND COLOR THEME',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8F887F),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: colors.map((cVal) {
                  final isSelected = cVal == customColor.value;
                  return InkWell(
                    onTap: () {
                      ref.read(customThemeColorProvider.notifier).updateColor(Color(cVal));
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(cVal),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                              : Colors.white24,
                          width: isSelected ? 3.0 : 1.0,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Color(cVal).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 32, color: Colors.white10),

              Text(
                'ABOUT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8F887F),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: brandColor),
                ),
                title: Text(
                  'Nuvio Notes v1.0.2',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1a1c1f),
                  ),
                ),
                subtitle: Text(
                  'Offline-first Recycled Canvas design.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF8F887F)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EMPTY & GENERAL STATES
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

  Widget _buildNoNotesFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Color(0xFF8F887F)),
          const SizedBox(height: 12),
          Text(
            'No matching notes found.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8F887F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BOTTOM NAVIGATION BAR (Docked glass design)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomNavigationBar(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? const Color(0xFF15171A).withOpacity(0.9) : const Color(0xFFFFFFFF).withOpacity(0.9);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E2E7);
    
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: navBgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.8),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.calendar_today_outlined, 'Calendar', primaryColor),
              _buildNavItem(1, Icons.description_outlined, 'Notes', primaryColor),
              _buildNavItem(2, Icons.home, 'Home', primaryColor, fillIcon: true),
              _buildNavItem(3, Icons.folder_outlined, 'Folders', primaryColor),
              _buildNavItem(4, Icons.settings_outlined, 'Settings', primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color primaryColor, {bool fillIcon = false}) {
    final isSelected = _currentTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color itemColor = isSelected 
        ? primaryColor 
        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B665E));
        
    return Expanded(
      child: InkWell(
        onTap: () => _switchTab(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected && fillIcon ? Icons.home_rounded : icon,
                color: itemColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: itemColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FOLDER ACTIONS (long-press) & MODAL SHEETS
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
                            ref.read(foldersProvider.notifier).addFolder(
                                name, selectedColor,
                                parentId: _selectedFolderId);
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

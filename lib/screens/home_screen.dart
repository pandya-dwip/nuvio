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
import '../screens/accent_color_screen.dart';
import '../screens/splash_screen.dart';
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
  String _settingsSearch = '';
  final TextEditingController _settingsSearchCtrl = TextEditingController();

  // Folders
  String? _selectedFolderId;

  // Calendar selected day
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _kDefaultTab);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _settingsSearchCtrl.dispose();
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
      _settingsSearch = '';
      _settingsSearchCtrl.clear();
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
                      _settingsSearch = '';
                      _settingsSearchCtrl.clear();
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
    bool showBackButton = false,
    VoidCallback? onBack,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF8F887F);

    // Determine the header icon based on the title
    IconData headerIcon = Icons.description_rounded;
    if (title.toLowerCase() == 'folders') {
      headerIcon = Icons.folder_rounded;
    } else if (title.toLowerCase() == 'settings') {
      headerIcon = Icons.settings_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Header with Icon (matching Settings header style)
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
          child: Row(
            children: [
              if (showBackButton) ...[
                GestureDetector(
                  onTap: onBack,
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
              ] else ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    headerIcon,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF333E5A),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),

        // Full-width Search Bar matching Settings / Pinned search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
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
                hintText: searchHint,
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: subtleColor),
                prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: subtleColor, size: 18),
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
                  style: title == 'Nuvio'
                      ? GoogleFonts.greatVibes(
                          fontSize: 38,
                          fontWeight: FontWeight.w400,
                          color: brandColor,
                        ).copyWith(
                          fontFamilyFallback: ['Segoe Script', 'Lucida Handwriting', 'cursive'],
                        )
                      : GoogleFonts.plusJakartaSans(
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
    // Filter notes edited on the selected date
    final calendarNotes = sortedNotes.where((note) {
      return note.updatedAt.year == _selectedDay.year &&
          note.updatedAt.month == _selectedDay.month &&
          note.updatedAt.day == _selectedDay.day;
    }).toList();

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    // We start from Monday
    final leadingSpaces = firstDay.weekday - 1;
    final totalCells = leadingSpaces + daysInMonth;

    // Get a set of days that have notes in the focused month
    final monthNotes = sortedNotes.where((note) => note.updatedAt.year == year && note.updatedAt.month == month).toList();
    final daysWithNotes = monthNotes.map((n) => n.updatedAt.day).toSet();

    const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthYearStr = '${monthNames[month - 1]} $year';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, 'Calendar', 'View notes chronologically', brandColor),
        
        // Month Navigation Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthYearStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1C1F),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(year, month - 1, 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: isDark ? Colors.white70 : const Color(0xFF2C2A29),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(year, month + 1, 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: isDark ? Colors.white70 : const Color(0xFF2C2A29),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Weekdays labels row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              SizedBox(width: 40, child: Text('M', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F887F)), textAlign: TextAlign.center)),
              SizedBox(width: 40, child: Text('T', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F887F)), textAlign: TextAlign.center)),
              SizedBox(width: 40, child: Text('W', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F887F)), textAlign: TextAlign.center)),
              SizedBox(width: 40, child: Text('T', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F887F)), textAlign: TextAlign.center)),
              SizedBox(width: 40, child: Text('F', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F887F)), textAlign: TextAlign.center)),
              SizedBox(width: 40, child: Text('S', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F887F)), textAlign: TextAlign.center)),
              SizedBox(width: 40, child: Text('S', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F887F)), textAlign: TextAlign.center)),
            ],
          ),
        ),

        // Monthly Days Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < leadingSpaces) {
                return const SizedBox();
              }

              final dayNumber = index - leadingSpaces + 1;
              final date = DateTime(year, month, dayNumber);
              final isSelected = date.year == _selectedDay.year &&
                  date.month == _selectedDay.month &&
                  date.day == _selectedDay.day;
              
              final hasNotes = daysWithNotes.contains(dayNumber);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = date;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? brandColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? Colors.transparent 
                          : (date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day 
                              ? brandColor.withOpacity(0.5) 
                              : Colors.transparent),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected || hasNotes ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? ((brandColor == Colors.white || brandColor.value == 0xFFFFFFFF) ? Colors.black : Colors.white)
                              : (isDark ? Colors.white70 : const Color(0xFF1A1C1F)),
                        ),
                      ),
                      if (hasNotes)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? ((brandColor == Colors.white || brandColor.value == 0xFFFFFFFF) ? Colors.black : Colors.white) 
                                : brandColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
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
                  final hasWhiteText = brandColor == Colors.white || brandColor.value == 0xFFFFFFFF;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFolderId = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: isAllSelected
                                ? brandColor
                                : brandColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAllSelected
                                  ? brandColor
                                  : brandColor.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: isAllSelected
                                ? [
                                    BoxShadow(
                                      color: brandColor.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'All Notes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isAllSelected
                                  ? (hasWhiteText ? Colors.black : Colors.white)
                                  : brandColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final folder = folders[index - 1];
                final isSelected = folder.id == _selectedFolderId;
                final folderColor = Color(folder.colorValue);
                final hasWhiteText = brandColor == Colors.white || brandColor.value == 0xFFFFFFFF;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFolderId = folder.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? brandColor
                              : folderColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? brandColor
                                : folderColor.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: brandColor.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 16,
                              color: isSelected
                                  ? (hasWhiteText ? Colors.black : Colors.white)
                                  : folderColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              folder.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (hasWhiteText ? Colors.black : Colors.white)
                                    : folderColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

  String _formatPinnedDate(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final monthStr = months[date.month - 1];
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$monthStr $dayStr, ${date.year}';
  }

  Widget _buildPinnedCard(BuildContext context, Note note, bool isDark, Color brandColor, bool showThickLeftBorder, List<Folder> folders) {
    final folder = note.folderId != null
        ? folders.firstWhere((f) => f.id == note.folderId, orElse: () => Folder(id: '', name: '', createdAt: DateTime.now(), colorValue: 0))
        : null;

    final cardBgColor = isDark ? const Color(0xFF1E2124) : Colors.white;
    final borderCol = isDark ? Colors.white10 : const Color(0xFFC1C6D7).withOpacity(0.20);
    
    final textColor = isDark ? Colors.white : const Color(0xFF1A1C1F);
    final snippetColor = isDark ? Colors.white70 : const Color(0xFF414755);
    final dateColor = isDark ? Colors.white38 : const Color(0xFF717786);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderCol, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetailScreen(noteId: note.id),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showThickLeftBorder)
                  Container(
                    width: 6,
                    color: brandColor,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    note.title.isNotEmpty ? note.title : 'Untitled',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.push_pin,
                                  color: brandColor,
                                  size: 16,
                                ),
                              ],
                            ),
                            if (note.content.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                note.content,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: snippetColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatPinnedDate(note.updatedAt),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: dateColor,
                                ),
                            ),
                            if (folder != null && folder.name.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(folder.colorValue).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  folder.name.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(folder.colorValue),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            _buildSectionTitle('Pinned', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PinnedNotesScreen()),
              );
            }, brandColor),
            const SizedBox(height: 8),
            SizedBox(
              height: 152,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: pinnedNotes.length,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemBuilder: (context, index) {
                  final note = pinnedNotes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 14.0),
                    child: _buildPinnedCard(
                      context,
                      note,
                      isDark,
                      brandColor,
                      index == 0,
                      folders,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // --- Favorites Section ---
          if (favoriteNotes.isNotEmpty) ...[
            _buildSectionTitle('Favorites', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            }, brandColor),
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
          showBackButton: _selectedFolderId != null,
          onBack: onBack,
          trailing: _selectedFolderId == null
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${folderNotes.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: folderNotes.length,
                      itemBuilder: (context, index) {
                        final n = folderNotes[index];
                        return NoteCard(
                          note: n,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteDetailScreen(noteId: n.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (_selectedFolderId != null &&
                      displayFolders.isEmpty &&
                      folderNotes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 56,
                              color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Folder is empty',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: subtleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a note inside this folder to get started',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: subtleColor,
                              ),
                            ),
                          ],
                        ),
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

  // Unused bottom sheets removed to clean up settings tab code

  Widget _buildSettingsTab(
    Color brandColor,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF1E2124) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF8F887F);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E2E7);

    // Settings Header with brand-styled icon
    Widget settingsHeader = Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: brandColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Settings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF333E5A),
              ),
            ),
          ),
        ],
      ),
    );

    final showDarkMode = _settingsSearch.isEmpty ||
        'dark mode'.contains(_settingsSearch.toLowerCase()) ||
        'switch'.contains(_settingsSearch.toLowerCase()) ||
        'light'.contains(_settingsSearch.toLowerCase());

    final showAccentColor = _settingsSearch.isEmpty ||
        'accent color'.contains(_settingsSearch.toLowerCase()) ||
        'personalize'.contains(_settingsSearch.toLowerCase()) ||
        'theme'.contains(_settingsSearch.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        settingsHeader,
        
        // Full Width Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1E22) : const Color(0xFFE8E8ED),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _settingsSearchCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: 'Search settings...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: subtleColor),
                prefixIcon: Icon(Icons.search_rounded, color: brandColor, size: 20),
                suffixIcon: _settingsSearch.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: subtleColor, size: 18),
                        onPressed: () => setState(() {
                          _settingsSearch = '';
                          _settingsSearchCtrl.clear();
                        }),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                filled: false,
              ),
              onChanged: (v) => setState(() => _settingsSearch = v),
            ),
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 100.0),
            physics: const BouncingScrollPhysics(),
            children: [
              if (showDarkMode || showAccentColor) ...[
                Text(
                  'APPEARANCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subtleColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              
              // Dark Mode Card
              if (showDarkMode) ...[
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderCol, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: brandColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.dark_mode_outlined,
                          color: brandColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark Mode',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Switch between light and dark',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: subtleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDark,
                        activeColor: brandColor,
                        onChanged: (_) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Accent Color Card
              if (showAccentColor) ...[
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderCol, width: 1.0),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccentColorScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: brandColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.palette_outlined,
                              color: brandColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accent Color',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Personalize app theme',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: subtleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: brandColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: subtleColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              if (!showDarkMode && !showAccentColor)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: subtleColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No matching settings found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: subtleColor,
                        ),
                      ),
                    ],
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



  // ═══════════════════════════════════════════════════════════════════════════
  //  BOTTOM NAVIGATION BAR (Docked glass design)
  // ═══════════════════════════════════════════════════════════════════════════
  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.calendar_today_outlined;
      case 1:
        return Icons.description_outlined;
      case 2:
        return Icons.home_rounded;
      case 3:
        return Icons.folder_outlined;
      case 4:
        return Icons.settings_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;
    final targetX = itemWidth * _currentTab + itemWidth / 2;

    final barColor = isDark ? const Color(0xFF1C1E22) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06);

    return Container(
      height: 92,
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Sliding Background and Floating Action Circle
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: targetX, end: targetX),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, animX, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Painted background with the dynamic curve
                  CustomPaint(
                    size: Size(screenWidth, 92),
                    painter: BottomBarPainter(
                      activeX: animX,
                      color: barColor,
                      shadowColor: shadowColor,
                      isDark: isDark,
                    ),
                  ),
                  // Sliding Floating Circle
                  Positioned(
                    left: animX - 28, // Center of circle (diameter 56)
                    top: 8, // Rises slightly above the bar (since flatTopY is 32)
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getTabIcon(_currentTab),
                        color: (primaryColor == Colors.white || primaryColor.value == 0xFFFFFFFF) ? Colors.black : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // 2. Interactive Row of Icons
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  final isSelected = _currentTab == index;
                  final Color iconColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B665E);
                  
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _switchTab(index),
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isSelected ? 0.0 : 1.0,
                          child: Icon(
                            _getTabIcon(index),
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
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

class BottomBarPainter extends CustomPainter {
  final double activeX;
  final Color color;
  final Color shadowColor;
  final bool isDark;

  BottomBarPainter({
    required this.activeX,
    required this.color,
    required this.shadowColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E2E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    
    // Normal height of the flat top (bar height is 92, flat top is at Y = 32, giving 60px height for the bar)
    final double flatTopY = 32.0; 
    // Peak height of the curve (curves up to Y = 6, giving 26px rise)
    final double peakY = 6.0;
    // Width of the curve base
    final double curveWidth = 84.0;

    path.moveTo(0, size.height);
    path.lineTo(0, flatTopY + 16);
    // Rounded corner top-left of the navigation bar
    path.quadraticBezierTo(0, flatTopY, 16, flatTopY);
    
    // Line to the start of the curve
    path.lineTo(activeX - curveWidth / 2, flatTopY);
    
    // Cubic bezier curve up and down
    path.cubicTo(
      activeX - curveWidth / 3, flatTopY,
      activeX - curveWidth / 3, peakY,
      activeX, peakY,
    );
    path.cubicTo(
      activeX + curveWidth / 3, peakY,
      activeX + curveWidth / 3, flatTopY,
      activeX + curveWidth / 2, flatTopY,
    );

    // Line to the top-right corner
    path.lineTo(size.width - 16, flatTopY);
    // Rounded corner top-right
    path.quadraticBezierTo(size.width, flatTopY, size.width, flatTopY + 16);
    path.lineTo(size.width, size.height);
    path.close();

    // Draw shadow first
    canvas.drawShadow(path, Colors.black.withOpacity(isDark ? 0.8 : 0.1), 8.0, true);
    
    // Draw the main background shape
    canvas.drawPath(path, paint);

    // Create a path just for the top border
    final borderPath = Path();
    borderPath.moveTo(0, flatTopY + 16);
    borderPath.quadraticBezierTo(0, flatTopY, 16, flatTopY);
    borderPath.lineTo(activeX - curveWidth / 2, flatTopY);
    borderPath.cubicTo(
      activeX - curveWidth / 3, flatTopY,
      activeX - curveWidth / 3, peakY,
      activeX, peakY,
    );
    borderPath.cubicTo(
      activeX + curveWidth / 3, peakY,
      activeX + curveWidth / 3, flatTopY,
      activeX + curveWidth / 2, flatTopY,
    );
    borderPath.lineTo(size.width - 16, flatTopY);
    borderPath.quadraticBezierTo(size.width, flatTopY, size.width, flatTopY + 16);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant BottomBarPainter oldDelegate) {
    return oldDelegate.activeX != activeX ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

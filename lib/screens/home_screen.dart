import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../models/note_model.dart';
import '../models/folder_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';
import '../widgets/create_choice_sheet.dart';
import '../screens/note_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? selectedFolderId; // To filter notes by folder
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);

    // Filter notes by selected folder and search query
    List<Note> filteredNotes = allNotes;
    if (selectedFolderId != null) {
      filteredNotes = filteredNotes.where((note) => note.folderId == selectedFolderId).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filteredNotes = filteredNotes.where((note) {
        return note.title.toLowerCase().contains(q) ||
            note.content.toLowerCase().contains(q) ||
            note.checklist.any((item) => item.text.toLowerCase().contains(q));
      }).toList();
    }

    // Sort notes by updatedAt descending to show recent changes first
    final sortedNotes = List<Note>.from(filteredNotes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Segregate Pinned, Favorite, and Recent notes
    final pinnedNotes = sortedNotes.where((note) => note.isPinned).toList();
    final favoriteNotes = sortedNotes.where((note) => note.isFavorite).toList();
    final recentNotes = sortedNotes.where((note) => !note.isPinned).toList();

    final isWorkspaceEmpty = allNotes.isEmpty && folders.isEmpty;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFCEFD5), // Soft peach/sand (top-right)
              Color(0xFFFAF8F5), // Warm ivory/white (bottom-left)
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PERSISTENT SEARCH BAR
              _buildSearchBar(context),

              // 2. MAIN CONTENT
              Expanded(
                child: isWorkspaceEmpty
                    ? const EmptyState()
                    : (filteredNotes.isEmpty && (searchQuery.isNotEmpty || selectedFolderId != null))
                        ? _buildNoNotesFoundState()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pinned Section
                                if (pinnedNotes.isNotEmpty) ...[
                                  _buildSectionHeader('Pinned Notes', pinnedNotes.length),
                                  const SizedBox(height: 4),
                                  _buildNotesHorizontalList(pinnedNotes),
                                  const SizedBox(height: 16),
                                ],

                                // Favorites Section
                                if (favoriteNotes.isNotEmpty) ...[
                                  _buildSectionHeader('Favorites', favoriteNotes.length),
                                  const SizedBox(height: 4),
                                  _buildNotesHorizontalList(favoriteNotes),
                                  const SizedBox(height: 16),
                                ],

                                // Folders Section
                                if (folders.isNotEmpty) ...[
                                  _buildSectionHeader('Folders', folders.length),
                                  const SizedBox(height: 4),
                                  _buildFoldersHorizontalList(context, ref, folders, allNotes),
                                  const SizedBox(height: 16),
                                ],

                                // Recent Notes Section
                                if (recentNotes.isNotEmpty) ...[
                                  _buildSectionHeader('Recent Notes', recentNotes.length),
                                  const SizedBox(height: 4),
                                  _buildNotesHorizontalList(recentNotes),
                                ],
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      // 3. FAB (Squircle Floating Action Button)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateChoiceSheet(),
          );
        },
        backgroundColor: const Color(0xFFF5A25D), // Warm soft peach
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18), // Squircle-like appearance
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // --- Search Bar Widget ---
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5DEC9),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2A29),
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8F887F),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6B665E), size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF6B665E), size: 18),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    searchQuery = val.trim();
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24, color: Color(0xFF2C2A29)),
            onPressed: () {
              _showSettingsBottomSheet(context);
            },
          ),
        ],
      ),
    );
  }

  // --- No Notes Found State ---
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

  // --- Section Header Widget ---
  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2C2A29),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF2E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5DEC9), width: 1.0),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B665E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Notes Horizontal List ---
  Widget _buildNotesHorizontalList(List<Note> notes) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: notes.length,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemBuilder: (context, index) {
          final note = notes[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: 180,
              child: NoteCard(
                note: note,
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
    );
  }

  // --- Folders Horizontal List ---
  Widget _buildFoldersHorizontalList(
    BuildContext context,
    WidgetRef ref,
    List<Folder> folders,
    List<Note> allNotes,
  ) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: folders.length + 1,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _buildAllNotesCard(context, allNotes.length),
            );
          }
          final folder = folders[index - 1];
          final noteCount = allNotes.where((n) => n.folderId == folder.id).length;
          final isSelected = folder.id == selectedFolderId;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (selectedFolderId == folder.id) {
                    selectedFolderId = null; // Toggle selection off
                  } else {
                    selectedFolderId = folder.id;
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2C2A29) : const Color(0xFFE5DEC9),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color dot and note count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(folder.colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE5DEC9), width: 0.5),
                          ),
                        ),
                        Text(
                          '$noteCount notes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8F887F),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Folder Name
                    Text(
                      folder.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2A29),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Edit & Delete row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B665E)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _showEditFolderDialog(context, ref, folder);
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _showDeleteFolderDialog(context, ref, folder);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- "All Notes" Folder Card ---
  Widget _buildAllNotesCard(BuildContext context, int totalNotesCount) {
    final isSelected = selectedFolderId == null;
    return InkWell(
      onTap: () {
        setState(() {
          selectedFolderId = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2C2A29) : const Color(0xFFE5DEC9),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.notes,
                  size: 16,
                  color: Color(0xFF2C2A29),
                ),
                Text(
                  '$totalNotesCount notes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8F887F),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'All Notes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C2A29),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Empty space to align with folder cards
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Settings Bottom Sheet ---
  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF8F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5DEC9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Workspace Settings',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(
                    'Nuvio Notes v1.0.0',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Offline-first Recycled Canvas design.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Edit Folder Dialog ---
  void _showEditFolderDialog(BuildContext context, WidgetRef ref, Folder folder) {
    final nameController = TextEditingController(text: folder.name);
    int selectedColor = folder.colorValue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFAF8F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Edit Folder',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C2A29),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Folder Name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5DEC9)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      initialValue: selectedColor,
                      decoration: InputDecoration(
                        labelText: 'Theme Color',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5DEC9)),
                        ),
                      ),
                      items: [
                        _buildColorDropdownItem(0xFFFAF2E6, 'Warm Beige'),
                        _buildColorDropdownItem(0xFFFCEFD5, 'Orange/Peach'),
                        _buildColorDropdownItem(0xFFE0F2FE, 'Sky Blue'),
                        _buildColorDropdownItem(0xFFDCFCE7, 'Mint Green'),
                        _buildColorDropdownItem(0xFFF3E8FF, 'Violet'),
                        _buildColorDropdownItem(0xFFFEE2E2, 'Coral Red'),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedColor = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF6B665E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      ref.read(foldersProvider.notifier).updateFolder(folder.id, name, selectedColor);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A25D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Delete Folder Dialog ---
  void _showDeleteFolderDialog(BuildContext context, WidgetRef ref, Folder folder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF8F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Folder',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C2A29),
            ),
          ),
          content: Text(
            'Are you sure you want to delete the folder "${folder.name}"? The notes in this folder will not be deleted, but they will no longer be linked to this folder.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF6B665E),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B665E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(foldersProvider.notifier).deleteFolder(folder.id);
                ref.read(notesProvider.notifier).removeFolderLink(folder.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Color Dropdown Item Builder ---
  DropdownMenuItem<int> _buildColorDropdownItem(int colorVal, String name) {
    return DropdownMenuItem<int>(
      value: colorVal,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Color(colorVal),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5DEC9), width: 1.0),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2C2A29),
            ),
          ),
        ],
      ),
    );
  }
}

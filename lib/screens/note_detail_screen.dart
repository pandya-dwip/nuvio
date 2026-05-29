import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note_model.dart';
import '../models/folder_model.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final TextEditingController _checklistInputController = TextEditingController();

  List<ChecklistItem> _checklistItems = [];
  int _colorValue = 0xFFFFFFFF;
  String? _folderId;

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final note = ref.watch(notesProvider).firstWhere(
            (n) => n.id == widget.noteId,
            orElse: () => Note(
              id: widget.noteId,
              title: '',
              content: '',
              isPinned: false,
              isFavorite: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              colorValue: 0xFFFFFFFF,
              checklist: [],
            ),
          );

      _titleController = TextEditingController(text: note.title);
      _contentController = TextEditingController(text: note.content);
      _checklistItems = List.from(note.checklist);
      _colorValue = note.colorValue;
      _folderId = note.folderId;
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _checklistInputController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // If note is completely empty, delete it to prevent clutter
    if (title.isEmpty && content.isEmpty && _checklistItems.isEmpty) {
      ref.read(notesProvider.notifier).deleteNote(widget.noteId);
    } else {
      ref.read(notesProvider.notifier).updateNote(
            widget.noteId,
            title: title,
            content: content,
            colorValue: _colorValue,
            checklist: _checklistItems,
            folderId: _folderId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);

    // Find note to watch reactive updates for pin/favorite status
    final note = allNotes.firstWhere(
      (n) => n.id == widget.noteId,
      orElse: () => Note(
        id: widget.noteId,
        title: _titleController.text,
        content: _contentController.text,
        isPinned: false,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        colorValue: _colorValue,
        checklist: _checklistItems,
      ),
    );

    final colors = [
      0xFFFFFFFF, // White
      0xFFFAF2E6, // Warm Beige
      0xFFFCEFD5, // Orange/Peach
      0xFFE0F2FE, // Sky Blue
      0xFFDCFCE7, // Mint Green
      0xFFF3E8FF, // Violet
    ];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: Color(_colorValue),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2C2A29), size: 20),
            onPressed: () {
              _saveNote();
              Navigator.pop(context);
            },
          ),
          actions: [
            // Pin Toggle Button
            IconButton(
              icon: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.isPinned ? const Color(0xFFF5A25D) : const Color(0xFF2C2A29),
              ),
              onPressed: () {
                ref.read(notesProvider.notifier).togglePin(widget.noteId);
              },
            ),

            // Favorite Toggle Button
            IconButton(
              icon: Icon(
                note.isFavorite ? Icons.star : Icons.star_border,
                color: note.isFavorite ? const Color(0xFFF5A25D) : const Color(0xFF2C2A29),
              ),
              onPressed: () {
                ref.read(notesProvider.notifier).toggleFavorite(widget.noteId);
              },
            ),

            // Three-dots options menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Color(0xFF2C2A29)),
              color: const Color(0xFFFAF8F5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) => _handleMenuOption(value, folders),
              itemBuilder: (context) => [
                _buildMenuItem('duplicate', Icons.copy_all, 'Duplicate Note'),
                _buildMenuItem('move', Icons.folder_open, 'Move to Folder'),
                _buildMenuItem('archive', Icons.archive_outlined, 'Archive'),
                _buildMenuItem('tags', Icons.label_outline, 'Add Tags'),
                _buildMenuItem('share', Icons.share_outlined, 'Share'),
                _buildMenuItem('export', Icons.download_outlined, 'Export'),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(
                    'Delete Note',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Editable Title Field
                      TextField(
                        controller: _titleController,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C2A29),
                        ),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(color: const Color(0xFF2C2A29).withAlpha(80)),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Editable Content Field
                      TextField(
                        controller: _contentController,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.6,
                          color: const Color(0xFF4A453F),
                        ),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Start writing...',
                          hintStyle: TextStyle(color: const Color(0xFF6B665E).withAlpha(100)),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Checklist items header
                      if (_checklistItems.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tasks',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6B665E),
                              ),
                            ),
                            Text(
                              'More Options v',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8F887F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: _checklistItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: item.isChecked,
                                    activeColor: const Color(0xFFF5A25D),
                                    onChanged: (val) {
                                      setState(() {
                                        final index = _checklistItems.indexOf(item);
                                        _checklistItems[index] = item.copyWith(isChecked: val ?? false);
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.text,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                        color: item.isChecked ? Colors.grey : const Color(0xFF2C2A29),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        _checklistItems.remove(item);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Add checklist item builder row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _checklistInputController,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Add task item...',
                                filled: true,
                                fillColor: Colors.white.withAlpha(128),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE5DEC9)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFFF5A25D)),
                            onPressed: () {
                              final text = _checklistInputController.text.trim();
                              if (text.isNotEmpty) {
                                setState(() {
                                  _checklistItems.add(ChecklistItem(text: text, isChecked: false));
                                  _checklistInputController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom note details panel (Color selection, folder selector, last edited timestamp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  border: const Border(top: BorderSide(color: Color(0xFFE5DEC9), width: 0.8)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color Palette Selector Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colors.map((cValue) {
                        final isSelected = cValue == _colorValue;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _colorValue = cValue;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(cValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2C2A29) : const Color(0xFFE5DEC9),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Last edited timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last edited ${_formatTime(note.updatedAt)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8F887F),
                          ),
                        ),
                        // Small folder label tag
                        if (folders.isNotEmpty)
                          DropdownButton<String?>(
                            value: _folderId,
                            hint: Text(
                              'No Folder',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF8F887F)),
                            ),
                            underline: Container(),
                            dropdownColor: const Color(0xFFFAF8F5),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No Folder', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                              ),
                              ...folders.map((f) {
                                return DropdownMenuItem<String?>(
                                  value: f.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: Color(f.colorValue), shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(f.name, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _folderId = val;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2C2A29), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C2A29),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuOption(String option, List<Folder> folders) {
    if (option == 'delete') {
      ref.read(notesProvider.notifier).deleteNote(widget.noteId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted')),
      );
      Navigator.pop(context);
    } else if (option == 'duplicate') {
      ref.read(notesProvider.notifier).duplicateNote(widget.noteId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note duplicated')),
      );
      Navigator.pop(context);
    } else if (option == 'move') {
      _showMoveFolderDialog(context, folders);
    } else {
      // Mock other features (Archive, Tags, Share, Export)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note: $option completed (demo)')),
      );
    }
  }

  void _showMoveFolderDialog(BuildContext context, List<Folder> folders) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF8F5),
          title: Text('Move Note to Folder', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: folders.isEmpty
              ? Text('No folders exist. Create one first.', style: GoogleFonts.plusJakartaSans())
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: folders.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          title: const Text('Remove from Folder'),
                          onTap: () {
                            setState(() {
                              _folderId = null;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }
                      final folder = folders[index - 1];
                      return ListTile(
                        leading: Icon(Icons.folder, color: Color(folder.colorValue)),
                        title: Text(folder.name),
                        onTap: () {
                          setState(() {
                            _folderId = folder.id;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

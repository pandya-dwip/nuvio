import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../screens/note_detail_screen.dart';

class CreateChoiceSheet extends ConsumerWidget {
  const CreateChoiceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF15171A) : const Color(0xFFFAF8F5);
    final textColor = isDark ? Colors.white : const Color(0xFF2C2A29);
    final borderCol = isDark ? Colors.white10 : const Color(0xFFE5DEC9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE5DEC9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create New',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceCard(
                    context: context,
                    icon: Icons.note_add_outlined,
                    label: 'Note',
                    description: 'Write thoughts & checklists',
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFFAF2E6),
                    textColor: textColor,
                    borderCol: borderCol,
                    onTap: () {
                      Navigator.pop(context); // Pop sheet

                      final newNote = ref.read(notesProvider.notifier).addNote(
                            title: '',
                            content: '',
                            colorValue: 0xFFFFFFFF,
                            checklist: [],
                          );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetailScreen(noteId: newNote.id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChoiceCard(
                    context: context,
                    icon: Icons.create_new_folder_outlined,
                    label: 'Folder',
                    description: 'Organize notes in sections',
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE5DEC9).withOpacity(0.3),
                    textColor: textColor,
                    borderCol: borderCol,
                    onTap: () {
                      Navigator.pop(context); // Pop sheet
                      _showCreateFolderDialog(context, ref);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required Color textColor,
    required Color borderCol,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderCol,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: textColor,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    int selectedColor = 0xFFFAF2E6; // Default beige
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF15171A) : const Color(0xFFFAF8F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'New Folder',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2C2A29),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Folder Name',
                        hintText: 'e.g. Work, Ideas',
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.white,
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
                        fillColor: isDark ? Colors.white10 : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5DEC9)),
                        ),
                      ),
                      items: [
                        _buildColorDropdownItem(context, 0xFFFAF2E6, 'Warm Beige'),
                        _buildColorDropdownItem(context, 0xFFFCEFD5, 'Orange/Peach'),
                        _buildColorDropdownItem(context, 0xFFE0F2FE, 'Sky Blue'),
                        _buildColorDropdownItem(context, 0xFFDCFCE7, 'Mint Green'),
                        _buildColorDropdownItem(context, 0xFFF3E8FF, 'Violet'),
                        _buildColorDropdownItem(context, 0xFFFEE2E2, 'Coral Red'),
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
                      ref.read(foldersProvider.notifier).addFolder(name, selectedColor);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A25D), // Orange theme
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create',
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

  DropdownMenuItem<int> _buildColorDropdownItem(BuildContext context, int colorVal, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? Colors.white70 : const Color(0xFF2C2A29),
            ),
          ),
        ],
      ),
    );
  }
}

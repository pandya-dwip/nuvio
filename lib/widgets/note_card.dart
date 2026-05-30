import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';

class NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    // In dark mode, if the note has default white color (0xFFFFFFFF), use the theme's card color.
    final cardColor = (note.colorValue == 0xFFFFFFFF && isDarkTheme)
        ? Theme.of(context).colorScheme.surface
        : Color(note.colorValue);

    final isCardDark = ThemeData.estimateBrightnessForColor(cardColor) == Brightness.dark;

    final textColor = isCardDark ? Colors.white : const Color(0xFF2C2A29);
    final textMuted = isCardDark ? Colors.white70 : const Color(0xFF6B665E);
    final textSecondary = isCardDark ? Colors.white60 : const Color(0xFF8F887F);
    final borderColor = isDarkTheme ? Colors.white12 : const Color(0xFFE5DEC9).withAlpha(128);

    // Find first image block in note
    String? imageUrl;
    for (final block in note.blocks) {
      if (block.type == BlockType.image && block.images.isNotEmpty) {
        imageUrl = block.images.first.url;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          onLongPress: () {
            // Show options dialog (Pin/Unpin, Delete)
            _showNoteOptions(context, ref);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.file(
                    File(imageUrl),
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and Star icon
                    Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isNotEmpty ? note.title : 'Untitled',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor, // Dynamic title color
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      Icon(
                        Icons.push_pin,
                        color: Theme.of(context).primaryColor, // Dynamic pin color
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Note content snippet
                if (note.content.isNotEmpty) ...[
                  Text(
                    note.content,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: textMuted, // Dynamic body color
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Checklist checklist previews
                if (note.checklist.isNotEmpty) ...[
                  Column(
                    children: note.checklist.take(3).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              item.isChecked
                                  ? Icons.check_box_outlined
                                  : Icons.check_box_outline_blank,
                              size: 16,
                              color: item.isChecked
                                  ? Theme.of(context).primaryColor
                                  : textSecondary, // Dynamic checkbox border color
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.text,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: item.isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isChecked
                                      ? (isCardDark ? Colors.white38 : const Color(0xFF9CA3AF))
                                      : textMuted, // Dynamic checklist text color
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Last edited info
                Text(
                  _formatLastEdited(note.updatedAt),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textSecondary, // Dynamic metadata color
                  ),
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

  String _formatLastEdited(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Last edited just now';
    } else if (difference.inHours < 1) {
      return 'Last edited ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Last edited ${difference.inHours}h ago';
    } else {
      return 'Last edited ${difference.inDays}d ago';
    }
  }

  void _showNoteOptions(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sheetBg = isDark ? const Color(0xFF15171A) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: textColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  note.isPinned ? 'Unpin Note' : 'Pin Note',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                onTap: () {
                  ref.read(notesProvider.notifier).togglePin(note.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Delete Note',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () {
                  ref.read(notesProvider.notifier).deleteNote(note.id);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

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
    final cardColor = Color(note.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5DEC9).withAlpha(128),
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
          child: Padding(
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
                          color: const Color(0xFF2C2A29), // Deep warm charcoal
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      const Icon(
                        Icons.star,
                        color: Color(0xFFF5A25D), // Gold star
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
                      color: const Color(0xFF6B665E), // Muted grey
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
                                  ? const Color(0xFFF5A25D)
                                  : const Color(0xFF8F887F),
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
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF4A453F),
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
                    color: const Color(0xFF8F887F),
                  ),
                ),
              ],
            ),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF8F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DEC9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.star_border : Icons.star,
                  color: const Color(0xFF2C2A29),
                ),
                title: Text(
                  note.isPinned ? 'Unpin Note' : 'Pin Note',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C2A29),
                  ),
                ),
                onTap: () {
                  ref.read(notesProvider.notifier).togglePin(note.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
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
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

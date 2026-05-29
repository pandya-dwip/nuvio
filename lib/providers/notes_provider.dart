import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]);

  // Adds a note and returns the newly created Note object
  Note addNote({
    required String title,
    required String content,
    required int colorValue,
    required List<ChecklistItem> checklist,
    String? folderId,
    bool isPinned = false,
    bool isFavorite = false,
  }) {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      isPinned: isPinned,
      isFavorite: isFavorite,
      folderId: folderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorValue: colorValue,
      checklist: checklist,
    );
    state = [...state, newNote];
    return newNote;
  }

  void updateNote(
    String id, {
    String? title,
    String? content,
    int? colorValue,
    List<ChecklistItem>? checklist,
    String? folderId,
    bool? isPinned,
    bool? isFavorite,
  }) {
    state = state.map((note) {
      if (note.id == id) {
        return note.copyWith(
          title: title,
          content: content,
          colorValue: colorValue,
          checklist: checklist,
          folderId: folderId,
          isPinned: isPinned,
          isFavorite: isFavorite,
          updatedAt: DateTime.now(),
        );
      }
      return note;
    }).toList();
  }

  void togglePin(String id) {
    state = state.map((note) {
      if (note.id == id) {
        return note.copyWith(
          isPinned: !note.isPinned,
          updatedAt: DateTime.now(),
        );
      }
      return note;
    }).toList();
  }

  void toggleFavorite(String id) {
    state = state.map((note) {
      if (note.id == id) {
        return note.copyWith(
          isFavorite: !note.isFavorite,
          updatedAt: DateTime.now(),
        );
      }
      return note;
    }).toList();
  }

  void duplicateNote(String id) {
    final original = state.firstWhere((note) => note.id == id);
    final duplicated = Note(
      id: '${DateTime.now().millisecondsSinceEpoch}_dup',
      title: '${original.title} (Copy)',
      content: original.content,
      isPinned: original.isPinned,
      isFavorite: original.isFavorite,
      folderId: original.folderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorValue: original.colorValue,
      checklist: original.checklist.map((item) => item.copyWith()).toList(),
    );
    state = [...state, duplicated];
  }

  void deleteNote(String id) {
    state = state.where((note) => note.id != id).toList();
  }

  void deleteNotesInFolder(String folderId) {
    state = state.where((note) => note.folderId != folderId).toList();
  }

  void removeFolderLink(String folderId) {
    state = state.map((note) {
      if (note.folderId == folderId) {
        return note.copyWithNullFolderId();
      }
      return note;
    }).toList();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

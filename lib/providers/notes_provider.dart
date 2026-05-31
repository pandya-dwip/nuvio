import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]) {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('nuvio_notes');
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        state = jsonList.map((j) => Note.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      state = [];
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((n) => n.toJson()).toList();
      await prefs.setString('nuvio_notes', jsonEncode(jsonList));
    } catch (e) {
      // Handle saving errors silently
    }
  }

  // Adds a note and returns the newly created Note object
  Note addNote({
    required String title,
    required String content,
    required int colorValue,
    required List<ChecklistItem> checklist,
    List<NoteBlock> blocks = const [],
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
      blocks: blocks,
    );
    state = [...state, newNote];
    _saveNotes();
    return newNote;
  }

  void updateNote(
    String id, {
    String? title,
    String? content,
    int? colorValue,
    List<ChecklistItem>? checklist,
    List<NoteBlock>? blocks,
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
          blocks: blocks,
          folderId: folderId,
          isPinned: isPinned,
          isFavorite: isFavorite,
          updatedAt: DateTime.now(),
        );
      }
      return note;
    }).toList();
    _saveNotes();
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
    _saveNotes();
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
    _saveNotes();
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
      blocks: original.blocks.map((block) => block.copyWith()).toList(),
    );
    state = [...state, duplicated];
    _saveNotes();
  }

  void deleteNote(String id) {
    state = state.where((note) => note.id != id).toList();
    _saveNotes();
  }

  void deleteNotesInFolder(String folderId) {
    state = state.where((note) => note.folderId != folderId).toList();
    _saveNotes();
  }

  void removeFolderLink(String folderId) {
    state = state.map((note) {
      if (note.folderId == folderId) {
        return note.copyWithNullFolderId();
      }
      return note;
    }).toList();
    _saveNotes();
  }

  void clearAllNotes() {
    state = [];
    _saveNotes();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

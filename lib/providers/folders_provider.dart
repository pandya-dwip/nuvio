import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/folder_model.dart';

class FoldersNotifier extends StateNotifier<List<Folder>> {
  FoldersNotifier() : super([]) {
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('nuvio_folders');
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        state = jsonList.map((j) => Folder.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Handle loading error or default to empty
      state = [];
    }
  }

  Future<void> _saveFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((f) => f.toJson()).toList();
      await prefs.setString('nuvio_folders', jsonEncode(jsonList));
    } catch (e) {
      // Handle saving errors silently
    }
  }

  Folder addFolder(String name, int colorValue, {String? parentId}) {
    final newFolder = Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      colorValue: colorValue,
      parentId: parentId,
    );
    state = [...state, newFolder];
    _saveFolders();
    return newFolder;
  }

  void deleteFolder(String id) {
    // Delete all child folders recursively
    final idsToDelete = <String>{id};
    _findChildFolderIds(id, idsToDelete);

    state = state.where((folder) => !idsToDelete.contains(folder.id)).toList();
    _saveFolders();
  }

  void _findChildFolderIds(String parentId, Set<String> collectedIds) {
    final children = state.where((f) => f.parentId == parentId).map((f) => f.id).toList();
    for (final childId in children) {
      if (collectedIds.add(childId)) {
        _findChildFolderIds(childId, collectedIds);
      }
    }
  }

  void updateFolder(String id, String name, int colorValue) {
    state = state.map((folder) {
      if (folder.id == id) {
        return folder.copyWith(
          name: name,
          colorValue: colorValue,
        );
      }
      return folder;
    }).toList();
    _saveFolders();
  }

  void togglePin(String id) {
    state = state.map((folder) {
      if (folder.id == id) {
        return folder.copyWith(isPinned: !folder.isPinned);
      }
      return folder;
    }).toList();
    _saveFolders();
  }
}

final foldersProvider = StateNotifierProvider<FoldersNotifier, List<Folder>>((ref) {
  return FoldersNotifier();
});

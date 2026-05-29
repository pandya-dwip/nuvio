import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/folder_model.dart';

class FoldersNotifier extends StateNotifier<List<Folder>> {
  FoldersNotifier() : super([]);

  void addFolder(String name, int colorValue) {
    final newFolder = Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      colorValue: colorValue,
    );
    state = [...state, newFolder];
  }

  void deleteFolder(String id) {
    state = state.where((folder) => folder.id != id).toList();
  }

  void updateFolder(String id, String name, int colorValue) {
    state = state.map((folder) {
      if (folder.id == id) {
        return Folder(
          id: folder.id,
          name: name,
          createdAt: folder.createdAt,
          colorValue: colorValue,
        );
      }
      return folder;
    }).toList();
  }
}

final foldersProvider = StateNotifierProvider<FoldersNotifier, List<Folder>>((ref) {
  return FoldersNotifier();
});

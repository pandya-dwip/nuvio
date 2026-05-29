class ChecklistItem {
  final String text;
  final bool isChecked;

  ChecklistItem({
    required this.text,
    required this.isChecked,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isChecked': isChecked,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      text: json['text'] as String,
      isChecked: json['isChecked'] as bool,
    );
  }

  ChecklistItem copyWith({String? text, bool? isChecked}) {
    return ChecklistItem(
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final bool isPinned;
  final bool isFavorite;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int colorValue;
  final List<ChecklistItem> checklist;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.isFavorite,
    this.folderId,
    required this.createdAt,
    required this.updatedAt,
    required this.colorValue,
    required this.checklist,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'colorValue': colorValue,
      'checklist': checklist.map((item) => item.toJson()).toList(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isPinned: json['isPinned'] as bool,
      isFavorite: json['isFavorite'] as bool? ?? false,
      folderId: json['folderId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      colorValue: json['colorValue'] as int,
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Note copyWith({
    String? title,
    String? content,
    bool? isPinned,
    bool? isFavorite,
    String? folderId,
    DateTime? updatedAt,
    int? colorValue,
    List<ChecklistItem>? checklist,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorValue: colorValue ?? this.colorValue,
      checklist: checklist ?? this.checklist,
    );
  }

  Note copyWithNullFolderId() {
    return Note(
      id: id,
      title: title,
      content: content,
      isPinned: isPinned,
      isFavorite: isFavorite,
      folderId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
      colorValue: colorValue,
      checklist: checklist,
    );
  }
}

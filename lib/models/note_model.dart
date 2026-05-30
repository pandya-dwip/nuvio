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

enum BlockType { text, task, image, quote, file }

class NoteImage {
  final String id;
  final String url;
  final String name;
  final String description;

  NoteImage({
    required this.id,
    required this.url,
    this.name = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'description': description,
    };
  }

  factory NoteImage.fromJson(Map<String, dynamic> json) {
    return NoteImage(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  NoteImage copyWith({
    String? id,
    String? url,
    String? name,
    String? description,
  }) {
    return NoteImage(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}

class NoteBlock {
  final String id;
  final BlockType type;
  final String text;
  final bool isChecked;
  final List<NoteImage> images;

  NoteBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.isChecked = false,
    this.images = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'isChecked': isChecked,
      'images': images.map((img) => img.toJson()).toList(),
    };
  }

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    return NoteBlock(
      id: json['id'] as String,
      type: BlockType.values.byName(json['type'] as String),
      text: json['text'] as String? ?? '',
      isChecked: json['isChecked'] as bool? ?? false,
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => NoteImage.fromJson(img as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  NoteBlock copyWith({
    String? id,
    BlockType? type,
    String? text,
    bool? isChecked,
    List<NoteImage>? images,
  }) {
    return NoteBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
      images: images ?? this.images,
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
  final List<NoteBlock> blocks;

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
    this.blocks = const [],
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
      'blocks': blocks.map((block) => block.toJson()).toList(),
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
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map((block) => NoteBlock.fromJson(block as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  List<NoteBlock> get safeBlocks {
    if (blocks.isNotEmpty) return blocks;
    
    final fallback = <NoteBlock>[];
    if (content.isNotEmpty) {
      fallback.add(NoteBlock(
        id: 'init_text',
        type: BlockType.text,
        text: content,
      ));
    }
    for (int i = 0; i < checklist.length; i++) {
      fallback.add(NoteBlock(
        id: 'init_task_$i',
        type: BlockType.task,
        text: checklist[i].text,
        isChecked: checklist[i].isChecked,
      ));
    }
    if (fallback.isEmpty) {
      fallback.add(NoteBlock(
        id: 'init_empty',
        type: BlockType.text,
        text: '',
      ));
    }
    return fallback;
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
    List<NoteBlock>? blocks,
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
      blocks: blocks ?? this.blocks,
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
      blocks: blocks,
    );
  }
}


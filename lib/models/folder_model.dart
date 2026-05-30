class Folder {
  final String id;
  final String name;
  final DateTime createdAt;
  final int colorValue;
  final String? parentId; // String reference to parent folder (null if root level)
  final bool isPinned;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.colorValue,
    this.parentId,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'colorValue': colorValue,
      'parentId': parentId,
      'isPinned': isPinned,
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      colorValue: json['colorValue'] as int,
      parentId: json['parentId'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Folder copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? colorValue,
    String? parentId,
    bool? isPinned,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      colorValue: colorValue ?? this.colorValue,
      parentId: parentId ?? this.parentId,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

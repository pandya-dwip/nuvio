class Folder {
  final String id;
  final String name;
  final DateTime createdAt;
  final int colorValue;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'colorValue': colorValue,
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      colorValue: json['colorValue'] as int,
    );
  }
}

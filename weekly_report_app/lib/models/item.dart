import 'dart:convert';

enum ItemCategory {
  routine,
  task,
  hobby;

  String get displayName {
    switch (this) {
      case ItemCategory.routine:
        return 'Routine';
      case ItemCategory.task:
        return 'Task';
      case ItemCategory.hobby:
        return 'Hobby';
    }
  }

  static ItemCategory fromString(String value) {
    return ItemCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItemCategory.task,
    );
  }
}

class Item {
  final String id;
  final String title;
  final ItemCategory category;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.id,
    required this.title,
    required this.category,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  Item copyWith({
    String? title,
    ItemCategory? category,
    String? memo,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      memo: memo ?? this.memo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'memo': memo,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        title: json['title'] as String,
        category: ItemCategory.fromString(json['category'] as String),
        memo: json['memo'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static List<Item> listFromJson(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Item> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}

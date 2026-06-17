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

  // Routine: 今日やったか（日付が変わると自動リセット）
  final DateTime? lastDoneDate;
  // Routine: 補助カウンター
  final int count;
  // Task: 完了状態
  final bool isDone;
  // Hobby: 進捗 0-100
  final int progress;

  const Item({
    required this.id,
    required this.title,
    required this.category,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
    this.lastDoneDate,
    this.count = 0,
    this.isDone = false,
    this.progress = 0,
  });

  // Hobby: count 0=Lv0, 1-4=Lv1, 5-9=Lv2, 10-19=Lv3, 20-49=Lv4, 50+=Lv5
  int get hobbyLevel {
    if (count == 0) return 0;
    if (count < 5) return 1;
    if (count < 10) return 2;
    if (count < 20) return 3;
    if (count < 50) return 4;
    return 5;
  }

  bool get isDoneToday {
    if (lastDoneDate == null) return false;
    final today = DateTime.now();
    return lastDoneDate!.year == today.year &&
        lastDoneDate!.month == today.month &&
        lastDoneDate!.day == today.day;
  }

  Item copyWith({
    String? title,
    ItemCategory? category,
    String? memo,
    DateTime? updatedAt,
    DateTime? lastDoneDate,
    bool resetLastDoneDate = false,
    int? count,
    bool? isDone,
    int? progress,
  }) {
    return Item(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      memo: memo ?? this.memo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastDoneDate:
          resetLastDoneDate ? null : (lastDoneDate ?? this.lastDoneDate),
      count: count ?? this.count,
      isDone: isDone ?? this.isDone,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'memo': memo,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastDoneDate': lastDoneDate?.toIso8601String(),
        'count': count,
        'isDone': isDone,
        'progress': progress,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        title: json['title'] as String,
        category: ItemCategory.fromString(json['category'] as String),
        memo: json['memo'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        lastDoneDate: json['lastDoneDate'] != null
            ? DateTime.parse(json['lastDoneDate'] as String)
            : null,
        count: (json['count'] as int?) ?? 0,
        isDone: (json['isDone'] as bool?) ?? false,
        progress: (json['progress'] as int?) ?? 0,
      );

  static List<Item> listFromJson(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Item> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}

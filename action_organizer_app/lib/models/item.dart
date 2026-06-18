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
  // Hobby: 累計経験値（タップ+10 / 達成記録+20 / 100で1レベルアップ）
  final int xp;

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
    this.xp = 0,
  });

  // Hobby: XP 100ごとに1レベル、Lv.1スタート、上限Lv.999
  int get hobbyLevel => (xp ~/ 100 + 1).clamp(1, 999);
  int get hobbyXpInLevel => xp % 100;
  bool get isHobbyAtMax => xp ~/ 100 >= 999;

  String get hobbyRankName {
    final lv = hobbyLevel;
    if (lv >= 100) return '横綱';
    if (lv >= 90) return '大関';
    if (lv >= 80) return '関脇';
    if (lv >= 70) return '小結';
    if (lv >= 60) return '前頭';
    if (lv >= 50) return '十両';
    if (lv >= 40) return '幕下';
    if (lv >= 30) return '三段目';
    if (lv >= 20) return '序二段';
    if (lv >= 10) return '序ノ口';
    return '前相撲';
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
    int? xp,
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
      xp: xp ?? this.xp,
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
        'xp': xp,
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
        xp: (json['xp'] as int?) ?? 0,
      );

  static List<Item> listFromJson(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Item> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}

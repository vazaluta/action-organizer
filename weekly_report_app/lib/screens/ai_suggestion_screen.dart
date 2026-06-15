import 'package:flutter/material.dart';
import '../models/item.dart';

class AiSuggestion {
  final String message;
  final Item? targetItem;
  final ItemCategory? suggestedCategory;

  const AiSuggestion({
    required this.message,
    this.targetItem,
    this.suggestedCategory,
  });
}

List<AiSuggestion> generateSuggestions(List<Item> items) {
  final suggestions = <AiSuggestion>[];
  if (items.isEmpty) {
    suggestions.add(const AiSuggestion(
      message: 'まだアイテムがありません。習慣・タスク・趣味を追加してみましょう。',
    ));
    return suggestions;
  }

  final routines = items.where((i) => i.category == ItemCategory.routine).toList();
  final tasks = items.where((i) => i.category == ItemCategory.task).toList();
  final hobbies = items.where((i) => i.category == ItemCategory.hobby).toList();

  // Routineに移動できそうなTaskを提案
  final routineLikeKeywords = ['学習', '勉強', '運動', '筋トレ', '読書', '散歩', '瞑想', 'ランニング', '練習'];
  for (final task in tasks) {
    final matchedKeyword = routineLikeKeywords.firstWhere(
      (kw) => task.title.contains(kw),
      orElse: () => '',
    );
    if (matchedKeyword.isNotEmpty) {
      suggestions.add(AiSuggestion(
        message: '「${task.title}」は継続的に取り組む内容のため、Routineに移動することを検討してみてください。',
        targetItem: task,
        suggestedCategory: ItemCategory.routine,
      ));
    }
  }

  // HobbyをRoutineにできそうな提案
  final hobbyRoutineKeywords = ['ギター', '絵', 'ピアノ', '語学', '英語', '日記'];
  for (final hobby in hobbies) {
    final matchedKeyword = hobbyRoutineKeywords.firstWhere(
      (kw) => hobby.title.contains(kw),
      orElse: () => '',
    );
    if (matchedKeyword.isNotEmpty) {
      suggestions.add(AiSuggestion(
        message: '「${hobby.title}」は毎日少し続けることでRoutineになります。習慣化を検討してみましょう。',
        targetItem: hobby,
        suggestedCategory: ItemCategory.routine,
      ));
    }
  }

  // Routineが多い場合
  if (routines.length >= 5) {
    suggestions.add(AiSuggestion(
      message: 'Routineが${routines.length}件あります。優先度の低いものを一時停止して、集中できる習慣に絞ることを検討してみましょう。',
    ));
  }

  // Taskが多い場合
  if (tasks.length >= 5) {
    suggestions.add(AiSuggestion(
      message: 'Taskが${tasks.length}件あります。今週中に完了すべき最重要タスクを1〜3件に絞ってみましょう。',
    ));
  }

  // 全体が少ない場合
  if (items.length < 3) {
    suggestions.add(const AiSuggestion(
      message: 'アイテムがまだ少ないです。日々の習慣・やるべきこと・興味を積極的に追加してみましょう。',
    ));
  }

  // Hobbyが空の場合
  if (hobbies.isEmpty) {
    suggestions.add(const AiSuggestion(
      message: 'Hobbyが登録されていません。好きなこと・興味のあることを追加すると、自分の行動の全体像が見えやすくなります。',
    ));
  }

  if (suggestions.isEmpty) {
    suggestions.add(const AiSuggestion(
      message: '現在の整理状況は良好です。引き続きアイテムを更新して、自分の行動を見える化しましょう。',
    ));
  }

  return suggestions;
}

class AiSuggestionScreen extends StatefulWidget {
  final List<Item> items;
  final void Function(Item item, ItemCategory newCategory) onCategoryChanged;

  const AiSuggestionScreen({
    super.key,
    required this.items,
    required this.onCategoryChanged,
  });

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  late List<AiSuggestion> _suggestions;
  final Set<int> _applied = {};
  final Set<int> _ignored = {};

  @override
  void initState() {
    super.initState();
    _suggestions = generateSuggestions(widget.items);
  }

  void _apply(int index) {
    final suggestion = _suggestions[index];
    if (suggestion.targetItem != null && suggestion.suggestedCategory != null) {
      widget.onCategoryChanged(suggestion.targetItem!, suggestion.suggestedCategory!);
    }
    setState(() => _applied.add(index));
  }

  void _ignore(int index) {
    setState(() => _ignored.add(index));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome),
            SizedBox(width: 8),
            Text('AI提案'),
          ],
        ),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          final isApplied = _applied.contains(index);
          final isIgnored = _ignored.contains(index);
          final hasAction = suggestion.targetItem != null &&
              suggestion.suggestedCategory != null &&
              !isApplied;

          return Card(
            color: isApplied
                ? colorScheme.primaryContainer
                : isIgnored
                    ? colorScheme.surfaceContainerHighest
                    : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isApplied
                            ? Icons.check_circle
                            : Icons.lightbulb_outline,
                        color: isApplied
                            ? colorScheme.primary
                            : colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.message,
                          style: TextStyle(
                            color: isIgnored
                                ? colorScheme.outline
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isApplied) ...[
                    const SizedBox(height: 8),
                    Text(
                      '反映しました',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ] else if (!isIgnored && hasAction) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _ignore(index),
                          child: const Text('無視する'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _apply(index),
                          child: const Text('反映する'),
                        ),
                      ],
                    ),
                  ] else if (!isIgnored && !hasAction) ...[
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

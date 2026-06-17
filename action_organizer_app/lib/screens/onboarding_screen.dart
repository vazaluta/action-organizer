import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';

class OnboardingScreen extends StatefulWidget {
  final void Function(List<Item> selected) onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _candidates = {
    ItemCategory.routine: ['朝の運動', 'ストレッチ', '瞑想', '読書', '日記', '早起き'],
    ItemCategory.task: ['部屋の掃除', '洗濯', '買い物', '書類整理', 'メールの返信'],
    ItemCategory.hobby: ['ゲーム', '映画・ドラマ', '料理', '音楽', '散歩', 'イラスト'],
  };

  final Set<String> _selected = {};

  String _key(ItemCategory cat, String title) => '${cat.name}:$title';

  bool _isSelected(ItemCategory cat, String title) =>
      _selected.contains(_key(cat, title));

  void _toggle(ItemCategory cat, String title) {
    final k = _key(cat, title);
    setState(() {
      if (_selected.contains(k)) {
        _selected.remove(k);
      } else {
        _selected.add(k);
      }
    });
  }

  void _complete() {
    final now = DateTime.now();
    const uuid = Uuid();
    final items = <Item>[];
    for (final entry in _candidates.entries) {
      for (final title in entry.value) {
        if (_isSelected(entry.key, title)) {
          items.add(Item(
            id: uuid.v4(),
            title: title,
            category: entry.key,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }
    }
    widget.onComplete(items);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      '行動整理へようこそ',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'よく行う行動を選んでスタートしましょう。\nあとから自由に追加・削除できます。',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 36),
                    ..._candidates.entries.map(
                      (entry) => _CategorySection(
                        category: entry.key,
                        titles: entry.value,
                        isSelected: (t) => _isSelected(entry.key, t),
                        onToggle: (t) => _toggle(entry.key, t),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => widget.onComplete([]),
                    child: const Text('スキップ'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _complete,
                    child: Text(
                      _selected.isEmpty
                          ? '始める'
                          : '始める（${_selected.length}件）',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ItemCategory category;
  final List<String> titles;
  final bool Function(String) isSelected;
  final void Function(String) onToggle;

  const _CategorySection({
    required this.category,
    required this.titles,
    required this.isSelected,
    required this.onToggle,
  });

  Color _accentColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (category) {
      case ItemCategory.routine:
        return cs.primary;
      case ItemCategory.task:
        return cs.secondary;
      case ItemCategory.hobby:
        return cs.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: _accentColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: titles.map((title) {
            return FilterChip(
              label: Text(title),
              selected: isSelected(title),
              onSelected: (_) => onToggle(title),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/storage_service.dart';
import 'item_form_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storage = StorageService();
  List<Item> _items = [];
  bool _loading = true;

  static const _tabs = [
    ItemCategory.routine,
    ItemCategory.task,
    ItemCategory.hobby,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await _storage.loadItems();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _saveItems() async {
    await _storage.saveItems(_items);
  }

  ItemCategory get _currentCategory => _tabs[_tabController.index];

  Future<void> _openAddForm() async {
    final item = await Navigator.of(context).push<Item>(
      MaterialPageRoute(
        builder: (_) =>
            ItemFormScreen(initialCategory: _currentCategory),
      ),
    );
    if (item != null) {
      setState(() => _items.add(item));
      await _saveItems();
    }
  }

  Future<void> _deleteItem(Item item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    setState(() => _items.removeWhere((i) => i.id == item.id));
    await _saveItems();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${item.title}」を削除しました'),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            setState(() {
              final insertIndex = index.clamp(0, _items.length);
              _items.insert(insertIndex, item);
            });
            await _saveItems();
          },
        ),
      ),
    );
  }

  Future<void> _updateItem(Item item) async {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx >= 0) _items[idx] = item;
    });
    await _saveItems();
  }

  Future<void> _openDetail(Item item) async {
    final updated = await Navigator.of(context).push<Item>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(
          item: item,
          initialCategory: item.category,
          onDelete: () => _deleteItem(item),
        ),
      ),
    );
    if (updated == null) return;
    setState(() {
      final idx = _items.indexWhere((i) => i.id == updated.id);
      if (idx >= 0) _items[idx] = updated;
    });
    await _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: const Text('行動整理'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs
              .map((c) => Tab(text: c.displayName))
              .toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((category) => _ItemListView(
                        items: _items
                            .where((i) => i.category == category)
                            .toList(),
                        category: category,
                        onTap: _openDetail,
                        onDelete: _deleteItem,
                        onUpdate: _updateItem,
                      ))
                  .toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddForm,
        tooltip: 'アイテムを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ItemListView extends StatelessWidget {
  final List<Item> items;
  final ItemCategory category;
  final void Function(Item) onTap;
  final void Function(Item) onDelete;
  final void Function(Item) onUpdate;

  const _ItemListView({
    required this.items,
    required this.category,
    required this.onTap,
    required this.onDelete,
    required this.onUpdate,
  });

  Future<void> _showAchievementDialog(BuildContext context, Item item) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('達成したことを記録'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '何を達成しましたか？',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setDialogState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: const Text('記録する (+20 XP)'),
            ),
          ],
        ),
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (confirmed != true || !context.mounted) return;

    final now = DateTime.now();
    final entry = '[${now.month}/${now.day}] $text';
    final newMemo = (item.memo == null || item.memo!.isEmpty)
        ? entry
        : '${item.memo}\n$entry';
    final newItem = item.copyWith(
      xp: item.xp + 20,
      memo: newMemo,
      updatedAt: now,
    );
    onUpdate(newItem);

    if (!context.mounted) return;
    if (newItem.hobbyRankName != item.hobbyRankName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} が ${newItem.hobbyRankName} Lv.${newItem.hobbyLevel} に昇進しました！',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} の達成を記録しました！ +20 XP')),
      );
    }
  }

  Widget _buildListTile(BuildContext context, Item item) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (item.category) {
      case ItemCategory.routine:
        final done = item.isDoneToday;
        return ListTile(
          leading: Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? colorScheme.primary : colorScheme.outline,
          ),
          title: Text(
            item.count > 0 ? '${item.title}  ×${item.count}' : item.title,
          ),
          onTap: () => onUpdate(
            done
                ? item.copyWith(resetLastDoneDate: true)
                : item.copyWith(lastDoneDate: DateTime.now()),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => onTap(item),
          ),
        );

      case ItemCategory.task:
        return ListTile(
          leading: Icon(
            item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
            color: item.isDone ? colorScheme.primary : colorScheme.outline,
          ),
          title: Text(
            item.title,
            style: item.isDone
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: colorScheme.outline,
                  )
                : null,
          ),
          onTap: () => onUpdate(item.copyWith(isDone: !item.isDone)),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => onTap(item),
          ),
        );

      case ItemCategory.hobby:
        final level = item.hobbyLevel;
        final isMax = item.isHobbyAtMax;
        final levelLabel = isMax ? 'Lv.999+' : 'Lv.$level';
        final xpLabel = isMax ? '' : '  ${item.hobbyXpInLevel}/100 XP';
        return ListTile(
          title: Text(item.title),
          subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.hobbyRankName}  $levelLabel$xpLabel'),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: isMax ? 1.0 : item.hobbyXpInLevel / 100,
                  ),
                ],
              ),
          onTap: isMax
              ? null
              : () {
                  final newItem = item.copyWith(
                    xp: item.xp + 10,
                    updatedAt: DateTime.now(),
                  );
                  onUpdate(newItem);
                  if (newItem.hobbyRankName != item.hobbyRankName) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${item.title} が ${newItem.hobbyRankName} Lv.${newItem.hobbyLevel} に昇進しました！',
                        ),
                      ),
                    );
                  }
                },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMax)
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  tooltip: '達成したことを記録 (+20 XP)',
                  onPressed: () => _showAchievementDialog(context, item),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '編集',
                onPressed: () => onTap(item),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'アイテムがありません',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 4),
            Text(
              '右下の＋ボタンで追加できます',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) => _buildListTile(context, items[index]),
    );
  }
}

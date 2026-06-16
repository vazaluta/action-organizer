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

  Future<void> _showProgressDialog(BuildContext context, Item item) async {
    double progress = item.progress.toDouble();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(item.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('進捗: ${progress.round()}%'),
              Slider(
                value: progress,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${progress.round()}%',
                onChanged: (v) => setDialogState(() => progress = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                onUpdate(item.copyWith(progress: progress.round()));
                Navigator.of(ctx).pop();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, Item item) {
    switch (item.category) {
      case ItemCategory.routine:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.count}回',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'カウント',
              onPressed: () => onUpdate(item.copyWith(count: item.count + 1)),
            ),
          ],
        );
      case ItemCategory.task:
        return const Icon(Icons.chevron_right);
      case ItemCategory.hobby:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.progress}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(
                  width: 48,
                  child: LinearProgressIndicator(
                    value: item.progress / 100,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: '進捗を更新',
              onPressed: () => _showProgressDialog(context, item),
            ),
          ],
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
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        final doneToday = item.isDoneToday;
        final taskDone = item.isDone;

        Widget? leading;
        if (item.category == ItemCategory.routine) {
          leading = Checkbox(
            value: doneToday,
            onChanged: (_) => onUpdate(
              doneToday
                  ? item.copyWith(resetLastDoneDate: true)
                  : item.copyWith(lastDoneDate: DateTime.now()),
            ),
          );
        } else if (item.category == ItemCategory.task) {
          leading = Checkbox(
            value: taskDone,
            onChanged: (_) => onUpdate(item.copyWith(isDone: !taskDone)),
          );
        }

        final titleStyle =
            (item.category == ItemCategory.routine && doneToday) ||
                    (item.category == ItemCategory.task && taskDone)
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Theme.of(context).colorScheme.outline,
                  )
                : null;

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Theme.of(context).colorScheme.error,
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          onDismissed: (_) => onDelete(item),
          child: ListTile(
            leading: leading,
            title: Text(item.title, style: titleStyle),
            subtitle: item.memo != null && item.memo!.isNotEmpty
                ? Text(
                    item.memo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: _buildTrailing(context, item),
            onTap: () => onTap(item),
          ),
        );
      },
    );
  }
}

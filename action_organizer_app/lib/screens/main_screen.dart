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

  Widget _buildChip(BuildContext context, Item item) {
    Widget? avatar;
    String labelText = item.title;
    bool selected = false;
    VoidCallback? onPressed;

    switch (item.category) {
      case ItemCategory.routine:
        final done = item.isDoneToday;
        avatar = Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
        );
        if (item.count > 0) labelText = '${item.title}  ×${item.count}';
        selected = done;
        onPressed = () => onUpdate(
              done
                  ? item.copyWith(resetLastDoneDate: true)
                  : item.copyWith(lastDoneDate: DateTime.now()),
            );
        break;
      case ItemCategory.task:
        avatar = Icon(
          item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
          size: 18,
        );
        selected = item.isDone;
        onPressed = () => onUpdate(item.copyWith(isDone: !item.isDone));
        break;
      case ItemCategory.hobby:
        final level = item.hobbyLevel;
        final levelLabel = item.isHobbyAtMax ? 'Lv.999+' : 'Lv.$level';
        if (level > 0 || item.isHobbyAtMax) {
          labelText = '${item.title}  ${item.hobbyRankName}  $levelLabel';
        }
        onPressed = item.isHobbyAtMax
            ? null
            : () {
                final newItem = item.copyWith(
                  count: item.count + 1,
                  updatedAt: DateTime.now(),
                );
                onUpdate(newItem);
                if (newItem.hobbyRankName != item.hobbyRankName) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${item.title} が ${newItem.hobbyRankName} に昇進しました！',
                      ),
                    ),
                  );
                }
              };
        break;
    }

    return GestureDetector(
      onLongPress: () => onTap(item),
      child: InputChip(
        avatar: avatar,
        label: Text(labelText),
        selected: selected,
        onPressed: onPressed,
        onDeleted: () => onDelete(item),
        deleteIcon: const Icon(Icons.close, size: 16),
      ),
    );
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) => _buildChip(context, item)).toList(),
      ),
    );
  }
}

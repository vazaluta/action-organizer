import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/storage_service.dart';
import 'item_detail_screen.dart';
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

  Future<void> _openDetail(Item item) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item),
      ),
    );
    if (result == null) return;

    if (result['action'] == 'delete') {
      setState(() => _items.removeWhere((i) => i.id == item.id));
      await _saveItems();
    } else if (result['action'] == 'update') {
      final updated = result['item'] as Item;
      setState(() {
        final idx = _items.indexWhere((i) => i.id == updated.id);
        if (idx >= 0) _items[idx] = updated;
      });
      await _saveItems();
    }
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
                        onTap: _openDetail,
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
  final void Function(Item) onTap;

  const _ItemListView({required this.items, required this.onTap});

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
        return ListTile(
          title: Text(item.title),
          subtitle: item.memo != null && item.memo!.isNotEmpty
              ? Text(
                  item.memo!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onTap(item),
        );
      },
    );
  }
}

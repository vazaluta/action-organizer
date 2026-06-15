import 'package:flutter/material.dart';
import '../models/item.dart';
import 'item_form_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${item.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop({'action': 'delete', 'item': item});
    }
  }

  Future<void> _openEdit(BuildContext context) async {
    final updated = await Navigator.of(context).push<Item>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(
          item: item,
          initialCategory: item.category,
        ),
      ),
    );
    if (updated != null && context.mounted) {
      Navigator.of(context).pop({'action': 'update', 'item': updated});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細'),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '編集',
            onPressed: () => _openEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '削除',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CategoryChip(category: item.category),
          const SizedBox(height: 12),
          Text(item.title, style: textTheme.headlineSmall),
          if (item.memo != null && item.memo!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('メモ', style: textTheme.labelMedium?.copyWith(color: colorScheme.outline)),
            const SizedBox(height: 4),
            Text(item.memo!, style: textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          _DateRow(label: '作成日時', date: _formatDate(item.createdAt)),
          const SizedBox(height: 4),
          _DateRow(label: '更新日時', date: _formatDate(item.updatedAt)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ItemCategory category;

  const _CategoryChip({required this.category});

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (category) {
      case ItemCategory.routine:
        return cs.primaryContainer;
      case ItemCategory.task:
        return cs.secondaryContainer;
      case ItemCategory.hobby:
        return cs.tertiaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(category.displayName),
      backgroundColor: _color(context),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String date;

  const _DateRow({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label, style: textTheme.labelMedium?.copyWith(color: colorScheme.outline)),
        const SizedBox(width: 8),
        Text(date, style: textTheme.bodySmall),
      ],
    );
  }
}

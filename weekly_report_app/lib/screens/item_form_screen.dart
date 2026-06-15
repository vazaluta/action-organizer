import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item;
  final ItemCategory initialCategory;

  const ItemFormScreen({
    super.key,
    this.item,
    required this.initialCategory,
  });

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _memoController;
  late ItemCategory _selectedCategory;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _memoController = TextEditingController(text: widget.item?.memo ?? '');
    _selectedCategory = widget.item?.category ?? widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final item = _isEditing
        ? widget.item!.copyWith(
            title: _titleController.text.trim(),
            category: _selectedCategory,
            memo: _memoController.text.trim().isEmpty
                ? null
                : _memoController.text.trim(),
            updatedAt: now,
          )
        : Item(
            id: const Uuid().v4(),
            title: _titleController.text.trim(),
            category: _selectedCategory,
            memo: _memoController.text.trim().isEmpty
                ? null
                : _memoController.text.trim(),
            createdAt: now,
            updatedAt: now,
          );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'アイテムを編集' : 'アイテムを追加'),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'アイテム名 *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'アイテム名を入力してください' : null,
            ),
            const SizedBox(height: 16),
            const Text('カテゴリ'),
            const SizedBox(height: 8),
            SegmentedButton<ItemCategory>(
              segments: ItemCategory.values
                  .map((c) => ButtonSegment(
                        value: c,
                        label: Text(c.displayName),
                      ))
                  .toList(),
              selected: {_selectedCategory},
              onSelectionChanged: (s) =>
                  setState(() => _selectedCategory = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memoController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

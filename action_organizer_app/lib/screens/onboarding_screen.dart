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
  final _pageController = PageController();
  int _currentPage = 0;
  final Set<String> _selected = {};

  static const _pages = [
    ItemCategory.routine,
    ItemCategory.task,
    ItemCategory.hobby,
  ];

  static const _candidates = {
    ItemCategory.routine: [
      '朝の運動', 'ストレッチ', '瞑想', '読書', '日記を書く', '早起き',
      'ヨガ', 'ウォーキング', 'ランニング', '筋トレ', '朝食を食べる',
      '歯磨き（夜）', 'スキンケア', 'ビタミン摂取', '水を2L飲む',
      '勉強', '英語の勉強', 'ニュースを読む', 'SNSチェック', 'メール確認',
      'スケジュール確認', '感謝日記', '深呼吸', '冷水シャワー',
      'ベッドメイキング', '体重測定', '睡眠記録', '1日の振り返り',
      '読んだページ数を記録', '間食しない',
    ],
    ItemCategory.task: [
      '部屋の掃除', '洗濯', '買い物', '書類整理', 'メールの返信',
      '請求書の支払い', '窓拭き', '冷蔵庫の整理', 'クローゼット整理',
      '不用品の処分', '銀行の手続き', '確定申告', '保険の見直し',
      '車のメンテナンス', '歯医者の予約', '健康診断', 'プレゼントを用意',
      '資料作成', '会議の準備', '連絡を返す', 'SNSの整理',
      'パスワードの更新', 'データのバックアップ', 'アプリの整理',
      '写真の整理', '植物に水をやる', '本の返却', '引き出しの整理',
      'ゴミ出しの確認', '薬の補充',
    ],
    ItemCategory.hobby: [
      'ゲーム', '映画・ドラマ', '料理', '音楽を聴く', '散歩',
      'イラストを描く', '読書', '旅行・外出', '写真を撮る', '手芸・編み物',
      '釣り', 'ガーデニング', '楽器を弾く', '歌う', 'ダンス',
      'ボードゲーム', 'アニメを観る', '漫画を読む', 'カラオケ', 'キャンプ',
      'サイクリング', '水泳', 'テニス', 'サッカー', '将棋・チェス',
      'パズル', 'ミニチュア作り', '陶芸', 'カリグラフィー', '美術館巡り',
    ],
  };

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

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _back() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _StepDots(current: _currentPage, total: _pages.length),
            const SizedBox(height: 4),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final cat = _pages[index];
                  return _CategoryPage(
                    category: cat,
                    candidates: _candidates[cat]!,
                    isSelected: (t) => _isSelected(cat, t),
                    onToggle: (t) => _toggle(cat, t),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Row(
                children: [
                  if (isFirst)
                    TextButton(
                      onPressed: () => widget.onComplete([]),
                      child: const Text('スキップ'),
                    )
                  else
                    TextButton.icon(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('戻る'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      isLast
                          ? (_selected.isEmpty ? '始める' : '始める（${_selected.length}件）')
                          : '次へ',
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

class _StepDots extends StatelessWidget {
  final int current;
  final int total;

  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: active ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? colorScheme.primary : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _CategoryPage extends StatelessWidget {
  final ItemCategory category;
  final List<String> candidates;
  final bool Function(String) isSelected;
  final void Function(String) onToggle;

  const _CategoryPage({
    required this.category,
    required this.candidates,
    required this.isSelected,
    required this.onToggle,
  });

  String _subtitle() {
    switch (category) {
      case ItemCategory.routine:
        return '毎日続けたいことを選んでください';
      case ItemCategory.task:
        return 'やっておきたいことを選んでください';
      case ItemCategory.hobby:
        return '楽しんでいることを選んでください';
    }
  }

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = _accentColor(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category.displayName,
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle(),
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: candidates
                .map((title) => FilterChip(
                      label: Text(title),
                      selected: isSelected(title),
                      onSelected: (_) => onToggle(title),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

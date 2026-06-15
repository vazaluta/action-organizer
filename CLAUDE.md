# action-organizer プロジェクトルール

## ブランチ・開発フロー

1. 作業は必ず **feature ブランチ**で行う
2. `master` への直接 push は禁止
3. 変更は **Pull Request を作成してからマージ**する

```
feature ブランチ作成
→ 変更・commit・push
→ PR 作成
→ マージ
→ ブランチ削除
```

## ブランチ命名規則

```
feature/<作業内容>
例: feature/add-copy-button
```

## コミットメッセージ

日本語で簡潔に記述する。

```
例: コピーボタンを追加
例: テキスト選択機能を追加
```

## プロジェクト構成

```
action-organizer/
├── .github/workflows/deploy.yml  # GitHub Actions（masterへのpushで自動デプロイ）
└── action_organizer_app/         # Flutter アプリ
    └── lib/main.dart             # メインコード
```

## デプロイ

- `master` に merge されると GitHub Actions が自動で Flutter Web をビルド
- GitHub Pages に自動デプロイされる
- URL: https://vazaluta.github.io/action-organizer/

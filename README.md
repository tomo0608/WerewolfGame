# 人狼ゲーム (WerewolfGame)

対面で遊ぶための人狼ゲーム進行アプリです。GM（ゲームマスター）なしで、端末1台を回しながらプレイできます。

## 機能

- 夜フェーズ：端末を順番に回して各自の役職確認・アクション選択
- 昼フェーズ：議論タイマー・投票（一括/個別モード）・処刑
- 勝利判定の自動処理
- ゲーム履歴の保存・閲覧

## 対応役職（11種）

| 村人陣営 | 人狼陣営 | 妖狐陣営 |
|---------|---------|---------|
| 村人 | 人狼 | 妖狐 |
| 占い師 | 狂人 | 背徳者 |
| 偽占い師 | 狂信者 | |
| 霊媒師 | | |
| 騎士 | | |
| 猫又 | | |

## 動作環境

- iOS 17+
- Xcode 16+

## ビルド

```bash
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## テスト

```bash
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## アーキテクチャ

SwiftUI + MVVM（`@Observable`）

```
WerewolfGame/
├── Models/          # ゲームロジック（GameManager, RoleType, Player等）
├── ViewModels/      # GameViewModel
└── Views/           # フェーズごとのSwiftUI View
    ├── Setup/       # 初期設定・役職設定・確認
    ├── Night/       # 夜フェーズ
    ├── Day/         # 昼フェーズ（議論・投票）
    ├── GameOver/    # ゲーム終了
    └── History/     # ゲーム履歴
```

## ライセンス

MIT

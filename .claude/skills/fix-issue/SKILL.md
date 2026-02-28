---
name: fix-issue
description: GitHub Issue番号を受け取り、調査→実装→テスト→コミット→PR作成まで行う。Issue修正やバグ修正の依頼時に使用。
disable-model-invocation: true
argument-hint: "[issue番号]"
---

GitHub Issue #$ARGUMENTS を修正し、PRを作成する。

## 手順

### 1. Issue の内容を確認

```bash
gh issue view $ARGUMENTS
```

Issue のタイトル、本文、ラベルを読み取り、何をすべきか把握する。

### 2. ブランチを作成

Issue 番号とタイトルからブランチ名を決める。

```bash
git checkout -b fix/$ARGUMENTS-<簡潔な説明>
```

### 3. 関連コードの調査

Issue の内容に応じて関連ファイルを特定する。主要な変更対象：

| 変更の種類 | 主な対象ファイル |
|-----------|----------------|
| ゲームロジックバグ | `WerewolfGame/Models/GameManager.swift` |
| 役職の問題 | `WerewolfGame/Models/RoleType.swift` |
| プレイヤーモデル | `WerewolfGame/Models/Player.swift` |
| 型定義の追加・変更 | `WerewolfGame/Models/GameTypes.swift` |
| 設定・構成 | `WerewolfGame/Models/GameSettings.swift` |
| ViewModel・状態管理 | `WerewolfGame/ViewModels/GameViewModel.swift` |
| セットアップ画面 | `WerewolfGame/Views/InitialSetupView.swift`, `RoleSetupView.swift`, `ConfirmSetupView.swift` |
| 夜フェーズ画面 | `WerewolfGame/Views/NightPhaseView.swift` |
| 昼フェーズ画面 | `WerewolfGame/Views/DayPhaseView.swift` |
| ゲーム終了画面 | `WerewolfGame/Views/GameOverView.swift` |
| 履歴画面 | `WerewolfGame/Views/GameHistoryView.swift`, `GameHistoryDetailView.swift` |

### 4. 修正を実装

- 既存のコードパターンに従う
- MVVM パターンを維持：ロジックは Model 層、UI状態は ViewModel、表示は View
- UI文字列はすべて日本語
- コード識別子とコメントは英語

### 5. テストを書く・更新する

テストファイル: `WerewolfGameTests/GameManagerTests.swift`, `PlayerTests.swift`, `RoleTypeTests.swift`

テストヘルパー関数：
```swift
// デフォルト5人のGMを作成
private func makeGM(_ names: [String]? = nil) -> GameManager

// 名前と役職のペアからGMを作成（最も便利）
private func makeGMWithRoles(_ roles: [(String, RoleType)]) -> GameManager

// 既存GMのプレイヤーに役職を直接設定
private func assignFixedRoles(_ gm: GameManager, roles: [(String, RoleType)])
```

テストのパターン例：
```swift
func testNewFeature() {
    let gm = makeGMWithRoles([
        ("Alice", .seer),
        ("Bob", .werewolf),
        ("Charlie", .villager),
    ])

    // テストロジック
    let result = gm.resolveNightActions(actions)
    XCTAssertEqual(result.victims.count, 1)
}
```

### 6. ビルド・テスト実行

```bash
# ビルド確認
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# 全テスト
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# 関連テストのみ
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WerewolfGameTests/<TestClass> test
```

### 7. コミット・PR作成

- コミットメッセージは変更内容を端的に記述
- PR本文に Issue 番号を `Closes #$ARGUMENTS` で参照
- PR のラベルは Issue と同じものを付与
- `/create-issue` スキルのラベル体系に従う

```bash
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary
...

Closes #$ARGUMENTS

## Test plan
...

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

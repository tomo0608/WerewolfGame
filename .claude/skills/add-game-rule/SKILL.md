---
name: add-game-rule
description: 新しいハウスルール（オプションルール）を追加する。GameSettings、GameManager、設定UI、テストを一貫して変更する。
disable-model-invocation: true
argument-hint: "[ルール名]"
---

新しいハウスルール「$ARGUMENTS」を追加する。

## 前提知識

ハウスルール基盤は構築済み：
- `GameSettings.swift` に `HouseRules` 構造体（`Codable`, `Equatable`）が定義されている
- `GameManager` は `let houseRules: HouseRules` を `init` で受け取る
- `GameViewModel` が `var houseRules = HouseRules()` を保持し、`startGame()` で `GameManager` に渡す
- テストヘルパー `makeGM()` / `makeGMWithRoles()` は `houseRules` パラメータを受け取れる

## 変更対象ファイル

### 1. `WerewolfGame/Models/GameSettings.swift` — ルール設定の定義

`HouseRules` 構造体にプロパティを追加する：

```swift
struct HouseRules: Codable, Equatable {
    var consecutiveGuardEnabled: Bool = true   // 連続ガード許可（デフォルト: 許可）
    // ...新しいルールをここに追加
}
```

設定値の命名規則：
- Bool 型: `xxxEnabled`（true = 機能ON）
- 数値型: そのまま（例: `discussionMinutes: Int`）
- デフォルト値は「最も一般的な遊び方」に合わせる
- `Codable` と `Equatable` の準拠は自動合成されるため、保持プロパティがこれらに準拠していれば追加作業不要

### 2. `WerewolfGame/Models/GameManager.swift` — ルールロジック

`GameManager` は既に `let houseRules: HouseRules` を保持している。ルールが影響する処理にロジックを追加する：

| ルールの種類 | 影響する処理 |
|-------------|-------------|
| 襲撃関連 | `resolveNightActions()` の攻撃解決部分 |
| ガード関連 | `resolveNightActions()` のガード判定部分 |
| 投票・処刑関連 | `executeDayVote()` |
| 勝利条件関連 | `checkVictory()` |
| 占い関連 | `resolveNightActions()` の占い処理部分 |

条件分岐パターン：
```swift
// 例: 連続ガード禁止
if houseRules.consecutiveGuardEnabled || lastGuardTarget != target {
    guardTargets.insert(target)
}
```

### 3. `WerewolfGame/ViewModels/GameViewModel.swift` — 状態管理

`GameViewModel` は既に `var houseRules = HouseRules()` を保持し、`startGame()` で `GameManager` に渡し、`resetGame()` でリセットしている。通常は変更不要。

ルールがゲーム中のUI状態に影響する場合（例: 投票フローの変更）のみ、関連するメソッドを調整する。

### 4. 設定UI — ルール設定画面

設定場所の候補（プロジェクトの構成に合わせて判断）：
- `RoleSetupView.swift` にセクション追加（役職設定と同じ画面）
- 新しい `HouseRulesView.swift` を作成（設定が多い場合）

UI パターン：
```swift
// Bool ルール → Toggle
Toggle("連続ガード禁止", isOn: $viewModel.houseRules.consecutiveGuardEnabled)

// 数値ルール → Stepper or Picker
Stepper("議論時間: \(viewModel.houseRules.discussionMinutes)分",
        value: $viewModel.houseRules.discussionMinutes, in: 1...10)

// 選択肢ルール → Picker
Picker("投票方式", selection: $viewModel.houseRules.votingStyle) {
    Text("一括投票").tag(VotingStyle.batch)
    Text("個別投票").tag(VotingStyle.individual)
}
```

UIテキストはすべて日本語。ルール名の下に簡潔な説明テキストを添える。

### 5. テスト追加

`WerewolfGameTests/GameManagerTests.swift` にテスト追加。

ルールON/OFFの両方のケースをテストする：

```swift
func testNewRuleEnabled() {
    var rules = HouseRules()
    rules.newRule = true
    let gm = makeGMWithRoles([...], houseRules: rules)
    // ルール適用時の動作を確認
}

func testNewRuleDisabled() {
    let gm = makeGMWithRoles([...])  // デフォルトの HouseRules が使われる
    // ルール無効時は従来通りの動作を確認
}
```

テストヘルパー `makeGM()` / `makeGMWithRoles()` は既に `houseRules` パラメータ（デフォルト値付き）を受け取れる。

### 6. ビルド・テスト

```bash
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## よくあるハウスルール例

| ルール | 設定型 | 影響箇所 |
|--------|--------|---------|
| 連続ガード禁止 | Bool | resolveNightActions（前回のガード対象を記憶） |
| 決選投票 | Bool | executeDayVote（同数時に再投票） |
| 初日占い | Bool | 夜フェーズ（turn 1 の占い師アクション可否）※現在は占い師 turn 1 有効 |
| 仲間認識 | Bool | 夜フェーズ（人狼同士が互いを認識するか） |
| 平和な村（初日襲撃なし） | Bool | resolveNightActions（turn 1 の攻撃スキップ） |
| 引き分け判定 | Bool | checkVictory（特定条件で引き分け） |
| 役職欠け | Bool | startGame（一部役職を墓地に送る） |

## チェックリスト

- [ ] HouseRules にプロパティを追加（デフォルト値付き）
- [ ] GameManager の該当ロジックに `houseRules` 参照の条件分岐を追加
- [ ] 設定UIを追加（Toggle/Stepper/Picker）
- [ ] ルールON/OFF両方のテストを追加
- [ ] 既存テストが壊れていないことを確認（デフォルト値で従来動作が維持されること）
- [ ] ビルド成功、全テスト通過

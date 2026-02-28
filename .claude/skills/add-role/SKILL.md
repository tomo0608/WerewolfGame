---
name: add-role
description: 新しい人狼ゲームの役職を追加する。RoleType、GameManager、GameSettings、View、テストを一貫して変更する。
disable-model-invocation: true
argument-hint: "[役職名(英語)]"
---

新しい役職 `$ARGUMENTS` を追加する。以下のファイルを順に変更する。

## 変更対象ファイル（順序が重要）

### 1. `WerewolfGame/Models/RoleType.swift` — 役職定義

`RoleType` enum に新しい case を追加し、全プロパティを実装する。

```swift
enum RoleType: String, CaseIterable, Codable {
    // 既存の case の後に追加
    case newRole = "日本語名"
}
```

実装すべきプロパティ（既存の switch 文すべてに case を追加）：

| プロパティ | 型 | 説明 |
|-----------|---|------|
| `rawValue` | String | 日本語の役職名（UI表示用） |
| `team` | Team | `.villager`, `.werewolf`, `.fox` のいずれか |
| `species` | Species | `.villager`, `.werewolf`, `.fox`（勝利判定のカウントに使用） |
| `seerResult` | SeerResult | 占い結果: `.villager` or `.werewolf` |
| `mediumResult` | MediumResult | 霊媒結果: `.notWerewolf` or `.werewolf` |
| `actionDescription` | String? | 夜アクションの説明（nil = アクションなし） |
| `displayName` | String | 表示名（通常は rawValue と同じ。偽占い師のように偽装が必要な場合のみ変更） |
| `hasNightAction(turn:)` | Bool | ターンごとのアクション可否。占い師は turn 1 から、人狼・騎士は turn 2 から |

### 2. `WerewolfGame/Models/GameTypes.swift` — 必要に応じて型追加

新しい死因や ActionType が必要な場合のみ変更。

既存の ActionType: `seer`, `attack`, `guard`, `medium`, `none`
既存の DeathReason: `attack`, `execute`, `curse`, `suicide`, `retaliation`

新しい ActionType を追加した場合は `displayName` も実装する。

### 3. `WerewolfGame/Models/GameManager.swift` — ゲームロジック

夜アクションがある役職の場合、`resolveNightActions()` に処理を追加：

```swift
func resolveNightActions(_ nightActions: [String: NightAction]) -> NightResult {
    // 1. アクションを種類別に分類
    // 2. 各アクションタイプの処理（ここに新役職のロジックを追加）
    // 3. 襲撃解決
    // 4. 特殊死亡処理（猫又道連れ、背徳者後追い等）
}
```

勝利条件に影響する場合は `checkVictory()` も変更：
- species が `.villager` / `.werewolf` / `.fox` のどれかで自動的にカウントされる
- 特殊な勝利条件が必要な場合のみ checkVictory() を変更

特殊死亡メカニクスがある場合（猫又の道連れ、背徳者の後追いのようなもの）：
- `resolveNightActions()` と `executeDayVote()` の両方に処理を追加
- 夜と昼（処刑時）の両方で発動するか確認

### 4. `WerewolfGame/Models/GameSettings.swift` — デフォルト設定

`defaultRoleCounts` に新役職を追加（通常は 0）：

```swift
static let defaultRoleCounts: [RoleType: Int] = [
    // ...既存の役職...
    .newRole: 0,
]
```

### 5. `WerewolfGame/ViewModels/GameViewModel.swift` — ViewModel

夜アクションがある役職の場合：
- `confirmNightAction()` でアクション結果の生成ロジックを追加
- 対象選択のフィルタリングが特殊な場合は調整

### 6. `WerewolfGame/Views/NightPhaseView.swift` — 夜画面

夜アクションがある役職の場合：
- `ActionSelectContent` に対象選択UIを追加（特殊なフィルタリングが必要な場合）
- `ActionResultContent` にアクション結果の表示を追加

既存パターン：
- 人狼: 自チーム以外から選択
- 占い師/偽占い師: 自分以外から選択
- 騎士: 自分以外から選択

### 7. `WerewolfGame/Views/DayPhaseView.swift` — 昼画面

特殊死亡がある場合、夜結果表示セクションに追加。
処刑時の特殊効果がある場合、処刑結果表示セクションに追加。

### 8. テスト追加

#### `WerewolfGameTests/RoleTypeTests.swift`

新役職の属性テスト（既存テストのパターンに従う）：

```swift
func testNewRole() {
    let role = RoleType.newRole
    XCTAssertEqual(role.rawValue, "日本語名")
    XCTAssertEqual(role.team, .expectedTeam)
    XCTAssertEqual(role.species, .expectedSpecies)
    XCTAssertEqual(role.seerResult, .expected)
    XCTAssertEqual(role.mediumResult, .expected)
    XCTAssertEqual(role.actionDescription, "...")  // or XCTAssertNil
    XCTAssertFalse(role.hasNightAction(turn: 1))   // or True
    XCTAssertTrue(role.hasNightAction(turn: 2))     // or False
    XCTAssertEqual(role.displayName, "日本語名")
}
```

#### `WerewolfGameTests/GameManagerTests.swift`

夜アクション・特殊能力のテスト：

```swift
func testNewRoleNightAction() {
    let gm = makeGMWithRoles([
        ("Alice", .newRole),
        ("Bob", .werewolf),
        ("Charlie", .villager),
        // 必要なプレイヤー
    ])

    let actions: [String: NightAction] = [
        "Alice": NightAction(type: .newType, target: "Bob"),
        "Bob": NightAction(type: .attack, target: "Charlie"),
        "Charlie": NightAction(type: .none, target: nil),
    ]

    let result = gm.resolveNightActions(actions)
    // 期待される結果をアサート
}
```

特殊死亡がある場合はそのテストも追加（猫又テストのパターンを参考に）。

### 9. ビルド・テスト

```bash
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## チェックリスト

- [ ] RoleType に case 追加、全 switch 文を網羅
- [ ] GameTypes に必要な型を追加（ActionType, DeathReason 等）
- [ ] GameManager の夜アクション解決に処理追加
- [ ] GameManager の処刑処理に特殊効果追加（該当する場合）
- [ ] GameManager の勝利判定に変更（該当する場合）
- [ ] GameSettings のデフォルト設定に追加
- [ ] GameViewModel のアクション処理に追加
- [ ] NightPhaseView の対象選択・結果表示に追加
- [ ] DayPhaseView の結果表示に追加（該当する場合）
- [ ] RoleTypeTests に属性テスト追加
- [ ] GameManagerTests にロジックテスト追加
- [ ] ビルド成功、全テスト通過

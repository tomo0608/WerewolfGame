---
name: review-pr
description: PRをレビューする。コード品質、ゲームルールの整合性、テストカバレッジ、MVVM準拠を確認する。
disable-model-invocation: true
argument-hint: "[PR番号]"
---

PR #$ARGUMENTS をレビューする。

## 手順

### 1. PR の内容を取得

```bash
gh pr view $ARGUMENTS
gh pr diff $ARGUMENTS
```

### 2. レビュー観点

以下の観点でコードを確認し、問題があればコメントする。

#### A. ゲームルールの整合性（最重要）

人狼ゲーム特有のロジックが正しいか確認：

**勝利条件:**
- Fox チームは「狼が全滅 OR 狼が村人以上」のどちらでも、狐が生存していれば勝利（他チームに優先）
- 人狼チームは `species == .werewolf` の数 >= `species == .villager` の数で勝利
- 村人チームは `species == .werewolf` と `species == .fox` が全滅で勝利
- 勝利判定は **species**（種族）でカウント。team（陣営）ではない。狂人・狂信者は species が villager

**特殊死亡チェーン:**
- 猫又: 襲撃死 → ランダムな人狼1体を道連れ。処刑死 → ランダムな生存者1人を道連れ
- 背徳者: 最後の妖狐が死亡（呪殺・処刑問わず） → 全生存背徳者が後追い自殺
- 占い師の呪殺: 妖狐のみ対象。騎士のガードでは防げない
- ガード: 襲撃のみ防ぐ。呪殺・処刑・道連れは防げない

**チェーンの発動順序（夜）:**
1. 占い師の呪殺処理
2. ガード判定
3. 襲撃解決（ガードで防げるか判定）
4. 猫又の道連れ（襲撃された場合）
5. 背徳者の後追い（最後の狐が死んだ場合）

**チェーンの発動順序（昼・処刑）:**
1. 処刑実行
2. 猫又の道連れ（処刑された場合）
3. 背徳者の後追い（処刑されたのが最後の狐の場合）

#### B. MVVM アーキテクチャ準拠

| レイヤー | 責務 | やってはいけないこと |
|---------|------|-------------------|
| Models (`Models/`) | 純粋なゲームロジック | UIKit/SwiftUI の import、View への依存 |
| ViewModel (`GameViewModel`) | UI状態管理、Model と View の橋渡し | 直接的な View 描画ロジック |
| Views (`Views/`) | 表示とユーザー入力 | ゲームロジックの直接実装 |

- `GameManager` に UI 関連のコードが混入していないか
- `View` にゲームロジック（勝利判定、アクション解決等）が直接書かれていないか
- `GameViewModel` が適切に `GameManager` のメソッドを呼んでいるか

#### C. コード品質

- Swift の慣例に従っているか（命名規則、guard/if let の使い分け）
- `@Observable` マクロの正しい使用（iOS 17+）
- Optional の安全な扱い（force unwrap の回避）
- switch 文の網羅性（RoleType の全 case をカバー）
- `CaseIterable` 対応が壊れていないか

#### D. テストカバレッジ

- 新しいロジックにテストがあるか
- エッジケースのテスト:
  - 猫又が道連れする対象がいない場合
  - 投票が同数の場合
  - 妖狐がガードされている+占われた場合
  - 全員同じ対象に投票した場合
- テストヘルパー (`makeGM`, `makeGMWithRoles`, `assignFixedRoles`) が適切に使われているか
- テストが独立しており、他のテストに依存していないか

#### E. UI/UX（View 変更がある場合）

- テキストがすべて日本語か
- 役職名は `displayName` を使用しているか（偽占い師が「占い師」と表示されるため）
- アクセシビリティへの配慮

#### F. 型安全性

- `GameTypes.swift` の型（Team, Species, DeathReason, ActionType 等）が正しく使われているか
- 新しい enum case が追加された場合、既存の switch 文が全て更新されているか
- Codable 準拠が壊れていないか（ゲーム結果の保存に影響）

### 3. レビューコメント投稿

```bash
gh pr review $ARGUMENTS --comment --body "レビュー内容"
```

問題の深刻度を明示：
- **MUST**: 修正必須（ゲームルールの誤り、クラッシュ、データ不整合）
- **SHOULD**: 強く推奨（テスト不足、アーキテクチャ違反）
- **NIT**: 些末（命名、フォーマット）

問題がなければ approve する：
```bash
gh pr review $ARGUMENTS --approve --body "LGTM 👍"
```

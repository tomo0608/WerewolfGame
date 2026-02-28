import SwiftUI

struct NightPhaseView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        Group {
            if let player = viewModel.currentNightPlayer {
                playerActionView(player: player)
            } else {
                nightCompleteView
            }
        }
        .navigationTitle("ターン \(viewModel.gameManager?.turn ?? 1): 夜")
    }

    // MARK: - 全員完了画面

    private var nightCompleteView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundStyle(.indigo)
            Text("全員の夜のアクションが完了しました。")
                .font(.headline)
            Spacer()
        }
        .padding()
    }

    // MARK: - プレイヤーアクション画面

    @ViewBuilder
    private func playerActionView(player: Player) -> some View {
        switch viewModel.nightPlayerState {
        case .handoff:
            handoffView(player: player)
        case .roleReveal:
            roleRevealView(player: player)
        case .actionSelect:
            actionSelectView(player: player)
        case .actionResult:
            actionResultView(player: player)
        case .done:
            doneView(player: player)
        }
    }

    // MARK: - 1. 引き渡し画面

    private func handoffView(player: Player) -> some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "person.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("次は \(player.name) さんの番です")
                .font(.title2)
                .fontWeight(.bold)
            Text("端末を渡してください")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("他の人は見ないでください！")
                .foregroundStyle(.red)
                .fontWeight(.semibold)
            Button("準備完了") {
                viewModel.nightPlayerState = .roleReveal
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .padding()
    }

    // MARK: - 2. 役職確認画面

    private func roleRevealView(player: Player) -> some View {
        VStack(spacing: 20) {
            Text("\(player.name) さん")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.roleRevealed {
                VStack(spacing: 12) {
                    Text("あなたの役職は")
                        .font(.headline)
                    Text(player.role.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text("です。")
                        .font(.headline)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.blue.opacity(0.1)))

                // 狂信者には人狼プレイヤーを表示
                if player.role == .fanatic,
                   let gm = viewModel.gameManager {
                    let wolves = gm.getAlivePlayers().filter { $0.role == .werewolf }
                    if !wolves.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("人狼は以下のプレイヤーです", systemImage: "pawprint.fill")
                                .font(.headline)
                                .foregroundStyle(.red)
                            ForEach(wolves, id: \.id) { wolf in
                                Text("・\(wolf.name)")
                                    .font(.body)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.red.opacity(0.1)))
                    }
                }

                let turn = viewModel.gameManager?.turn ?? 1
                if player.role.hasNightAction(turn: turn) {
                    Button("アクションへ") {
                        if player.role == .medium {
                            // 霊媒師は対象選択不要 → 直接結果表示
                            viewModel.confirmNightAction(
                                action: NightAction(type: .medium, target: nil)
                            )
                        } else {
                            viewModel.nightPlayerState = .actionSelect
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Text("このターンでは、特に必要なアクションはありません。")
                        .foregroundStyle(.secondary)
                        .padding()

                    Button("確認しました") {
                        viewModel.skipPlayerAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray)
                    Text("タップして役職を確認")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(40)
                .background(RoundedRectangle(cornerRadius: 16).fill(.gray.opacity(0.1)))
                .onTapGesture {
                    viewModel.roleRevealed = true
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - 3. アクション選択画面

    private func actionSelectView(player: Player) -> some View {
        ActionSelectContent(viewModel: viewModel, player: player)
    }

    // MARK: - 4. アクション結果画面

    private func actionResultView(player: Player) -> some View {
        ActionResultContent(viewModel: viewModel, player: player)
    }

    // MARK: - 5. 完了画面

    private func doneView(player: Player) -> some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("アクションが完了しました")
                .font(.title2)
                .fontWeight(.bold)
            Text("次の人に端末を渡してください")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button("次のプレイヤーへ") {
                viewModel.advanceToNextPlayer()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .padding()
    }
}

// MARK: - アクション選択コンテンツ

private struct ActionSelectContent: View {
    @Bindable var viewModel: GameViewModel
    let player: Player
    @State private var selectedTarget: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text(player.role.displayName)
                .font(.headline)
                .foregroundStyle(.blue)

            if let description = player.role.actionDescription {
                Text("\(description)を選んでください:")
                    .font(.subheadline)
            }

            let targets = availableTargets
            if targets.isEmpty {
                Text("選択できる対象がいません。")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                List(targets, id: \.self, selection: $selectedTarget) { target in
                    Text(target)
                }
                .listStyle(.plain)
            }

            Button("アクションを確定する") {
                let actionType: ActionType
                switch player.role {
                case .werewolf: actionType = .attack
                case .seer, .fakeSeer: actionType = .seer
                case .knight: actionType = .guard
                default: actionType = .none
                }
                viewModel.confirmNightAction(
                    action: NightAction(type: actionType, target: selectedTarget)
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedTarget == nil && !availableTargets.isEmpty)
        }
        .padding()
    }

    private var availableTargets: [String] {
        guard let gm = viewModel.gameManager else { return [] }
        let alive = gm.getAlivePlayers()

        switch player.role {
        case .werewolf:
            return alive.filter { $0.role.species != .werewolf }.map(\.name)
        case .seer, .fakeSeer:
            return alive.filter { $0.name != player.name }.map(\.name)
        case .knight:
            return alive.filter { $0.name != player.name }.map(\.name)
        default:
            return []
        }
    }
}

// MARK: - アクション結果コンテンツ

private struct ActionResultContent: View {
    @Bindable var viewModel: GameViewModel
    let player: Player

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            let action = viewModel.nightActions[player.name]

            if let action = action {
                switch action.type {
                case .seer:
                    seerResultView(action: action)
                case .attack:
                    if let target = action.target {
                        Text("あなたは **\(target)** さんを襲撃対象に選択しました。")
                    }
                case .guard:
                    if let target = action.target {
                        Text("あなたは **\(target)** さんを守護します。")
                    }
                case .medium:
                    mediumResultView()
                case .none:
                    Text("このターンでは、特に必要なアクションはありませんでした。")
                }
            }

            Spacer()

            Button("確認しました") {
                viewModel.nightPlayerState = .done
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    @ViewBuilder
    private func seerResultView(action: NightAction) -> some View {
        if let targetName = action.target {
            VStack(spacing: 12) {
                Text("あなたは **\(targetName)** さんを選択しました。")

                if player.role == .fakeSeer {
                    let result = player.role.fakeSeerResult()
                    HStack {
                        Image(systemName: "sparkles")
                        Text("占い結果: **\(targetName)** さんは **\(result)** です。")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(.purple.opacity(0.1)))
                } else if let gm = viewModel.gameManager,
                          let targetPlayer = gm.players.first(where: { $0.name == targetName }) {
                    let result = targetPlayer.role.seerResult.rawValue
                    HStack {
                        Image(systemName: "sparkles")
                        Text("占い結果: **\(targetName)** さんは **\(result)** です。")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(.blue.opacity(0.1)))
                }
            }
        }
    }

    @ViewBuilder
    private func mediumResultView() -> some View {
        if let gm = viewModel.gameManager, let executedName = gm.lastExecutedName {
            if let executedPlayer = gm.players.first(where: { $0.name == executedName }) {
                let result = executedPlayer.role.mediumResult.rawValue
                HStack {
                    Image(systemName: "sparkles")
                    Text("昨晩処刑された \(executedName) は **\(result)** でした。")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(.purple.opacity(0.1)))
            } else {
                Text("\(executedName) の情報が見つかりませんでした。")
                    .foregroundStyle(.orange)
            }
        } else {
            Text("昨晩は処刑がありませんでした。")
                .foregroundStyle(.secondary)
        }
    }
}

import SwiftUI

struct DayPhaseView: View {
    @Bindable var viewModel: GameViewModel
    @State private var victoryResult: VictoryResult? = nil
    @State private var batchTarget: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - 夜の結果発表
                nightResultSection

                // 夜の結果による勝利判定
                if let victory = checkNightVictory() {
                    victorySection(victory)
                } else {
                    // MARK: - 生存者表示
                    survivorSection

                    Divider()

                    // MARK: - 議論タイマー
                    DiscussionTimerView(minutes: viewModel.discussionMinutes)

                    Divider()

                    // MARK: - 投票
                    votingSection

                    // MARK: - 処刑結果表示
                    if viewModel.executionProcessed {
                        executionResultSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(viewModel.gameManager?.turn ?? 2)日目 - 昼")
    }

    // MARK: - 夜の結果

    private var nightResultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("夜の結果")
                .font(.headline)

            if !viewModel.lastNightVictims.isEmpty {
                Label(
                    "昨晩の犠牲者は \(viewModel.lastNightVictims.joined(separator: ", ")) でした。",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.red)
            } else {
                Label("昨晩は誰も死亡しませんでした。", systemImage: "checkmark.circle")
                    .foregroundStyle(.blue)
            }

            if viewModel.debugMode {
                debugNightSection
            }
        }
    }

    // MARK: - 勝利判定チェック (夜の結果)

    private func checkNightVictory() -> VictoryResult? {
        return viewModel.checkVictoryAfterNight()
    }

    // MARK: - 勝利表示

    private func victorySection(_ victory: VictoryResult) -> some View {
        VStack(spacing: 16) {
            Text(victory.message)
                .font(.headline)
                .foregroundStyle(.green)
                .padding()
            Button("結果を見る") {
                viewModel.proceedToGameOver()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 生存者

    private var survivorSection: some View {
        let alive = viewModel.gameManager?.getAlivePlayers() ?? []
        return VStack(alignment: .leading, spacing: 8) {
            Text("生存者")
                .font(.headline)

            if viewModel.debugMode {
                Text("\(alive.count) 人:")
                    .foregroundStyle(.secondary)
                ForEach(alive, id: \.id) { player in
                    Text("  \(player.name) — \(player.role.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("\(alive.count) 人: \(alive.map(\.name).joined(separator: ", "))")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 投票セクション

    private var votingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("投票")
                .font(.headline)

            Toggle("一括処刑モード", isOn: $viewModel.batchVoteMode)
                .padding(.bottom, 4)

            if viewModel.batchVoteMode {
                batchVotingView
            } else {
                individualVotingView
            }
        }
    }

    // MARK: - 一括処刑モード

    private var batchVotingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("議論の結果、処刑する対象者を一人選択してください。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let alive = viewModel.gameManager?.getAlivePlayers() ?? []

            Picker("処刑対象者", selection: $batchTarget) {
                Text("選択してください").tag("")
                ForEach(alive, id: \.id) { player in
                    Text(player.name).tag(player.name)
                }
            }
            .pickerStyle(.menu)

            if !viewModel.executionProcessed {
                Button("処刑を確定する") {
                    viewModel.executeBatchVote(target: batchTarget)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(batchTarget.isEmpty)
            }
        }
    }

    // MARK: - 個別投票モード

    private var individualVotingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            let alive = viewModel.gameManager?.getAlivePlayers() ?? []

            ForEach(alive, id: \.id) { voter in
                DisclosureGroup {
                    let targets = alive.map(\.name)
                    ForEach(targets, id: \.self) { target in
                        Button {
                            viewModel.dayVotes[voter.name] = target
                        } label: {
                            HStack {
                                Text(target)
                                Spacer()
                                if viewModel.dayVotes[voter.name] == target {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    HStack {
                        Text("\(voter.name) さんの投票")
                        Spacer()
                        if let vote = viewModel.dayVotes[voter.name] {
                            Text(vote)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            // 投票状況
            let allVoted = viewModel.dayVotes.count == alive.count
            Text("投票状況: \(viewModel.dayVotes.count) / \(alive.count) 人")
                .font(.caption)
                .foregroundStyle(allVoted ? .green : .orange)

            if allVoted {
                // 投票結果表示
                let voteCounts = countVotes()
                VStack(alignment: .leading, spacing: 4) {
                    Text("各プレイヤーへの得票数:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    ForEach(voteCounts.sorted(by: { $0.value > $1.value }), id: \.key) { name, count in
                        Text("- \(name): \(count) 票")
                    }
                }

                if viewModel.debugMode {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DEBUG: 投票内訳")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                        ForEach(viewModel.dayVotes.sorted(by: { $0.key < $1.key }), id: \.key) { voter, target in
                            Text("  · \(voter) → \(target)")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(6)
                }

                if !viewModel.executionProcessed {
                    Button("投票を締め切り、処刑を実行する") {
                        viewModel.executeIndividualVotes()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
    }

    // MARK: - 処刑結果

    private var executionResultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            if let result = viewModel.lastExecutionResult {
                if let error = result.error {
                    Text("処刑処理エラー: \(error)")
                        .foregroundStyle(.red)
                } else {
                    if let executed = result.executed {
                        Label("\(executed) さんが処刑されました。", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    } else {
                        Text("本日は処刑はありませんでした。")
                            .foregroundStyle(.secondary)
                    }

                    if !result.immoralSuicides.isEmpty {
                        Label(
                            "妖狐が処刑されたため、\(result.immoralSuicides.joined(separator: ", ")) が後を追いました。",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.orange)
                    }

                    if let retaliation = result.retaliationVictim, let executed = result.executed {
                        Label(
                            "\(executed)(猫又) が処刑されたため、\(retaliation) を道連れにしました。",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.red)
                    }
                }
            }

            if viewModel.debugMode, let result = viewModel.lastExecutionResult, let debug = result.debug, !debug.isEmpty {
                debugInfoBox(title: "処刑デバッグ情報", items: [debug])
            }

            // 処刑後の勝利判定
            if let victory = viewModel.checkVictoryAfterExecution() {
                Text(victory.message)
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding(.top)

                Button("最終結果へ") {
                    viewModel.proceedToGameOver()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("夜へ進む") {
                    viewModel.proceedToNight()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
    }

    // MARK: - デバッグ表示

    private var debugNightSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !viewModel.lastNightDebug.isEmpty {
                debugInfoBox(title: "夜フェーズ詳細", items: viewModel.lastNightDebug)
            }

            if let gm = viewModel.gameManager {
                debugInfoBox(
                    title: "全プレイヤー役職",
                    items: gm.players.map { "\($0.name): \($0.role.displayName) [\($0.isAlive ? "生存" : "死亡")]" }
                )
            }
        }
    }

    private func debugInfoBox(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("DEBUG: \(title)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text("  · \(item)")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding(8)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(6)
    }

    // MARK: - ヘルパー

    private func countVotes() -> [String: Int] {
        var counts: [String: Int] = [:]
        for (_, target) in viewModel.dayVotes {
            counts[target, default: 0] += 1
        }
        return counts
    }
}

// MARK: - 議論タイマー

struct DiscussionTimerView: View {
    let minutes: Int
    @State private var remainingSeconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text("議論タイム")
                .font(.headline)

            Text(timeString)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(remainingSeconds == 0 && isRunning ? .red : .primary)

            HStack(spacing: 16) {
                Button(isRunning ? "一時停止" : "開始") {
                    if isRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isRunning ? .blue : .green)

                Button("リセット") {
                    resetTimer()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .onAppear {
            remainingSeconds = minutes * 60
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    private var timeString: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func startTimer() {
        if remainingSeconds <= 0 {
            remainingSeconds = minutes * 60
        }
        isRunning = true
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    stopTimer()
                    break
                }
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    private func resetTimer() {
        stopTimer()
        remainingSeconds = minutes * 60
    }
}

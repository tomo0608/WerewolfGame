import SwiftUI

struct InitialSetupView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        Form {
            // MARK: - プレイヤー人数
            Section("プレイヤー人数") {
                Stepper(
                    "\(viewModel.playerCount) 人",
                    value: $viewModel.playerCount,
                    in: GameSettings.minPlayers...20,
                    step: 1
                )
                .onChange(of: viewModel.playerCount) {
                    viewModel.initializePlayerNames()
                }

                if GameSettings.defaultPlayerCount >= GameSettings.minPlayers {
                    Button("デフォルトの \(GameSettings.defaultPlayerCount) 人で設定") {
                        viewModel.playerCount = GameSettings.defaultPlayerCount
                        viewModel.initializePlayerNames()
                    }
                }
            }

            // MARK: - プレイヤー名
            Section("プレイヤー名") {
                ForEach(Array(viewModel.playerNames.indices), id: \.self) { index in
                    TextField(
                        "プレイヤー\(index + 1)",
                        text: Binding(
                            get: {
                                guard index < viewModel.playerNames.count else { return "" }
                                return viewModel.playerNames[index]
                            },
                            set: {
                                guard index < viewModel.playerNames.count else { return }
                                viewModel.playerNames[index] = $0
                            }
                        )
                    )
                }
            }

            // MARK: - エラーメッセージ
            if !viewModel.errorMessage.isEmpty {
                Section {
                    Text(viewModel.errorMessage)
                        .foregroundStyle(.red)
                }
            }

            // MARK: - 次へ
            Section {
                Button("役職設定へ進む") {
                    if viewModel.validatePlayerNames() {
                        viewModel.stage = .roleSetup
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // MARK: - 履歴
            Section {
                NavigationLink("過去の結果を見る") {
                    GameHistoryView()
                }
            }
        }
        .navigationTitle("ゲーム設定")
        .onAppear {
            viewModel.initializePlayerNames()
        }
    }
}

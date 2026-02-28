import SwiftUI

struct ConfirmSetupView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        Form {
            Section("プレイヤー") {
                Text("\(viewModel.playerCount) 人: \(viewModel.playerNames.joined(separator: ", "))")
            }

            Section("役職") {
                ForEach(RoleType.allCases.filter { viewModel.roleCounts[$0, default: 0] > 0 }) { role in
                    HStack {
                        Text(role.rawValue)
                        Spacer()
                        Text("\(viewModel.roleCounts[role, default: 0]) 人")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Toggle("デバッグモード", isOn: $viewModel.debugMode)
            }

            Section {
                Button("ゲーム開始！") {
                    viewModel.startGame()
                }
                .frame(maxWidth: .infinity)
                .font(.headline)

                Button("役職設定に戻る") {
                    viewModel.stage = .roleSetup
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("設定確認")
    }
}

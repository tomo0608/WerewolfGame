import SwiftUI

struct RoleSetupView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        Form {
            Section {
                Text("プレイヤー数: \(viewModel.playerCount) 人")
                Text("プレイヤー: \(viewModel.playerNames.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - デフォルト設定ボタン
            if GameSettings.defaultRoleCounts.values.reduce(0, +) == viewModel.playerCount {
                Section {
                    Button("デフォルトの役職構成を使用") {
                        viewModel.roleCounts = GameSettings.defaultRoleCounts
                    }
                }
            }

            // MARK: - 各役職の人数
            Section("各役職の人数") {
                ForEach(RoleType.allCases) { role in
                    Stepper(
                        "\(role.rawValue): \(viewModel.roleCounts[role, default: 0]) 人",
                        value: Binding(
                            get: { viewModel.roleCounts[role, default: 0] },
                            set: { viewModel.roleCounts[role] = $0 }
                        ),
                        in: 0...viewModel.playerCount
                    )
                }
            }

            // MARK: - ハウスルール
            Section("ハウスルール") {
                Toggle("連続ガード禁止", isOn: Binding(
                    get: { !viewModel.houseRules.allowConsecutiveGuard },
                    set: { viewModel.houseRules.allowConsecutiveGuard = !$0 }
                ))

                Picker("初日占い", selection: $viewModel.houseRules.firstDaySeer) {
                    ForEach(FirstDaySeerOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            // MARK: - 残り人数
            Section {
                let remaining = viewModel.remainingRoles
                if remaining > 0 {
                    Text("割り当て済み: \(viewModel.totalRoleCount) 人 / 残り: \(remaining) 人")
                        .foregroundStyle(.orange)
                } else if remaining < 0 {
                    Text("人数がプレイヤー数を超えています！")
                        .foregroundStyle(.red)
                } else {
                    Text("すべてのプレイヤーに役職が割り当てられました。")
                        .foregroundStyle(.green)
                }
            }

            // MARK: - エラーメッセージ
            if !viewModel.errorMessage.isEmpty {
                Section {
                    Text(viewModel.errorMessage)
                        .foregroundStyle(.red)
                }
            }

            // MARK: - ボタン
            Section {
                Button("設定を確認する") {
                    if viewModel.validateRoleCounts() {
                        viewModel.stage = .confirmSetup
                    }
                }
                .disabled(viewModel.remainingRoles != 0)
                .frame(maxWidth: .infinity)

                Button("プレイヤー設定に戻る") {
                    viewModel.stage = .initialSetup
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("役職設定")
    }
}

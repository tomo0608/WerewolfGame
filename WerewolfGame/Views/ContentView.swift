import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.stage {
                case .initialSetup:
                    InitialSetupView(viewModel: viewModel)
                case .roleSetup:
                    RoleSetupView(viewModel: viewModel)
                case .confirmSetup:
                    ConfirmSetupView(viewModel: viewModel)
                case .nightPhase:
                    NightPhaseView(viewModel: viewModel)
                case .dayPhase:
                    DayPhaseView(viewModel: viewModel)
                case .gameOver:
                    GameOverView(viewModel: viewModel)
                }
            }
            .navigationTitle("人狼ゲーム")
        }
    }
}

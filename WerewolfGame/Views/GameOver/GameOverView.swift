import SwiftUI

struct GameOverView: View {
    @Bindable var viewModel: GameViewModel
    @State private var saveMessage: String = ""
    @State private var showShareSheet: Bool = false
    @State private var jsonData: Data? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 勝利チーム
                if let team = viewModel.gameManager?.victoryTeam {
                    Text("\(team.rawValue) 陣営の勝利！")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                } else {
                    Text("勝敗が正常に判定できませんでした。")
                        .foregroundStyle(.orange)
                }

                // MARK: - 結果テーブル
                if let results = viewModel.gameManager?.getGameResults() {
                    VStack(alignment: .leading, spacing: 0) {
                        // ヘッダー
                        HStack {
                            Text("名前").frame(maxWidth: .infinity, alignment: .leading)
                            Text("役職").frame(width: 60, alignment: .center)
                            Text("陣営").frame(width: 50, alignment: .center)
                            Text("生死").frame(maxWidth: .infinity, alignment: .leading)
                            Text("").frame(width: 30, alignment: .center)
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.2))

                        // データ行
                        ForEach(results) { result in
                            HStack {
                                Text(result.name).frame(maxWidth: .infinity, alignment: .leading)
                                Text(result.role).frame(width: 60, alignment: .center)
                                Text(result.team).frame(width: 50, alignment: .center)
                                Text(result.status)
                                    .font(.caption2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(result.isWinner ? "🏆" : "")
                                    .frame(width: 30, alignment: .center)
                            }
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal)
                            Divider()
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }

                // MARK: - 保存・共有

                if !saveMessage.isEmpty {
                    Text(saveMessage)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Button("結果を保存する") {
                    saveResults()
                }
                .buttonStyle(.bordered)

                if let data = jsonData {
                    ShareLink(
                        item: String(data: data, encoding: .utf8) ?? "",
                        subject: Text("人狼ゲーム結果"),
                        message: Text("人狼ゲームの結果です")
                    ) {
                        Label("結果を共有する", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                // MARK: - 新しいゲーム
                Button("新しいゲームを始める") {
                    viewModel.resetGame()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle("ゲーム終了")
        .onAppear {
            prepareJsonData()
        }
    }

    // MARK: - JSON保存

    private func buildJsonObject() -> [String: Any]? {
        guard let results = viewModel.gameManager?.getGameResults() else { return nil }

        let playerArray = results.map { result -> [String: String] in
            [
                "名前": result.name,
                "役職": result.role,
                "生死": result.status,
                "陣営": result.team,
                "勝利": result.isWinner ? "🏆" : ""
            ]
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return [
            "勝利チーム": viewModel.gameManager?.victoryTeam?.rawValue ?? "不明",
            "日時": dateFormatter.string(from: Date()),
            "プレイヤー": playerArray
        ]
    }

    private func saveResults() {
        guard let jsonObject = buildJsonObject() else { return }

        do {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let resultDir = documentsDir.appendingPathComponent("result")
            try FileManager.default.createDirectory(at: resultDir, withIntermediateDirectories: true)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let filename = formatter.string(from: Date()) + ".json"
            let fileURL = resultDir.appendingPathComponent(filename)

            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
            try data.write(to: fileURL)

            saveMessage = "結果を \(filename) に保存しました。"
        } catch {
            saveMessage = "結果の保存中にエラーが発生しました: \(error.localizedDescription)"
        }
    }

    private func prepareJsonData() {
        guard let jsonObject = buildJsonObject() else { return }
        jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
    }
}

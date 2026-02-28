import SwiftUI

struct GameHistoryEntry: Identifiable {
    let id = UUID()
    let filename: String
    let date: String
    let winningTeam: String
    let playerCount: Int
    let players: [[String: String]]
}

struct GameHistoryView: View {
    @State private var entries: [GameHistoryEntry] = []
    @State private var errorMessage: String = ""
    @State private var selectedIDs: Set<UUID> = []
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        Group {
            if entries.isEmpty && errorMessage.isEmpty {
                ContentUnavailableView(
                    "履歴がありません",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("ゲーム終了後に結果を保存すると、ここに表示されます。")
                )
            } else if !errorMessage.isEmpty {
                ContentUnavailableView(
                    "読み込みエラー",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                List(selection: $selectedIDs) {
                    ForEach(entries) { entry in
                        NavigationLink(destination: GameHistoryDetailView(entry: entry)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text("\(entry.winningTeam)陣営の勝利")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(entry.playerCount)人")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
        }
        .navigationTitle("過去の結果")
        .toolbar {
            if !entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("削除(\(selectedIDs.count)件)") {
                            showDeleteConfirmation = true
                        }
                        .disabled(selectedIDs.isEmpty)
                        .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "完了" : "選択") {
                        if isEditing {
                            selectedIDs.removeAll()
                        }
                        isEditing.toggle()
                    }
                }
            }
        }
        .confirmationDialog(
            "\(selectedIDs.count)件の履歴を削除しますか？",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                deleteSelectedEntries()
            }
        }
        .onAppear {
            loadEntries()
        }
    }

    private func deleteSelectedEntries() {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let resultDir = documentsDir.appendingPathComponent("result")

        for entry in entries where selectedIDs.contains(entry.id) {
            let fileURL = resultDir.appendingPathComponent(entry.filename)
            try? FileManager.default.removeItem(at: fileURL)
        }
        entries.removeAll { selectedIDs.contains($0.id) }
        selectedIDs.removeAll()
        if entries.isEmpty {
            isEditing = false
        }
    }

    private func loadEntries() {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let resultDir = documentsDir.appendingPathComponent("result")

        guard FileManager.default.fileExists(atPath: resultDir.path) else {
            entries = []
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: resultDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }

            entries = files.compactMap { fileURL in
                guard let data = try? Data(contentsOf: fileURL),
                      let json = try? JSONSerialization.jsonObject(with: data) else { return nil }

                let filename = fileURL.lastPathComponent

                // New format: dictionary with 勝利チーム, 日時, プレイヤー
                if let dict = json as? [String: Any],
                   let winningTeam = dict["勝利チーム"] as? String,
                   let date = dict["日時"] as? String,
                   let players = dict["プレイヤー"] as? [[String: String]] {
                    return GameHistoryEntry(
                        filename: filename,
                        date: date,
                        winningTeam: winningTeam,
                        playerCount: players.count,
                        players: players
                    )
                }

                // Legacy format: array of player dictionaries
                if let players = json as? [[String: String]] {
                    let dateString = parseDateFromFilename(filename)
                    let winnerTeam = players.first(where: { $0["勝利"] == "🏆" })?["陣営"] ?? "不明"
                    return GameHistoryEntry(
                        filename: filename,
                        date: dateString,
                        winningTeam: winnerTeam,
                        playerCount: players.count,
                        players: players
                    )
                }

                return nil
            }
        } catch {
            errorMessage = "ファイルの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    private func parseDateFromFilename(_ filename: String) -> String {
        // filename: "20260228_143022.json" -> "2026-02-28 14:30:22"
        let name = filename.replacingOccurrences(of: ".json", with: "")
        let parts = name.split(separator: "_")
        guard parts.count == 2,
              parts[0].count == 8,
              parts[1].count == 6 else { return name }

        let d = parts[0]
        let t = parts[1]
        let dateIndex = d.index(d.startIndex, offsetBy: 4)
        let monthIndex = d.index(d.startIndex, offsetBy: 6)
        let hourIndex = t.index(t.startIndex, offsetBy: 2)
        let minIndex = t.index(t.startIndex, offsetBy: 4)

        return "\(d[d.startIndex..<dateIndex])-\(d[dateIndex..<monthIndex])-\(d[monthIndex...]) \(t[t.startIndex..<hourIndex]):\(t[hourIndex..<minIndex]):\(t[minIndex...])"
    }

    private func deleteEntries(at offsets: IndexSet) {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let resultDir = documentsDir.appendingPathComponent("result")

        for index in offsets {
            let entry = entries[index]
            let fileURL = resultDir.appendingPathComponent(entry.filename)
            try? FileManager.default.removeItem(at: fileURL)
        }
        entries.remove(atOffsets: offsets)
    }
}

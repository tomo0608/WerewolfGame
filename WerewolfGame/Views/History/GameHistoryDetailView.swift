import SwiftUI

struct GameHistoryDetailView: View {
    let entry: GameHistoryEntry

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 勝利チーム
                Text("\(entry.winningTeam) 陣営の勝利！")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(entry.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // MARK: - 結果テーブル
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
                    ForEach(Array(entry.players.enumerated()), id: \.offset) { _, player in
                        HStack {
                            Text(player["名前"] ?? "").frame(maxWidth: .infinity, alignment: .leading)
                            Text(player["役職"] ?? "").frame(width: 60, alignment: .center)
                            Text(player["陣営"] ?? "").frame(width: 50, alignment: .center)
                            Text(player["生死"] ?? "")
                                .font(.caption2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(player["勝利"] ?? "")
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
            .padding()
        }
        .navigationTitle("結果詳細")
    }
}

import Foundation

// MARK: - チーム (陣営)

enum Team: String, CaseIterable, Codable {
    case villager = "村人"
    case werewolf = "人狼"
    case fox = "妖狐"
}

// MARK: - 種族 (占い・勝利判定に使用)

enum Species: String {
    case villager = "村人"
    case werewolf = "人狼"
    case fox = "妖狐"
}

// MARK: - 占い結果

enum SeerResult: String {
    case villager = "村人"
    case werewolf = "人狼"
}

// MARK: - 霊媒結果

enum MediumResult: String {
    case notWerewolf = "人狼ではない"
    case werewolf = "人狼"
}

// MARK: - 死因

enum DeathReason: String, Codable {
    case attack = "attack"
    case execute = "execute"
    case curse = "curse"
    case suicide = "suicide"
    case retaliation = "retaliation"

    var displayName: String {
        switch self {
        case .attack: return "襲撃"
        case .execute: return "処刑"
        case .curse: return "呪殺"
        case .suicide: return "後追死"
        case .retaliation: return "道連れ"
        }
    }
}

// MARK: - 死亡情報

struct DeathInfo: Codable {
    let turn: Int
    let reason: DeathReason
}

// MARK: - 夜アクション種別

enum ActionType: String {
    case seer
    case attack
    case `guard`
    case medium
    case none
}

// MARK: - 夜アクション

struct NightAction {
    let type: ActionType
    let target: String?
}

// MARK: - 夜の結果

struct NightResult {
    let victims: [String]
    let immoralSuicides: [String]
    let debug: [String]?
}

// MARK: - 処刑結果

struct ExecutionResult {
    let executed: String?
    let immoralSuicides: [String]
    let retaliationVictim: String?
    let error: String?
    let debug: String?
}

// MARK: - 勝利結果

struct VictoryResult {
    let team: Team
    let message: String
}

// MARK: - プレイヤー結果 (ゲーム終了時)

struct PlayerResult: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let status: String
    let team: String
    let isWinner: Bool
}

// MARK: - ゲームステージ

enum GameStage {
    case initialSetup
    case roleSetup
    case confirmSetup
    case nightPhase
    case dayPhase
    case gameOver
}

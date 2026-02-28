import Foundation
import Observation

@Observable
class GameViewModel {
    // MARK: - ステージ管理

    var stage: GameStage = .initialSetup

    // MARK: - セットアップ状態

    var playerCount: Int = GameSettings.defaultPlayerCount
    var playerNames: [String] = []
    var roleCounts: [RoleType: Int] = GameSettings.defaultRoleCounts
    var debugMode: Bool = false
    var houseRules = HouseRules()
    var errorMessage: String = ""

    // MARK: - ゲーム状態

    var gameManager: GameManager? = nil

    // MARK: - 夜フェーズ状態

    var currentPlayerIndex: Int = 0
    var nightActions: [String: NightAction] = [:]

    /// 夜フェーズでの各プレイヤーの状態
    enum NightPlayerState {
        case handoff
        case roleReveal
        case actionSelect
        case actionResult
        case done
    }
    var nightPlayerState: NightPlayerState = .handoff
    var roleRevealed: Bool = false

    // MARK: - 昼フェーズ状態

    var dayVotes: [String: String] = [:]
    var batchVoteMode: Bool = false
    var executionProcessed: Bool = false
    var lastExecutionResult: ExecutionResult? = nil
    var lastNightVictims: [String] = []
    var lastNightImmoralSuicides: [String] = []
    var lastNightDebug: [String] = []
    var discussionMinutes: Int = 3

    // MARK: - セットアップ操作

    func initializePlayerNames() {
        if playerNames.count != playerCount {
            playerNames = (1...playerCount).map { "プレイヤー\($0)" }
        }
    }

    func validatePlayerNames() -> Bool {
        errorMessage = ""

        if playerNames.isEmpty {
            errorMessage = "プレイヤー名が設定されていません。"
            return false
        }

        if playerNames.contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            errorMessage = "すべてのプレイヤー名を入力してください。"
            return false
        }

        if Set(playerNames).count != playerCount {
            errorMessage = "プレイヤー名が重複しています。"
            return false
        }

        return true
    }

    var totalRoleCount: Int {
        roleCounts.values.reduce(0, +)
    }

    var remainingRoles: Int {
        playerCount - totalRoleCount
    }

    func validateRoleCounts() -> Bool {
        errorMessage = ""
        if totalRoleCount != playerCount {
            errorMessage = "役職の合計人数がプレイヤー数と一致しません。"
            return false
        }
        return true
    }

    // MARK: - ゲーム開始

    func startGame() {
        var roles: [RoleType] = []
        for (role, count) in roleCounts {
            roles.append(contentsOf: Array(repeating: role, count: count))
        }

        let gm = GameManager(playerNames: playerNames, debugMode: debugMode, houseRules: houseRules)
        gm.assignRoles(roles)
        gameManager = gm

        stage = .nightPhase
        currentPlayerIndex = 0
        nightActions = [:]
        nightPlayerState = .handoff
        roleRevealed = false
    }

    // MARK: - 夜フェーズ操作

    /// 生存中の人狼プレイヤー名（狂信者への表示用）
    var aliveWerewolfNames: [String] {
        guard let gm = gameManager else { return [] }
        return gm.getAlivePlayers().filter { $0.role == .werewolf }.map(\.name)
    }

    /// 現在アクション中のプレイヤー (nil = 全員完了)
    var currentNightPlayer: Player? {
        guard let gm = gameManager else { return nil }
        let alive = gm.getAlivePlayers()
        guard currentPlayerIndex < alive.count else { return nil }
        return alive[currentPlayerIndex]
    }

    func confirmNightAction(action: NightAction) {
        guard let player = currentNightPlayer else { return }
        nightActions[player.name] = action
        nightPlayerState = .actionResult
    }

    func advanceToNextPlayer() {
        guard let gm = gameManager else { return }
        let alive = gm.getAlivePlayers()
        currentPlayerIndex += 1
        roleRevealed = false

        if currentPlayerIndex >= alive.count {
            // 全員完了 → 夜の解決
            resolveNight()
        } else {
            nightPlayerState = .handoff
        }
    }

    func skipPlayerAction() {
        guard let player = currentNightPlayer else { return }
        nightActions[player.name] = NightAction(type: .none, target: nil)
        advanceToNextPlayer()
    }

    private func resolveNight() {
        guard let gm = gameManager else { return }

        let results = gm.resolveNightActions(nightActions)
        lastNightVictims = results.victims
        lastNightImmoralSuicides = results.immoralSuicides
        lastNightDebug = results.debug ?? []

        // ターンを進めて昼へ
        gm.turn += 1
        stage = .dayPhase

        // 昼フェーズ用の状態をリセット
        dayVotes = [:]
        executionProcessed = false
        lastExecutionResult = nil
    }

    // MARK: - 昼フェーズ操作

    func executeVote(votes: [String: Int]) {
        guard let gm = gameManager else { return }

        let result = gm.executeDayVote(votes)
        lastExecutionResult = result
        executionProcessed = true
    }

    func executeBatchVote(target: String) {
        executeVote(votes: [target: 1])
    }

    func executeIndividualVotes() {
        var voteCounts: [String: Int] = [:]
        for (_, target) in dayVotes {
            voteCounts[target, default: 0] += 1
        }
        executeVote(votes: voteCounts)
    }

    func checkVictoryAfterExecution() -> VictoryResult? {
        return gameManager?.checkVictory()
    }

    func checkVictoryAfterNight() -> VictoryResult? {
        return gameManager?.checkVictory()
    }

    func proceedToNight() {
        guard gameManager != nil else { return }
        stage = .nightPhase
        currentPlayerIndex = 0
        nightActions = [:]
        nightPlayerState = .handoff
        roleRevealed = false
        dayVotes = [:]
        executionProcessed = false
        lastExecutionResult = nil
    }

    func proceedToGameOver() {
        stage = .gameOver
    }

    // MARK: - リセット

    func resetGame() {
        stage = .initialSetup
        playerCount = GameSettings.defaultPlayerCount
        playerNames = []
        roleCounts = GameSettings.defaultRoleCounts
        debugMode = false
        houseRules = HouseRules()
        errorMessage = ""
        gameManager = nil
        currentPlayerIndex = 0
        nightActions = [:]
        nightPlayerState = .handoff
        roleRevealed = false
        dayVotes = [:]
        batchVoteMode = false
        executionProcessed = false
        lastExecutionResult = nil
        lastNightVictims = []
        lastNightImmoralSuicides = []
        lastNightDebug = []
        discussionMinutes = 3
    }
}

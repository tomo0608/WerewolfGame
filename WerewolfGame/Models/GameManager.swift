import Foundation

class GameManager {
    var players: [Player]
    var turn: Int = 1
    var lastNightVictimNameList: [String] = []
    var lastExecutedName: String? = nil
    var victoryTeam: Team? = nil
    let debugMode: Bool

    init(playerNames: [String], debugMode: Bool = false) {
        self.players = playerNames.enumerated().map { index, name in
            Player(id: index, name: name)
        }
        self.debugMode = debugMode
    }

    // MARK: - 役職割り当て

    func assignRoles(_ roles: [RoleType]) {
        let shuffled = roles.shuffled()
        for i in 0..<players.count {
            players[i].role = shuffled[i]
        }
    }

    // MARK: - 生存プレイヤー

    func getAlivePlayers() -> [Player] {
        return players.filter { $0.isAlive }
    }

    // MARK: - 勝利判定

    func checkVictory() -> VictoryResult? {
        let alivePlayers = getAlivePlayers()
        let wolves = alivePlayers.filter { $0.role.species == .werewolf }
        let villagers = alivePlayers.filter { $0.role.species == .villager }
        let foxes = alivePlayers.filter { $0.role.species == .fox }

        let villagerWin = wolves.isEmpty
        let werewolfWin = wolves.count >= villagers.count

        guard villagerWin || werewolfWin else {
            return nil
        }

        let result: VictoryResult

        if !foxes.isEmpty {
            // 妖狐勝利
            if villagerWin {
                result = VictoryResult(
                    team: .fox,
                    message: "人狼は全滅しましたが、妖狐が生き残ったため妖狐陣営の勝利です！"
                )
            } else {
                result = VictoryResult(
                    team: .fox,
                    message: "人狼が村人の人数以上となりましたが、妖狐が生き残ったため妖狐陣営の勝利です！"
                )
            }
        } else if villagerWin {
            result = VictoryResult(
                team: .villager,
                message: "人狼は全滅しました。村人陣営の勝利です！"
            )
        } else {
            result = VictoryResult(
                team: .werewolf,
                message: "人狼が村人の人数以上となりました。人狼陣営の勝利です！"
            )
        }

        victoryTeam = result.team
        return result
    }

    // MARK: - ゲーム結果

    func getGameResults() -> [PlayerResult] {
        return players.map { player in
            let isWinner: Bool
            if let winTeam = victoryTeam {
                isWinner = player.role.team == winTeam
            } else {
                isWinner = false
            }

            let status: String
            if !player.isAlive, let info = player.deathInfo {
                status = "\(info.turn)日目 \(info.reason.displayName)により死亡"
            } else if !player.isAlive {
                status = "死亡(詳細不明)"
            } else {
                status = "最終日生存"
            }

            return PlayerResult(
                name: player.name,
                role: player.role.rawValue,
                status: status,
                team: player.role.team.rawValue,
                isWinner: isWinner
            )
        }
    }

    // MARK: - 昼の投票処刑

    func executeDayVote(_ votes: [String: Int]) -> ExecutionResult {
        var debugInfoList: [String]? = debugMode ? [] : nil

        if votes.isEmpty {
            debugInfoList?.append("投票なしのため処刑なし")
            lastExecutedName = nil
            return ExecutionResult(
                executed: nil,
                immoralSuicides: [],
                retaliationVictim: nil,
                error: nil,
                debug: debugInfoList?.joined(separator: "; ")
            )
        }

        let maxVotes = votes.values.max()!
        let candidates = votes.filter { $0.value == maxVotes }.map { $0.key }

        let executedName: String
        if candidates.count > 1 {
            executedName = candidates.randomElement()!
            debugInfoList?.append("同票のためランダム処刑: \(candidates) -> \(executedName)")
        } else {
            executedName = candidates[0]
        }

        debugInfoList?.append("処刑対象は \(executedName)")

        guard let playerIndex = players.firstIndex(where: { $0.name == executedName }) else {
            lastExecutedName = nil
            return ExecutionResult(
                executed: nil,
                immoralSuicides: [],
                retaliationVictim: nil,
                error: "処刑対象プレイヤー '\(executedName)' が見つかりません",
                debug: debugInfoList?.joined(separator: "; ")
            )
        }

        guard players[playerIndex].isAlive else {
            debugInfoList?.append("処刑対象 \(executedName) は既に死亡しています")
            lastExecutedName = nil
            return ExecutionResult(
                executed: nil,
                immoralSuicides: [],
                retaliationVictim: nil,
                error: nil,
                debug: debugInfoList?.joined(separator: "; ")
            )
        }

        players[playerIndex].kill(turn: turn, reason: .execute)
        lastExecutedName = executedName
        debugInfoList?.append("\(executedName) を処刑しました")

        var immoralSuicides: [String] = []
        var retaliationVictim: String? = nil

        // 妖狐処刑時の背徳者後追い
        if players[playerIndex].role == .fox {
            debugInfoList?.append("最後の妖狐が処刑されたため、背徳者の後追い処理を開始")
            let immoralists = getAlivePlayers().filter { $0.role == .immoralist }
            for immoral in immoralists {
                if let idx = players.firstIndex(where: { $0.id == immoral.id }) {
                    players[idx].kill(turn: turn, reason: .suicide)
                    immoralSuicides.append(immoral.name)
                    debugInfoList?.append("\(immoral.name)(背徳者) が後追い自殺")
                }
            }
        }
        // 猫又処刑時の道連れ
        else if players[playerIndex].role == .nekomata {
            let otherAlive = getAlivePlayers().filter { $0.id != players[playerIndex].id }
            if let target = otherAlive.randomElement() {
                if let idx = players.firstIndex(where: { $0.id == target.id }) {
                    players[idx].kill(turn: turn, reason: .retaliation)
                    retaliationVictim = target.name
                    debugInfoList?.append("\(executedName)(猫又)が処刑されたため、\(target.name)を道連れにしました")
                }
            } else {
                debugInfoList?.append("\(executedName)(猫又)が処刑されましたが、道連れにする生存者がいません")
            }
        }

        return ExecutionResult(
            executed: executedName,
            immoralSuicides: immoralSuicides,
            retaliationVictim: retaliationVictim,
            error: nil,
            debug: debugInfoList?.joined(separator: "; ")
        )
    }

    // MARK: - 夜アクション解決

    func resolveNightActions(_ nightActions: [String: NightAction]) -> NightResult {
        var debugInfo: [String]? = debugMode ? [] : nil
        var nightVictims: Set<String> = []
        var immoralSuicides: [String] = []
        var attackTargets: [String] = []
        var guardTargets: Set<String> = []

        let alivePlayers = getAlivePlayers()

        // 1. 各プレイヤーのアクションを分類
        for (playerName, action) in nightActions {
            guard let player = players.first(where: { $0.name == playerName }),
                  player.isAlive else { continue }

            switch action.type {
            case .seer:
                guard let targetName = action.target,
                      let targetPlayer = alivePlayers.first(where: { $0.name == targetName }) else { continue }

                if player.role == .seer {
                    // 本物の占い師
                    if targetPlayer.role == .fox {
                        // 妖狐呪殺
                        if let idx = players.firstIndex(where: { $0.id == targetPlayer.id }) {
                            players[idx].kill(turn: turn, reason: .curse)
                            nightVictims.insert(targetName)
                            debugInfo?.append("\(playerName)が\(targetName)(妖狐)を呪殺")

                            // 最後の妖狐チェック → 背徳者後追い
                            let remainingFoxes = getAlivePlayers().filter { $0.role == .fox }
                            if remainingFoxes.isEmpty {
                                let immoralists = getAlivePlayers().filter { $0.role == .immoralist }
                                for immoral in immoralists {
                                    if let iIdx = players.firstIndex(where: { $0.id == immoral.id }) {
                                        players[iIdx].kill(turn: turn, reason: .suicide)
                                        nightVictims.insert(immoral.name)
                                        immoralSuicides.append(immoral.name)
                                        debugInfo?.append("妖狐全滅により\(immoral.name)(背徳者)が後追い")
                                    }
                                }
                            }
                        }
                    }
                }
                // 偽占い師の場合は何もしない (結果はUI側で生成)

            case .guard:
                if let targetName = action.target {
                    guardTargets.insert(targetName)
                    debugInfo?.append("\(playerName)が\(targetName)を護衛")
                }

            case .attack:
                if let targetName = action.target {
                    attackTargets.append(targetName)
                    debugInfo?.append("\(playerName)が\(targetName)を襲撃対象に選択")
                }

            case .medium, .none:
                break
            }
        }

        // 2. 人狼の襲撃対象を決定 (最多得票)
        var wolfAttackVictimName: String? = nil
        if !attackTargets.isEmpty {
            var targetCounts: [String: Int] = [:]
            for target in attackTargets {
                targetCounts[target, default: 0] += 1
            }
            let maxCount = targetCounts.values.max()!
            let mostCommon = targetCounts.filter { $0.value == maxCount }.map { $0.key }
            wolfAttackVictimName = mostCommon.randomElement()!
            if mostCommon.count > 1 {
                debugInfo?.append("複数の襲撃対象が同票のためランダムに決定: \(mostCommon) -> \(wolfAttackVictimName!)")
            } else {
                debugInfo?.append("人狼の最終襲撃対象は \(wolfAttackVictimName!)")
            }
        }

        // 3. 襲撃の解決
        if let victimName = wolfAttackVictimName,
           let victimPlayer = alivePlayers.first(where: { $0.name == victimName }) {

            let isProtected = guardTargets.contains(victimName)
            let isFox = victimPlayer.role == .fox

            if !isProtected && !isFox {
                // 襲撃成功
                if let idx = players.firstIndex(where: { $0.id == victimPlayer.id }) {
                    players[idx].kill(turn: turn, reason: .attack)
                    nightVictims.insert(victimName)
                    debugInfo?.append("襲撃成功: \(victimName) が死亡")

                    // 猫又の道連れ
                    if victimPlayer.role == .nekomata {
                        let aliveWolves = getAlivePlayers().filter { $0.role.species == .werewolf }
                        if let wolfToKill = aliveWolves.randomElement() {
                            if let wIdx = players.firstIndex(where: { $0.id == wolfToKill.id }) {
                                players[wIdx].kill(turn: turn, reason: .retaliation)
                                nightVictims.insert(wolfToKill.name)
                                debugInfo?.append("\(victimName)(猫又)が襲撃されたため、\(wolfToKill.name)(人狼)を道連れにしました")
                            }
                        } else {
                            debugInfo?.append("\(victimName)(猫又)が襲撃されましたが、道連れにする生存人狼がいません")
                        }
                    }
                }
            } else if isProtected {
                debugInfo?.append("襲撃失敗: \(victimName) は守られていた")
            } else if isFox {
                debugInfo?.append("襲撃失敗: \(victimName) は妖狐だった")
            }
        }

        // 4. 最終犠牲者リスト
        let finalVictimNames = nightVictims.sorted()
        lastNightVictimNameList = finalVictimNames

        debugInfo?.append("今夜の最終犠牲者リスト: \(finalVictimNames)")

        return NightResult(
            victims: finalVictimNames,
            immoralSuicides: immoralSuicides,
            debug: debugInfo
        )
    }
}

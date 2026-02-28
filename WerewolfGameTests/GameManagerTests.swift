import XCTest
@testable import WerewolfGame

final class GameManagerTests: XCTestCase {

    let playerNames = ["Alice", "Bob", "Charlie", "Dave", "Eve"]

    // MARK: - ヘルパー

    private func makeGM(_ names: [String]? = nil) -> GameManager {
        GameManager(playerNames: names ?? playerNames)
    }

    private func assignFixedRoles(_ gm: GameManager, roles: [(String, RoleType)]) {
        for (name, role) in roles {
            if let idx = gm.players.firstIndex(where: { $0.name == name }) {
                gm.players[idx].role = role
            }
        }
    }

    private func makeGMWithRoles(_ roles: [(String, RoleType)]) -> GameManager {
        let names = roles.map { $0.0 }
        let gm = GameManager(playerNames: names)
        for (i, (_, role)) in roles.enumerated() {
            gm.players[i].role = role
        }
        return gm
    }

    // MARK: - 初期化テスト

    func testInitialization() {
        let gm = makeGM()
        XCTAssertEqual(gm.players.count, playerNames.count)
        XCTAssertTrue(gm.players.allSatisfy { playerNames.contains($0.name) })
        XCTAssertEqual(gm.turn, 1)
        XCTAssertEqual(gm.lastNightVictimNameList, [])
        XCTAssertNil(gm.lastExecutedName)
        XCTAssertNil(gm.victoryTeam)
        XCTAssertFalse(gm.debugMode)
    }

    func testAssignRoles() {
        let gm = makeGM()
        let roles: [RoleType] = [.villager, .villager, .villager, .werewolf, .werewolf]
        gm.assignRoles(roles)

        let assignedRoles = gm.players.map(\.role)
        XCTAssertEqual(assignedRoles.count, playerNames.count)

        // 各役職の数を確認
        let villagerCount = assignedRoles.filter { $0 == .villager }.count
        let werewolfCount = assignedRoles.filter { $0 == .werewolf }.count
        XCTAssertEqual(villagerCount, 3)
        XCTAssertEqual(werewolfCount, 2)
    }

    func testGetAlivePlayers() {
        let gm = makeGM()
        gm.assignRoles([.villager, .villager, .villager, .werewolf, .werewolf])

        XCTAssertEqual(gm.getAlivePlayers().count, playerNames.count)

        gm.players[0].kill(turn: 1, reason: .attack)
        let alive = gm.getAlivePlayers()
        XCTAssertEqual(alive.count, playerNames.count - 1)
        XCTAssertFalse(alive.contains(where: { $0.name == gm.players[0].name }))
    }

    // MARK: - 勝利判定テスト

    func testCheckVictoryVillagerWin() {
        let gm = makeGMWithRoles([
            ("Alice", .villager), ("Bob", .villager), ("Charlie", .werewolf)
        ])
        gm.players[2].kill(turn: 1, reason: .attack)

        let result = gm.checkVictory()
        XCTAssertNotNil(result)
        XCTAssertEqual(gm.victoryTeam, .villager)
    }

    func testCheckVictoryWerewolfWin() {
        let gm = makeGMWithRoles([
            ("Alice", .werewolf), ("Bob", .villager)
        ])

        let result = gm.checkVictory()
        XCTAssertNotNil(result)
        XCTAssertEqual(gm.victoryTeam, .werewolf)
    }

    func testCheckVictoryFoxWinNoWolves() {
        let gm = makeGMWithRoles([
            ("Alice", .villager), ("Bob", .fox), ("Charlie", .werewolf)
        ])
        gm.players[2].kill(turn: 1, reason: .attack)

        let result = gm.checkVictory()
        XCTAssertNotNil(result)
        XCTAssertEqual(gm.victoryTeam, .fox)
    }

    func testCheckVictoryFoxWinWithWolves() {
        let gm = makeGMWithRoles([
            ("Alice", .werewolf), ("Bob", .villager), ("Charlie", .fox)
        ])

        let result = gm.checkVictory()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.team, .fox)
        XCTAssertEqual(gm.victoryTeam, .fox)
    }

    func testCheckVictoryGameContinue() {
        let gm = makeGM()
        gm.assignRoles([.villager, .villager, .villager, .werewolf, .werewolf])

        let result = gm.checkVictory()
        XCTAssertNil(result)
        XCTAssertNil(gm.victoryTeam)
    }

    // MARK: - 夜アクションテスト

    func testResolveNightActionsSimpleAttack() {
        let gm = makeGMWithRoles([
            ("Alice", .werewolf), ("Bob", .werewolf),
            ("Charlie", .villager), ("Dave", .villager), ("Eve", .villager)
        ])
        gm.turn = 1

        let actions: [String: NightAction] = [
            "Alice": NightAction(type: .attack, target: "Charlie"),
            "Bob": NightAction(type: .attack, target: "Charlie"),
            "Charlie": NightAction(type: .none, target: nil),
            "Dave": NightAction(type: .none, target: nil),
            "Eve": NightAction(type: .none, target: nil),
        ]

        let results = gm.resolveNightActions(actions)

        XCTAssertEqual(results.victims, ["Charlie"])
        XCTAssertEqual(gm.lastNightVictimNameList, ["Charlie"])
        XCTAssertEqual(results.immoralSuicides, [])
        XCTAssertTrue(gm.players[0].isAlive)
        XCTAssertTrue(gm.players[1].isAlive)
        XCTAssertFalse(gm.players[2].isAlive)
        XCTAssertEqual(gm.players[2].deathInfo?.turn, 1)
        XCTAssertEqual(gm.players[2].deathInfo?.reason, .attack)
    }

    func testResolveNightActionsAttackProtected() {
        let gm = makeGMWithRoles([
            ("Alice", .werewolf), ("Bob", .knight),
            ("Charlie", .villager), ("Dave", .villager), ("Eve", .villager)
        ])
        gm.turn = 2

        let actions: [String: NightAction] = [
            "Alice": NightAction(type: .attack, target: "Charlie"),
            "Bob": NightAction(type: .guard, target: "Charlie"),
        ]

        let results = gm.resolveNightActions(actions)

        XCTAssertEqual(results.victims, [])
        XCTAssertEqual(gm.lastNightVictimNameList, [])
        XCTAssertTrue(gm.players.allSatisfy(\.isAlive))
    }

    func testResolveNightActionsSeerKillsFox() {
        let gm = makeGMWithRoles([
            ("Alice", .seer), ("Bob", .fox),
            ("Charlie", .villager), ("Dave", .villager), ("Eve", .villager)
        ])
        gm.turn = 1

        let actions: [String: NightAction] = [
            "Alice": NightAction(type: .seer, target: "Bob"),
        ]

        let results = gm.resolveNightActions(actions)

        XCTAssertEqual(results.victims, ["Bob"])
        XCTAssertTrue(gm.players[0].isAlive)
        XCTAssertFalse(gm.players[1].isAlive)
        XCTAssertEqual(gm.players[1].deathInfo?.turn, 1)
        XCTAssertEqual(gm.players[1].deathInfo?.reason, .curse)
    }

    func testResolveNightActionsSeerKillsLastFoxWithImmoralist() {
        let gm = makeGMWithRoles([
            ("Alice", .seer), ("Bob", .fox),
            ("Charlie", .immoralist), ("Dave", .villager), ("Eve", .villager)
        ])
        gm.turn = 1

        let actions: [String: NightAction] = [
            "Alice": NightAction(type: .seer, target: "Bob"),
        ]

        let results = gm.resolveNightActions(actions)

        XCTAssertEqual(results.victims.sorted(), ["Bob", "Charlie"])
        XCTAssertEqual(results.immoralSuicides.sorted(), ["Charlie"])
        XCTAssertTrue(gm.players[0].isAlive)
        XCTAssertFalse(gm.players[1].isAlive)
        XCTAssertEqual(gm.players[1].deathInfo?.reason, .curse)
        XCTAssertFalse(gm.players[2].isAlive)
        XCTAssertEqual(gm.players[2].deathInfo?.reason, .suicide)
    }

    func testResolveNightActionsWolfAttacksFox() {
        let gm = makeGMWithRoles([
            ("Alice", .werewolf), ("Bob", .fox),
            ("Charlie", .villager), ("Dave", .villager), ("Eve", .villager)
        ])

        let actions: [String: NightAction] = [
            "Alice": NightAction(type: .attack, target: "Bob"),
        ]

        let results = gm.resolveNightActions(actions)

        XCTAssertEqual(results.victims, [])
        XCTAssertTrue(gm.players[1].isAlive) // Bob (妖狐) は生存
    }

    func testResolveNightActionsCombinedSeerAttack() {
        let gm = makeGMWithRoles([
            ("Alice", .seer), ("Bob", .werewolf),
            ("Charlie", .villager), ("Dave", .villager), ("Eve", .villager)
        ])
        gm.turn = 1

        let actions: [String: NightAction] = [
            "Alice": NightAction(type: .seer, target: "Charlie"),
            "Bob": NightAction(type: .attack, target: "Dave"),
        ]

        let results = gm.resolveNightActions(actions)

        XCTAssertEqual(results.victims, ["Dave"])
        XCTAssertTrue(gm.players[0].isAlive)
        XCTAssertTrue(gm.players[1].isAlive)
        XCTAssertTrue(gm.players[2].isAlive)
        XCTAssertFalse(gm.players[3].isAlive)
        XCTAssertEqual(gm.players[3].deathInfo?.reason, .attack)
    }

    func testResolveNightActionsGuardVsCurse() {
        let gm = makeGMWithRoles([
            ("Alice", .seer), ("Bob", .knight),
            ("Charlie", .fox), ("Dave", .villager), ("Eve", .villager)
        ])

        // 1日目夜: 騎士が妖狐を護衛
        gm.turn = 1
        let actions1: [String: NightAction] = [
            "Bob": NightAction(type: .guard, target: "Charlie"),
        ]
        _ = gm.resolveNightActions(actions1)
        XCTAssertTrue(gm.players[2].isAlive)

        // 2日目夜: 占い師が妖狐を占い (呪殺)
        gm.turn = 2
        let actions2: [String: NightAction] = [
            "Alice": NightAction(type: .seer, target: "Charlie"),
        ]
        let results = gm.resolveNightActions(actions2)

        XCTAssertEqual(results.victims, ["Charlie"])
        XCTAssertFalse(gm.players[2].isAlive)
        XCTAssertEqual(gm.players[2].deathInfo?.turn, 2)
        XCTAssertEqual(gm.players[2].deathInfo?.reason, .curse)
    }

    // MARK: - 投票テスト

    func testExecuteDayVoteSimple() {
        let gm = makeGM()
        gm.assignRoles([.villager, .villager, .villager, .werewolf, .werewolf])
        gm.turn = 2

        let votes = ["Alice": 3, "Bob": 1]
        let result = gm.executeDayVote(votes)

        XCTAssertEqual(result.executed, "Alice")
        XCTAssertEqual(gm.lastExecutedName, "Alice")
        XCTAssertEqual(result.immoralSuicides, [])
        XCTAssertNil(result.error)

        let alice = gm.players.first(where: { $0.name == "Alice" })!
        XCTAssertFalse(alice.isAlive)
        XCTAssertEqual(alice.deathInfo?.turn, 2)
        XCTAssertEqual(alice.deathInfo?.reason, .execute)
    }

    func testExecuteDayVoteTie() {
        let gm = makeGM()
        gm.assignRoles([.villager, .villager, .villager, .werewolf, .werewolf])
        gm.turn = 2

        let votes = ["Alice": 2, "Bob": 2, "Charlie": 1]
        let result = gm.executeDayVote(votes)

        XCTAssertTrue(["Alice", "Bob"].contains(result.executed ?? ""))
        XCTAssertNil(result.error)
    }

    func testExecuteDayVoteNoVotes() {
        let gm = makeGM()
        gm.assignRoles([.villager, .villager, .villager, .werewolf, .werewolf])

        let votes: [String: Int] = [:]
        let result = gm.executeDayVote(votes)

        XCTAssertNil(result.executed)
        XCTAssertNil(gm.lastExecutedName)
        XCTAssertEqual(result.immoralSuicides, [])
        XCTAssertNil(result.error)
    }

    func testExecuteDayVoteFoxAndImmoralist() {
        let gm = makeGMWithRoles([
            ("Alice", .fox), ("Bob", .immoralist), ("Charlie", .villager)
        ])
        gm.turn = 2

        let votes = ["Alice": 2, "Charlie": 1]
        let result = gm.executeDayVote(votes)

        XCTAssertEqual(result.executed, "Alice")
        XCTAssertEqual(result.immoralSuicides.sorted(), ["Bob"])
        XCTAssertNil(result.error)

        let alice = gm.players.first(where: { $0.name == "Alice" })!
        let bob = gm.players.first(where: { $0.name == "Bob" })!
        let charlie = gm.players.first(where: { $0.name == "Charlie" })!

        XCTAssertFalse(alice.isAlive)
        XCTAssertEqual(alice.deathInfo?.reason, .execute)
        XCTAssertFalse(bob.isAlive)
        XCTAssertEqual(bob.deathInfo?.reason, .suicide)
        XCTAssertTrue(charlie.isAlive)
    }

    // MARK: - get_game_results テスト

    func testGetGameResultsVillagerWin() {
        let gm = makeGMWithRoles([
            ("Alice", .villager), ("Bob", .villager), ("Charlie", .werewolf)
        ])
        gm.players[2].kill(turn: 1, reason: .attack)
        _ = gm.checkVictory()

        let results = gm.getGameResults()
        XCTAssertEqual(gm.victoryTeam, .villager)
        XCTAssertEqual(results.count, 3)

        XCTAssertEqual(results[0].name, "Alice")
        XCTAssertTrue(results[0].isWinner)
        XCTAssertEqual(results[0].status, "最終日生存")

        XCTAssertEqual(results[1].name, "Bob")
        XCTAssertTrue(results[1].isWinner)

        XCTAssertEqual(results[2].name, "Charlie")
        XCTAssertFalse(results[2].isWinner)
    }

    func testGetGameResultsWerewolfWin() {
        let gm = makeGMWithRoles([
            ("Alice", .werewolf), ("Bob", .villager)
        ])
        _ = gm.checkVictory()

        let results = gm.getGameResults()
        XCTAssertEqual(gm.victoryTeam, .werewolf)
        XCTAssertEqual(results.count, 2)

        XCTAssertTrue(results[0].isWinner) // Alice (人狼)
        XCTAssertFalse(results[1].isWinner) // Bob (村人)
    }

    func testGetGameResultsFoxWin() {
        let gm = makeGMWithRoles([
            ("Alice", .villager), ("Bob", .fox), ("Charlie", .werewolf)
        ])
        gm.players[2].kill(turn: 1, reason: .attack)
        _ = gm.checkVictory()

        let results = gm.getGameResults()
        XCTAssertEqual(gm.victoryTeam, .fox)
        XCTAssertEqual(results.count, 3)

        XCTAssertFalse(results[0].isWinner) // Alice (村人)
        XCTAssertTrue(results[1].isWinner)  // Bob (妖狐)
        XCTAssertFalse(results[2].isWinner) // Charlie (人狼)
    }

    func testGetGameResultsFoxExecuted() {
        let gm = makeGMWithRoles([
            ("Alice", .fox), ("Bob", .immoralist), ("Charlie", .villager)
        ])
        gm.turn = 2
        _ = gm.executeDayVote(["Alice": 1])
        _ = gm.checkVictory()

        XCTAssertEqual(gm.victoryTeam, .villager)

        let results = gm.getGameResults()
        XCTAssertEqual(results.count, 3)

        let alice = results.first(where: { $0.name == "Alice" })!
        XCTAssertFalse(alice.isWinner)
        XCTAssertEqual(alice.status, "2日目 処刑により死亡")

        let bob = results.first(where: { $0.name == "Bob" })!
        XCTAssertFalse(bob.isWinner)
        XCTAssertEqual(bob.status, "2日目 後追死により死亡")

        let charlie = results.first(where: { $0.name == "Charlie" })!
        XCTAssertTrue(charlie.isWinner)
        XCTAssertEqual(charlie.status, "最終日生存")
    }

    // MARK: - 猫又テスト

    func testNekomataRetaliationOnAttack() {
        let gm = makeGMWithRoles([
            ("Alice", .nekomata), ("Bob", .villager),
            ("Charlie", .werewolf), ("Dave", .knight)
        ])
        gm.turn = 1

        let actions: [String: NightAction] = [
            "Charlie": NightAction(type: .attack, target: "Alice"),
        ]

        let result = gm.resolveNightActions(actions)

        let nekomata = gm.players.first(where: { $0.name == "Alice" })!
        let wolf = gm.players.first(where: { $0.name == "Charlie" })!
        let villager = gm.players.first(where: { $0.name == "Bob" })!
        let knight = gm.players.first(where: { $0.name == "Dave" })!

        XCTAssertFalse(nekomata.isAlive)
        XCTAssertEqual(nekomata.deathInfo?.reason, .attack)
        XCTAssertFalse(wolf.isAlive)
        XCTAssertEqual(wolf.deathInfo?.reason, .retaliation)
        XCTAssertTrue(villager.isAlive)
        XCTAssertTrue(knight.isAlive)
        XCTAssertTrue(result.victims.contains("Alice"))
        XCTAssertTrue(result.victims.contains("Charlie"))
    }

    func testNekomataNoRetaliationWhenGuarded() {
        let gm = makeGMWithRoles([
            ("Alice", .nekomata), ("Bob", .villager),
            ("Charlie", .werewolf), ("Dave", .knight)
        ])
        gm.turn = 1

        let actions: [String: NightAction] = [
            "Charlie": NightAction(type: .attack, target: "Alice"),
            "Dave": NightAction(type: .guard, target: "Alice"),
        ]

        let result = gm.resolveNightActions(actions)

        let nekomata = gm.players.first(where: { $0.name == "Alice" })!
        let wolf = gm.players.first(where: { $0.name == "Charlie" })!

        XCTAssertTrue(nekomata.isAlive)
        XCTAssertTrue(wolf.isAlive)
        XCTAssertTrue(result.victims.isEmpty)
    }

    func testNekomataRetaliationOnExecution() {
        let gm = makeGMWithRoles([
            ("Alice", .nekomata), ("Bob", .villager),
            ("Charlie", .werewolf), ("Dave", .knight)
        ])
        gm.turn = 2

        let result = gm.executeDayVote(["Alice": 1])

        let nekomata = gm.players.first(where: { $0.name == "Alice" })!
        XCTAssertFalse(nekomata.isAlive)
        XCTAssertEqual(nekomata.deathInfo?.reason, .execute)

        XCTAssertNotNil(result.retaliationVictim)
        if let victimName = result.retaliationVictim {
            let victim = gm.players.first(where: { $0.name == victimName })!
            XCTAssertFalse(victim.isAlive)
            XCTAssertEqual(victim.deathInfo?.reason, .retaliation)
        }
    }

    func testNekomataVictoryCondition() {
        let gm = makeGMWithRoles([
            ("Alice", .nekomata), ("Bob", .villager),
            ("Charlie", .werewolf), ("Dave", .knight)
        ])
        gm.players[2].kill(turn: 1, reason: .attack)

        _ = gm.checkVictory()
        XCTAssertEqual(gm.victoryTeam, .villager)
    }

    func testGetGameResultsWithNekomata() {
        let gm = makeGMWithRoles([
            ("Alice", .nekomata), ("Bob", .villager),
            ("Charlie", .werewolf), ("Dave", .knight)
        ])

        // 1日目夜: 人狼が猫又を襲撃
        gm.turn = 1
        _ = gm.resolveNightActions([
            "Charlie": NightAction(type: .attack, target: "Alice")
        ])

        // 2日目昼: 村人を処刑
        gm.turn = 2
        _ = gm.executeDayVote(["Bob": 1])

        _ = gm.checkVictory()
        let results = gm.getGameResults()

        XCTAssertEqual(gm.victoryTeam, .villager)

        let resultNekomata = results.first(where: { $0.name == "Alice" })!
        let resultWolf = results.first(where: { $0.name == "Charlie" })!
        let resultVillager = results.first(where: { $0.name == "Bob" })!
        let resultKnight = results.first(where: { $0.name == "Dave" })!

        XCTAssertEqual(resultNekomata.status, "1日目 襲撃により死亡")
        XCTAssertEqual(resultWolf.status, "1日目 道連れにより死亡")
        XCTAssertEqual(resultVillager.status, "2日目 処刑により死亡")
        XCTAssertEqual(resultKnight.status, "最終日生存")
        XCTAssertTrue(resultKnight.isWinner)
    }
}

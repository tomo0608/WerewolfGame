import XCTest
@testable import WerewolfGame

final class PlayerTests: XCTestCase {

    func testPlayerInitialization() {
        let player = Player(id: 0, name: "Alice")
        XCTAssertEqual(player.name, "Alice")
        XCTAssertTrue(player.isAlive)
        XCTAssertEqual(player.role, .villager) // デフォルト
        XCTAssertEqual(player.id, 0)
        XCTAssertNil(player.deathInfo)
    }

    func testPlayerKill() {
        var player = Player(id: 0, name: "Charlie")
        XCTAssertTrue(player.isAlive)

        player.kill(turn: 1, reason: .attack)
        XCTAssertFalse(player.isAlive)
        XCTAssertEqual(player.deathInfo?.turn, 1)
        XCTAssertEqual(player.deathInfo?.reason, .attack)

        // 既に死んでいるプレイヤーを再度 kill しても状態は変わらない
        let deathInfoBefore = player.deathInfo
        player.kill(turn: 2, reason: .execute)
        XCTAssertFalse(player.isAlive)
        XCTAssertEqual(player.deathInfo?.turn, deathInfoBefore?.turn)
        XCTAssertEqual(player.deathInfo?.reason, deathInfoBefore?.reason)
    }

    func testPlayerDisplayString() {
        var playerAlive = Player(id: 3, name: "Dave", role: .knight)
        var playerDead = Player(id: 4, name: "Eve", role: .fox)
        playerDead.kill(turn: 1, reason: .curse)

        // 通常時 (役職非表示)
        XCTAssertEqual(playerAlive.displayString(), "Dave (生存)")
        XCTAssertEqual(playerDead.displayString(), "Eve (1日目 呪殺)")

        // 役職表示時
        XCTAssertEqual(playerAlive.displayString(revealRole: true), "Dave [騎士] (生存)")
        XCTAssertEqual(playerDead.displayString(revealRole: true), "Eve [妖狐] (1日目 呪殺)")
    }
}

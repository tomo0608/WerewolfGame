import XCTest
@testable import WerewolfGame

final class RoleTypeTests: XCTestCase {

    func testVillagerAttributes() {
        let role = RoleType.villager
        XCTAssertEqual(role.rawValue, "村人")
        XCTAssertEqual(role.team, .villager)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertNil(role.actionDescription)
        XCTAssertFalse(role.hasNightAction(turn: 1))
        XCTAssertFalse(role.hasNightAction(turn: 2))
    }

    func testWerewolfAttributes() {
        let role = RoleType.werewolf
        XCTAssertEqual(role.rawValue, "人狼")
        XCTAssertEqual(role.team, .werewolf)
        XCTAssertEqual(role.species, .werewolf)
        XCTAssertEqual(role.seerResult, .werewolf)
        XCTAssertEqual(role.mediumResult, .werewolf)
        XCTAssertEqual(role.actionDescription, "襲撃対象")
        XCTAssertFalse(role.hasNightAction(turn: 1)) // 初日はアクションなし
        XCTAssertTrue(role.hasNightAction(turn: 2))
    }

    func testSeerAttributes() {
        let role = RoleType.seer
        XCTAssertEqual(role.rawValue, "占い師")
        XCTAssertEqual(role.team, .villager)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertEqual(role.actionDescription, "占う対象")
        XCTAssertTrue(role.hasNightAction(turn: 1))
        XCTAssertTrue(role.hasNightAction(turn: 2))
    }

    func testFakeSeerAttributes() {
        let role = RoleType.fakeSeer
        XCTAssertEqual(role.rawValue, "偽占い師")
        XCTAssertEqual(role.team, .villager)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertEqual(role.actionDescription, "占う対象")
        XCTAssertTrue(role.hasNightAction(turn: 1))
        XCTAssertTrue(role.hasNightAction(turn: 2))
        // displayName は「占い師」と表示
        XCTAssertEqual(role.displayName, "占い師")
    }

    func testMediumAttributes() {
        let role = RoleType.medium
        XCTAssertEqual(role.rawValue, "霊媒師")
        XCTAssertEqual(role.team, .villager)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertNil(role.actionDescription)
        XCTAssertFalse(role.hasNightAction(turn: 1))
        XCTAssertTrue(role.hasNightAction(turn: 2))
    }

    func testKnightAttributes() {
        let role = RoleType.knight
        XCTAssertEqual(role.rawValue, "騎士")
        XCTAssertEqual(role.team, .villager)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertEqual(role.actionDescription, "守る対象")
        XCTAssertFalse(role.hasNightAction(turn: 1))
        XCTAssertTrue(role.hasNightAction(turn: 2))
    }

    func testNekomataAttributes() {
        let role = RoleType.nekomata
        XCTAssertEqual(role.rawValue, "猫又")
        XCTAssertEqual(role.team, .villager)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertFalse(role.hasNightAction(turn: 1))
    }

    func testMadmanAttributes() {
        let role = RoleType.madman
        XCTAssertEqual(role.rawValue, "狂人")
        XCTAssertEqual(role.team, .werewolf)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertNil(role.actionDescription)
        XCTAssertFalse(role.hasNightAction(turn: 1))
        XCTAssertFalse(role.hasNightAction(turn: 2))
    }

    func testFanaticAttributes() {
        let role = RoleType.fanatic
        XCTAssertEqual(role.rawValue, "狂信者")
        XCTAssertEqual(role.team, .werewolf)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertNil(role.actionDescription)
        XCTAssertFalse(role.hasNightAction(turn: 1))
        XCTAssertFalse(role.hasNightAction(turn: 2))
    }

    func testFoxAttributes() {
        let role = RoleType.fox
        XCTAssertEqual(role.rawValue, "妖狐")
        XCTAssertEqual(role.team, .fox)
        XCTAssertEqual(role.species, .fox)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertNil(role.actionDescription)
        XCTAssertFalse(role.hasNightAction(turn: 1))
        XCTAssertFalse(role.hasNightAction(turn: 2))
    }

    // MARK: - 初日占い設定テスト

    func testSeerHasNightActionWithFirstDaySeerEnabled() {
        let rules = HouseRules(firstDaySeer: .enabled)
        XCTAssertTrue(RoleType.seer.hasNightAction(turn: 1, houseRules: rules))
        XCTAssertTrue(RoleType.seer.hasNightAction(turn: 2, houseRules: rules))
        XCTAssertTrue(RoleType.fakeSeer.hasNightAction(turn: 1, houseRules: rules))
    }

    func testSeerHasNoNightActionWithFirstDaySeerDisabled() {
        let rules = HouseRules(firstDaySeer: .disabled)
        XCTAssertFalse(RoleType.seer.hasNightAction(turn: 1, houseRules: rules))
        XCTAssertTrue(RoleType.seer.hasNightAction(turn: 2, houseRules: rules))
        XCTAssertFalse(RoleType.fakeSeer.hasNightAction(turn: 1, houseRules: rules))
        XCTAssertTrue(RoleType.fakeSeer.hasNightAction(turn: 2, houseRules: rules))
    }

    func testSeerHasNightActionWithFirstDaySeerRandomWhite() {
        let rules = HouseRules(firstDaySeer: .randomWhite)
        // randomWhite still has a night action (shows random white result)
        XCTAssertTrue(RoleType.seer.hasNightAction(turn: 1, houseRules: rules))
        XCTAssertTrue(RoleType.seer.hasNightAction(turn: 2, houseRules: rules))
        XCTAssertTrue(RoleType.fakeSeer.hasNightAction(turn: 1, houseRules: rules))
    }

    func testFirstDaySeerOptionDoesNotAffectOtherRoles() {
        let rules = HouseRules(firstDaySeer: .disabled)
        XCTAssertFalse(RoleType.werewolf.hasNightAction(turn: 1, houseRules: rules))
        XCTAssertTrue(RoleType.werewolf.hasNightAction(turn: 2, houseRules: rules))
        XCTAssertFalse(RoleType.villager.hasNightAction(turn: 1, houseRules: rules))
    }

    func testImmoralistAttributes() {
        let role = RoleType.immoralist
        XCTAssertEqual(role.rawValue, "背徳者")
        XCTAssertEqual(role.team, .fox)
        XCTAssertEqual(role.species, .villager)
        XCTAssertEqual(role.seerResult, .villager)
        XCTAssertEqual(role.mediumResult, .notWerewolf)
        XCTAssertNil(role.actionDescription)
        XCTAssertFalse(role.hasNightAction(turn: 1))
        XCTAssertFalse(role.hasNightAction(turn: 2))
    }
}

import Foundation

enum GameSettings {
    static let defaultRoleCounts: [RoleType: Int] = [
        .werewolf: 2,
        .villager: 2,
        .seer: 1,
        .medium: 1,
        .knight: 1,
        .madman: 1,
        .fanatic: 0,
        .fox: 0,
        .immoralist: 0,
        .fakeSeer: 0,
        .nekomata: 0,
    ]

    static let defaultPlayerCount: Int = defaultRoleCounts.values.reduce(0, +)

    static let minPlayers: Int = 3
}

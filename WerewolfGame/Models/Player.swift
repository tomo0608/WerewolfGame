import Foundation

struct Player: Identifiable, Codable {
    let id: Int
    let name: String
    var role: RoleType
    var isAlive: Bool = true
    var deathInfo: DeathInfo? = nil

    init(id: Int, name: String, role: RoleType = .villager) {
        self.id = id
        self.name = name
        self.role = role
    }

    mutating func kill(turn: Int, reason: DeathReason) {
        guard isAlive else { return }
        isAlive = false
        deathInfo = DeathInfo(turn: turn, reason: reason)
    }

    /// 表示用の文字列
    func displayString(revealRole: Bool = false) -> String {
        let status: String
        if !isAlive, let info = deathInfo {
            status = "\(info.turn)日目 \(info.reason.displayName)"
        } else if !isAlive {
            status = "死亡(詳細不明)"
        } else {
            status = "生存"
        }

        if revealRole {
            return "\(name) [\(role.rawValue)] (\(status))"
        } else {
            return "\(name) (\(status))"
        }
    }
}

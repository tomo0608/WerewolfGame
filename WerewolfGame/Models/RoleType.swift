import Foundation

enum RoleType: String, CaseIterable, Identifiable, Codable {
    case villager = "村人"
    case werewolf = "人狼"
    case seer = "占い師"
    case fakeSeer = "偽占い師"
    case medium = "霊媒師"
    case knight = "騎士"
    case nekomata = "猫又"
    case madman = "狂人"
    case fanatic = "狂信者"
    case fox = "妖狐"
    case immoralist = "背徳者"

    var id: String { rawValue }

    /// 所属陣営
    var team: Team {
        switch self {
        case .villager, .seer, .fakeSeer, .medium, .knight, .nekomata:
            return .villager
        case .werewolf, .madman, .fanatic:
            return .werewolf
        case .fox, .immoralist:
            return .fox
        }
    }

    /// 種族 (勝利判定・占い結果に影響)
    var species: Species {
        switch self {
        case .villager, .seer, .fakeSeer, .medium, .knight, .nekomata,
             .madman, .fanatic, .immoralist:
            return .villager
        case .werewolf:
            return .werewolf
        case .fox:
            return .fox
        }
    }

    /// 占い師が見た場合の結果
    var seerResult: SeerResult {
        switch self {
        case .werewolf:
            return .werewolf
        default:
            return .villager
        }
    }

    /// 霊媒師が見た場合の結果
    var mediumResult: MediumResult {
        switch self {
        case .werewolf:
            return .werewolf
        default:
            return .notWerewolf
        }
    }

    /// 夜アクションの説明ラベル (nilならアクションなし)
    var actionDescription: String? {
        switch self {
        case .werewolf: return "襲撃対象"
        case .seer, .fakeSeer: return "占う対象"
        case .knight: return "守る対象"
        default: return nil
        }
    }

    /// UI上に表示する役職名 (偽占い師は「占い師」と表示)
    var displayName: String {
        switch self {
        case .fakeSeer: return "占い師"
        default: return rawValue
        }
    }

    /// 指定ターンで夜アクションを持つかどうか
    func hasNightAction(turn: Int, houseRules: HouseRules = HouseRules()) -> Bool {
        switch self {
        case .seer, .fakeSeer:
            if turn == 1 && houseRules.firstDaySeer == .disabled {
                return false
            }
            return true
        case .werewolf, .knight:
            return turn > 1
        case .medium:
            return turn > 1
        default:
            return false
        }
    }

    /// 偽占い師のランダム結果
    func fakeSeerResult() -> String {
        return Bool.random() ? "人狼" : "人狼ではない"
    }
}

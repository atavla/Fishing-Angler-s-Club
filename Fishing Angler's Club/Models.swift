import Foundation

struct AppData: Codable {
    var displayName = "Guest Angler"
    var experience = 0
    var lastQuizDate: Date?
    var quizScore = 0
    var bonuses: [RewardBonus] = []
}

struct QuizQuestion: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let answers: [String]
    let correctIndex: Int

    init(text: String, answers: [String], correctIndex: Int) {
        id = UUID()
        self.text = text
        self.answers = answers
        self.correctIndex = correctIndex
    }
}

enum BonusKind: String, Codable, CaseIterable, Identifiable {
    case freeSpins
    case cash
    case multiplier
    case merch
    case depositMatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freeSpins: "10 Free Spins"
        case .cash: "$10 Bonus Cash"
        case .multiplier: "2x Loyalty Boost"
        case .merch: "IceFishing Winter Hat"
        case .depositMatch: "100% Deposit Match"
        }
    }

    var details: String {
        switch self {
        case .freeSpins: "10 complimentary IceFishing rounds in demo mode."
        case .cash: "$10 promotional balance with a x30 wagering requirement."
        case .multiplier: "Double loyalty points for the next two hours."
        case .merch: "A branded winter hat available from the club desk."
        case .depositMatch: "Match your next deposit up to $50."
        }
    }

    var assetName: String {
        switch self {
        case .freeSpins: "bonus_free_spins"
        case .cash: "bonus_cash"
        case .multiplier: "bonus_multiplier"
        case .merch: "bonus_merch"
        case .depositMatch: "bonus_deposit_match"
        }
    }
}

struct RewardBonus: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: BonusKind
    let createdAt: Date
    let expiresAt: Date
    let redemptionSeed: String
    var isRevealed: Bool
    var usedAt: Date?

    var isExpired: Bool { expiresAt <= Date() }
    var isArchived: Bool { usedAt != nil || isExpired }

    static func random() -> RewardBonus {
        let kind = BonusKind.allCases.randomElement() ?? .freeSpins
        return RewardBonus(
            id: UUID(),
            kind: kind,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .hour, value: 48, to: Date()) ?? Date(),
            redemptionSeed: UUID().uuidString,
            isRevealed: false
        )
    }
}

enum AppTab: Hashable {
    case home
    case catchBox
    case guide
    case settings
}

enum QuizAnswerState: Equatable {
    case unanswered
    case correct(selected: Int)
    case incorrect(selected: Int, correct: Int)
    case timedOut(correct: Int)
}

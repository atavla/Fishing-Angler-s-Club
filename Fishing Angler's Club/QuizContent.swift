import Foundation

enum QuizContent {
    static let questions: [QuizQuestion] = [
        QuizQuestion(text: "How many segments are on the IceFishing wheel?", answers: ["30", "45", "53", "60"], correctIndex: 2),
        QuizQuestion(text: "What is the maximum multiplier in IceFishing?", answers: ["x100", "x1,000", "x5,000", "x10,000"], correctIndex: 2),
        QuizQuestion(text: "How many bonus rounds are available?", answers: ["2", "3", "4", "5"], correctIndex: 1),
        QuizQuestion(text: "Which bonus round has the lowest volatility?", answers: ["Lil' Blues", "Big Oranges", "Huge Reds", "Mega Whites"], correctIndex: 0),
        QuizQuestion(text: "Which bonus round offers the highest multipliers?", answers: ["Lil' Blues", "Big Oranges", "Huge Reds", "All are equal"], correctIndex: 2),
        QuizQuestion(text: "What happens when the wheel lands on a bonus segment?", answers: ["Instant payout", "A fishing mini-game begins", "All bets double", "The game ends"], correctIndex: 1),
        QuizQuestion(text: "Which tool is normally used to pull fish from the ice holes?", answers: ["Net", "Hook pole", "Fishing rod", "Harpoon"], correctIndex: 2),
        QuizQuestion(text: "What do green Leaf segments represent?", answers: ["Instant loss", "Multipliers or bonus access", "Free spins only", "Jackpot"], correctIndex: 1),
        QuizQuestion(text: "What is the approximate RTP of IceFishing?", answers: ["94.50%", "95.80%", "96.10%", "97.20%"], correctIndex: 2),
        QuizQuestion(text: "What may appear for a very large Huge Reds multiplier?", answers: ["Nothing special", "A crane or helicopter", "A second wheel", "A doubled fish"], correctIndex: 1),
        QuizQuestion(text: "Which segments can players bet on in the main round?", answers: ["Bonuses only", "Multipliers only", "Wheel segments", "Fish colors only"], correctIndex: 2),
        QuizQuestion(text: "What is an instant win?", answers: ["A bonus round", "A payout from a specific wheel segment", "A free game", "A jackpot"], correctIndex: 1),
        QuizQuestion(text: "Which fish is linked to Lil' Blues?", answers: ["Small blue fish", "Medium orange fish", "Large red fish", "Golden fish"], correctIndex: 0),
        QuizQuestion(text: "How often do bonus rounds occur on average?", answers: ["Every 5 spins", "Every 10–15 spins", "Every 50 spins", "Once per hour"], correctIndex: 1),
        QuizQuestion(text: "How are multipliers assigned during bonus rounds?", answers: ["They are fixed", "Randomly to fish in the holes", "By time of day", "They are not used"], correctIndex: 1),
        QuizQuestion(text: "Can players bet on several wheel segments at once?", answers: ["Yes", "No", "Bonuses only", "Leaves only"], correctIndex: 0),
        QuizQuestion(text: "What is the stated minimum Huge Reds multiplier?", answers: ["x1", "x10", "x50", "x100"], correctIndex: 2),
        QuizQuestion(text: "What happens on a gray segment?", answers: ["Bonus round", "Instant bet payout", "All bets lose", "Free spin"], correctIndex: 1),
        QuizQuestion(text: "Who hosts IceFishing?", answers: ["Anna", "Maria", "The host changes by broadcast", "There is no host"], correctIndex: 2),
        QuizQuestion(text: "Can IceFishing be played in demo mode?", answers: ["Yes, at many online casinos", "No", "Only after registration", "Mobile only"], correctIndex: 0)
    ]

    static func dailyQuestions() -> [QuizQuestion] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        var generator = SeededGenerator(seed: UInt64(day))
        return Array(questions.shuffled(using: &generator).prefix(5))
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

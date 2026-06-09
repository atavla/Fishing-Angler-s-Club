import Combine
import Foundation
import UIKit

final class AppStore {
    private let fileManager = FileManager.default
    private let sessionKey = "reviewer_session_active"

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var dataURL: URL {
        documentsDirectory.appendingPathComponent("angler_data.json")
    }

    private var avatarURL: URL {
        documentsDirectory.appendingPathComponent("angler_avatar.jpg")
    }

    func load() throws -> AppData {
        guard fileManager.fileExists(atPath: dataURL.path) else {
            return AppData()
        }
        let data = try Data(contentsOf: dataURL)
        return try JSONDecoder().decode(AppData.self, from: data)
    }

    func save(_ appData: AppData) throws {
        let data = try JSONEncoder().encode(appData)
        try data.write(to: dataURL, options: .atomic)
    }

    func loadSession() -> Bool {
        UserDefaults.standard.bool(forKey: sessionKey)
    }

    func saveSession(isActive: Bool) {
        UserDefaults.standard.set(isActive, forKey: sessionKey)
    }

    func loadAvatar() -> UIImage? {
        guard let data = try? Data(contentsOf: avatarURL) else { return nil }
        return UIImage(data: data)
    }

    func saveAvatar(_ image: UIImage) throws {
        let targetSize = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let squareImage = renderer.image { _ in
            let side = min(image.size.width, image.size.height)
            let origin = CGPoint(
                x: (image.size.width - side) / 2,
                y: (image.size.height - side) / 2
            )
            guard let cgImage = image.cgImage?.cropping(
                to: CGRect(origin: origin, size: CGSize(width: side, height: side))
            ) else {
                image.draw(in: CGRect(origin: .zero, size: targetSize))
                return
            }
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let data = squareImage.jpegData(compressionQuality: 0.82) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: avatarURL, options: .atomic)
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var data = AppData()
    @Published private(set) var avatarImage: UIImage?
    @Published private(set) var isAuthenticated = false
    @Published var selectedTab: AppTab = .home
    @Published var presentedScratchBonus: RewardBonus?
    @Published var storageErrorMessage: String?

    private let store = AppStore()

    static let reviewerEmail = "reviewer@anglersclub.app"
    static let reviewerPassword = "review111"

    init() {
        do {
            data = try store.load()
        } catch {
            storageErrorMessage = "Your saved data could not be loaded. A fresh reviewer profile is being used."
        }
        if data.displayName == "Guest Angler" {
            data.displayName = "Reviewer"
            persist()
        }
        avatarImage = store.loadAvatar()
        isAuthenticated = store.loadSession()
    }

    var quizCompletedToday: Bool {
        guard let lastQuizDate = data.lastQuizDate else { return false }
        return Calendar.current.isDateInToday(lastQuizDate)
    }

    var activeBonuses: [RewardBonus] {
        data.bonuses
            .filter { !$0.isArchived }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var archivedBonuses: [RewardBonus] {
        data.bonuses
            .filter(\.isArchived)
            .sorted { $0.createdAt > $1.createdAt }
    }

    func updateDisplayName(_ name: String) {
        data.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    func logIn(email: String, password: String) -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail == Self.reviewerEmail, password == Self.reviewerPassword else {
            return false
        }
        isAuthenticated = true
        store.saveSession(isActive: true)
        return true
    }

    func logOut() {
        presentedScratchBonus = nil
        selectedTab = .home
        isAuthenticated = false
        store.saveSession(isActive: false)
    }

    func updateAvatar(with data: Data) {
        guard let image = UIImage(data: data) else {
            storageErrorMessage = "That photo could not be used. Please choose another image."
            return
        }
        do {
            try store.saveAvatar(image)
            avatarImage = store.loadAvatar()
        } catch {
            storageErrorMessage = "The avatar could not be saved. Please try again."
        }
    }

    func completeQuiz(score: Int) -> RewardBonus? {
        data.lastQuizDate = Date()
        data.quizScore = score
        data.experience += score * 10

        var reward: RewardBonus?
        if score == 5 {
            data.experience += 50
            let bonus = RewardBonus.random()
            data.bonuses.append(bonus)
            reward = bonus
        }
        persist()
        return reward
    }

    func revealBonus(_ bonus: RewardBonus) {
        guard let index = data.bonuses.firstIndex(where: { $0.id == bonus.id }) else { return }
        data.bonuses[index].isRevealed = true
        persist()
    }

    func markBonusUsed(_ bonus: RewardBonus) {
        guard let index = data.bonuses.firstIndex(where: { $0.id == bonus.id }) else { return }
        data.bonuses[index].usedAt = Date()
        persist()
    }

    func bonus(withID id: UUID) -> RewardBonus? {
        data.bonuses.first { $0.id == id }
    }

    private func persist() {
        do {
            try store.save(data)
        } catch {
            storageErrorMessage = "Your latest changes could not be saved. Please try again."
        }
    }
}

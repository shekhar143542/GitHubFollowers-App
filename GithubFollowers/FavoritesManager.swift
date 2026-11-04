import Foundation
import GitHubNetworking
import OSLog

nonisolated struct FavoriteUser: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let login: String
    let avatarURL: URL
    let htmlURL: URL

    init(id: Int, login: String, avatarURL: URL, htmlURL: URL) {
        self.id = id
        self.login = login
        self.avatarURL = avatarURL
        self.htmlURL = htmlURL
    }

    init(from user: GitHubUser) {
        self.id = user.id
        self.login = user.login
        self.avatarURL = user.avatarURL
        self.htmlURL = user.htmlURL
    }
}

final class FavoritesManager: Sendable {
    static let shared = FavoritesManager()

    private let defaults = UserDefaults.standard
    private let favoritesKey = "gh_favorites"
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "GithubFollowers",
        category: "FavoritesManager"
    )

    private init() {}

    func getFavorites() -> [FavoriteUser] {
        guard let data = defaults.data(forKey: favoritesKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([FavoriteUser].self, from: data)
        } catch {
            logger.error("Failed to decode favorites: \(error.localizedDescription)")
            return []
        }
    }

    func addFavorite(_ user: GitHubUser) {
        let favorite = FavoriteUser(from: user)
        addFavorite(favorite)
    }

    func addFavorite(_ favorite: FavoriteUser) {
        var favorites = getFavorites()
        guard !favorites.contains(where: { $0.id == favorite.id }) else {
            return
        }
        favorites.append(favorite)
        save(favorites: favorites)
    }

    func removeFavorite(_ favorite: FavoriteUser) {
        var favorites = getFavorites()
        favorites.removeAll { $0.id == favorite.id }
        save(favorites: favorites)
    }

    private func save(favorites: [FavoriteUser]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            defaults.set(data, forKey: favoritesKey)
        } catch {
            logger.error("Failed to save favorites: \(error.localizedDescription)")
        }
    }
}


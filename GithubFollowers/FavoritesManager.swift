import Foundation
import GitHubNetworking

public nonisolated struct FavoriteUser: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let login: String
    public let avatarURL: URL
    public let htmlURL: URL

    public init(id: Int, login: String, avatarURL: URL, htmlURL: URL) {
        self.id = id
        self.login = login
        self.avatarURL = avatarURL
        self.htmlURL = htmlURL
    }

    public init(from user: GitHubUser) {
        self.id = user.id
        self.login = user.login
        self.avatarURL = user.avatarURL
        self.htmlURL = user.htmlURL
    }
}

public final class FavoritesManager: @unchecked Sendable {
    public static let shared = FavoritesManager()

    private let defaults = UserDefaults.standard
    private let favoritesKey = "gh_favorites"

    private init() {}

    public func getFavorites() -> [FavoriteUser] {
        guard let data = defaults.data(forKey: favoritesKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([FavoriteUser].self, from: data)
        } catch {
            print("Failed to decode favorites: \(error)")
            return []
        }
    }

    public func addFavorite(_ user: GitHubUser) {
        let favorite = FavoriteUser(from: user)
        addFavorite(favorite)
    }

    public func addFavorite(_ favorite: FavoriteUser) {
        var favorites = getFavorites()
        guard !favorites.contains(where: { $0.id == favorite.id }) else {
            return
        }
        favorites.append(favorite)
        save(favorites: favorites)
    }

    public func removeFavorite(_ favorite: FavoriteUser) {
        var favorites = getFavorites()
        favorites.removeAll { $0.id == favorite.id }
        save(favorites: favorites)
    }

    private func save(favorites: [FavoriteUser]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            defaults.set(data, forKey: favoritesKey)
        } catch {
            print("Failed to save favorites: \(error)")
        }
    }
}

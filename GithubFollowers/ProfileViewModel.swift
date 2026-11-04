
import Foundation
import GitHubNetworking
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published private(set) var user: GitHubUser?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let api = GitHubAPIClient()
    private let username: String

    init(username: String, user: GitHubUser? = nil) {
        self.username = username
        self.user = user
    }

    func loadProfile() async {
        guard user == nil else { return }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            user = try await api.fetchUser(
                username: username
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


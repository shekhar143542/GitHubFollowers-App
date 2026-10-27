
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

    init(username: String) {
        self.username = username
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            user = try await api.fetchUser(
                username: username
            )
        } catch GitHubAPIError.userNotFound {
            errorMessage = "GitHub user not found."
        } catch GitHubAPIError.rateLimitExceeded {
            errorMessage = "GitHub API rate limit reached."
        } catch {
            errorMessage = "Unable to load profile. Please try again."
        }
    }
}


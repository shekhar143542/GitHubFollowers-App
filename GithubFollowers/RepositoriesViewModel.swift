
import Foundation
import Combine
import GitHubNetworking

@MainActor
final class RepositoriesViewModel: ObservableObject {

    @Published private(set) var repositories: [GitHubRepository] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let api = GitHubAPIClient()
    private let username: String

    private var currentPage = 1
    private var hasMoreRepositories = true

    init(username: String) {
        self.username = username
    }

    func loadRepositories() async {
        guard !isLoading, hasMoreRepositories else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let newRepositories = try await api.fetchRepositories(
                username: username,
                page: currentPage
            )

            repositories.append(contentsOf: newRepositories)

            hasMoreRepositories = newRepositories.count == 100

            if hasMoreRepositories {
                currentPage += 1
            }
        } catch GitHubAPIError.userNotFound {
            errorMessage = "GitHub user not found."
        } catch GitHubAPIError.rateLimitExceeded {
            errorMessage = "GitHub API rate limit reached. Please try again later."
        } catch {
            errorMessage = "Unable to load repositories. Please try again."
        }
    }
}

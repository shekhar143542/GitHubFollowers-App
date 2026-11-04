import Foundation

public enum GitHubAPIError: Error {
    case invalidURL
    case invalidResponse
    case userNotFound
    case rateLimitExceeded
    case requestFailed(statusCode: Int)
}

public struct GitHubAPIClient {

    public init() {

    }

    public func fetchUser(username: String) async throws -> GitHubUser {
        try await request(
            urlString: "https://api.github.com/users/\(username)"
        )
    }

    public func fetchFollowers(
        username: String,
        page: Int
    ) async throws -> [GitHubUser] {
        try await request(
            urlString: "https://api.github.com/users/\(username)/followers?per_page=100&page=\(page)"
        )
    }

    public func fetchRepositories(
        username: String,
        page: Int = 1
    ) async throws -> [GitHubRepository] {
        try await request(
            urlString: "https://api.github.com/users/\(username)/repos?per_page=100&page=\(page)&sort=updated"
        )
    }

    private func request<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw GitHubAPIError.invalidURL
        }
        return try await request(from: url)
    }

    private func request<T: Decodable>(from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        let statusCode = httpResponse.statusCode

        if statusCode == 404 {
            throw GitHubAPIError.userNotFound
        }

        if statusCode == 403 || statusCode == 429 {
            let remaining = httpResponse.value(
                forHTTPHeaderField: "X-RateLimit-Remaining"
            )

            if statusCode == 429 || remaining == "0" {
                throw GitHubAPIError.rateLimitExceeded
            }
        }

        guard (200..<300).contains(statusCode) else {
            throw GitHubAPIError.requestFailed(
                statusCode: statusCode
            )
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

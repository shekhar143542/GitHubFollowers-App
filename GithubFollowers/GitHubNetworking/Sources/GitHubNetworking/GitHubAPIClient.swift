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
        let validUsername = try validateUsername(username)
        let url = try makeURL(path: "/users/\(validUsername)")
        return try await request(from: url)
    }

    public func fetchFollowers(
        username: String,
        page: Int
    ) async throws -> [GitHubUser] {
        let validUsername = try validateUsername(username)
        let queryItems = [
            URLQueryItem(name: "per_page", value: "100"),
            URLQueryItem(name: "page", value: String(page))
        ]
        let url = try makeURL(
            path: "/users/\(validUsername)/followers",
            queryItems: queryItems
        )
        return try await request(from: url)
    }

    public func fetchRepositories(
        username: String,
        page: Int = 1
    ) async throws -> [GitHubRepository] {
        let validUsername = try validateUsername(username)
        let queryItems = [
            URLQueryItem(name: "per_page", value: "100"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sort", value: "updated")
        ]
        let url = try makeURL(
            path: "/users/\(validUsername)/repos",
            queryItems: queryItems
        )
        return try await request(from: url)
    }

    private func validateUsername(_ username: String) throws -> String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw GitHubAPIError.invalidURL
        }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        guard trimmed.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            throw GitHubAPIError.invalidURL
        }

        return trimmed
    }

    private func makeURL(
        path: String,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = path
        components.queryItems = queryItems?.isEmpty == false ? queryItems : nil

        guard let url = components.url else {
            throw GitHubAPIError.invalidURL
        }

        return url
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

public enum GitHubAPIError: Error {
    case invalidURL
    case invalidResponse
    case userNotFound
    case rateLimitExceeded
    case requestFailed(statusCode: Int)
}


import Foundation

public struct GitHubAPIClient {

    public init() {

    }
    
    public func fetchUser(username: String) async throws -> GitHubUser {

        //safely handle when the Url is not built succesfully or fails with a invalid url string
        guard let url = URL(string: "https://api.github.com/users/\(username)")
        else{
            throw GitHubAPIError.invalidURL
        }

            let (data, response) = try await URLSession.shared.data(from: url)
        
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

        guard (200..<300).contains(httpResponse.statusCode) else {
                        throw GitHubAPIError.requestFailed(
                            statusCode: httpResponse.statusCode
                )
            }

            let user = try JSONDecoder().decode(GitHubUser.self, from: data)

            return user
        }
    
    
    public func fetchFollowers(
        username: String,
        page: Int
    ) async throws -> [GitHubUser] {

        guard let url = URL(
            string: "https://api.github.com/users/\(username)/followers?per_page=100&page=\(page)"
        ) else {
            throw GitHubAPIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

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

        return try JSONDecoder().decode(
            [GitHubUser].self,
            from: data
        )
    }
    
    
    public func fetchRepositories(
        username: String,
        page: Int = 1
    ) async throws -> [GitHubRepository] {

        guard let url = URL(
            string: "https://api.github.com/users/\(username)/repos?per_page=100&page=\(page)&sort=updated"
        ) else {
            throw GitHubAPIError.invalidURL
        }

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

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(
                [GitHubRepository].self,
                from: data
            )

        case 404:
            throw GitHubAPIError.userNotFound

        case 403, 429:
            throw GitHubAPIError.rateLimitExceeded

        default:
            throw GitHubAPIError.requestFailed(
                statusCode: httpResponse.statusCode
            )
        }
    }



}

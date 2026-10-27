
import Foundation

public struct GitHubRepository: Decodable, Identifiable, Hashable, Sendable {

    public let id: Int
    public let name: String
    public let description: String?
    public let language: String?
    public let stargazersCount: Int
    public let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case language
        case stargazersCount = "stargazers_count"
        case htmlURL = "html_url"
    }
}

//
//  GitHubUser.swift
//  GitHubNetworking
//
//  Created by Kubbireddy Soma Chinna Shekhar on 23/10/26.
//



import Foundation

public struct GitHubUser: Decodable, Identifiable, Hashable {
    public let id: Int
    public let login: String
    public let avatarURL: URL
    public let htmlURL: URL
    public let name: String?
    public let bio: String?
    public let followers: Int?
    public let following: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case name
        case bio
        case followers
        case following
    }
}

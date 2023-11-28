//
//  Models+Codable.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

extension UserCreationParams: Encodable {
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname = "nickname"
        case profileURL = "profile_url"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encode(self.nickname, forKey: .nickname)
        try container.encode(self.profileURL, forKey: .profileURL)
    }
    
    public static func create(userId: String, nickname: String, profileURL: String?) -> UserCreationParams {
        UserCreationParams(userId: userId, nickname: nickname, profileURL: profileURL)
    }
}

extension SBUser: Decodable {
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname = "nickname"
        case profileURL = "profile_url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.nickname = try? container.decode(String.self, forKey: .nickname)
        self.profileURL = try? container.decode(String.self, forKey: .profileURL)
    }
}

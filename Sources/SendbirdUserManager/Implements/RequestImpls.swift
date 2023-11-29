//
//  RequestImpls.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

struct GetUserRequest: Request, RequestProperties {
    typealias Response = SBUser
    
    let userId: String

    var method: SBApiRequestMethod { .get }
    var endpoint: String { "/users/\(userId)" }
    var queryParams: Encodable? { nil }
    var bodyParams: Encodable? { nil }
}

struct GetUsersResponse: Decodable {
    let users: [SBUser]
    let next: String
}

struct GetUsersRequest: Request, RequestProperties {
    typealias Response = GetUsersResponse

    var method: SBApiRequestMethod { .get }
    var endpoint: String { "/users" }
    var queryParams: Encodable?
    var bodyParams: Encodable? { nil }
}

struct CreateUserRequest: Request, RequestProperties {
    typealias Response = SBUser
    
    var method: SBApiRequestMethod { .post }
    var endpoint: String { "/users" }
    var queryParams: Encodable? { nil }
    var bodyParams: Encodable?
}

struct UpdateUserRequest: Request, RequestProperties {
    typealias Response = SBUser
    
    let userId: String
    
    var method: SBApiRequestMethod { .put }
    var endpoint: String { "/users/\(userId)" }
    var queryParams: Encodable? { nil }
    var bodyParams: Encodable?
}

//
//  RequestImpls.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

// MARK: - Request implements
struct CreateUserRequest: Request {
    typealias Response = SBUser
    
    var method: RequestMethod { .post }
    var endpoint: String { "/users" }
    var queryParams: [String: String] { [:] }
    var bodyParams: Encodable?
}

struct UpdateUserRequest: Request {
    typealias Response = SBUser
    
    let userId: String
    
    var method: RequestMethod { .put }
    var endpoint: String { "/users/\(userId)" }
    var queryParams: [String: String] { [:] }
    var bodyParams: Encodable?
}

struct GetUserRequest: Request {
    typealias Response = SBUser
    
    let userId: String

    var method: RequestMethod { .get }
    var endpoint: String { "/users/\(userId)" }
    var queryParams: [String: String] { [:] }
    var bodyParams: Encodable? { nil }
}

struct GetUsersResponse: Decodable {
    let users: [SBUser]
    let next: String
}

struct GetUsersRequest: Request {
    typealias Response = GetUsersResponse

    var method: RequestMethod { .get }
    var endpoint: String { "/users" }
    var queryParams: [String: String]
    var bodyParams: Encodable? { nil }
}

// MARK: - extension
extension Request {
    func url(applicationId: String) throws -> URL? {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api-\(applicationId).sendbird.com"
        urlComponents.path = "/v3".appending(endpoint)
        if !queryParams.isEmpty {
            urlComponents.queryItems = queryParams.map {
                .init(name: $0.key, value: $0.value)
            }
        }
        
        return urlComponents.url
    }
    
    func urlRequest(applicationId: String, apiToken: String) throws -> URLRequest? {
        
        guard let url = try url(applicationId: applicationId) else { return nil }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = [
            "Content-Type": "application/json; charset=utf8",
            "Api-Token": apiToken
        ]
        if let bodyParams = try bodyParams?.toDictionary(), !bodyParams.isEmpty {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: bodyParams)
        }
        return urlRequest
    }
}


//
//  RequestProperties.swift
//  
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

enum SBApiRequestMethod: String {
    case get, post, put
}

protocol RequestProperties {
    var method: SBApiRequestMethod { get }
    var endpoint: String { get }
    var queryParams: Encodable? { get }
    var bodyParams: Encodable? { get }
}

extension RequestProperties {
    func urlRequest(applicationId: String, apiToken: String) throws -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api-\(applicationId).sendbird.com"
        urlComponents.path = "/v3".appending(endpoint)
        if let queryParams = try queryParams?.toDictionary(), !queryParams.isEmpty {
            urlComponents.queryItems = queryParams.map { .init(name: $0.key, value: "\($0.value)") }
        }
        
        guard let url = urlComponents.url else { return nil }
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

extension Encodable {
    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        let jsonData = try JSONSerialization.jsonObject(with: data)
        return jsonData as? [String: Any]
    }
}

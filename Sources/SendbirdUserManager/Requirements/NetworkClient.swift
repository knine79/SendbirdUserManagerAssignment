//
//  NetworkClient.swift
//  
//
//  Created by Sendbird
//

import Foundation

public enum RequestMethod: String {
    case get, post, put
}

public protocol Request where Response: Decodable {
    associatedtype Response
    
    var method: RequestMethod { get }
    var endpoint: String { get }
    var queryParams: [String: String] { get }
    var bodyParams: Encodable? { get }
}

public protocol SBNetworkClient {
    init()
    
    /// 리퀘스트를 요청하고 리퀘스트에 대한 응답을 받아서 전달합니다
    func request<R: Request>(
        request: R,
        completionHandler: @escaping (Result<R.Response, Error>) -> Void
    )
}

//
//  NetworkClientImpl.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation


public enum SBNetworkError: Error {
    case notInitialized
    case requestFailed
    case httpError(statusCode: Int, apiError: SBApiError?)
    case emptyData
    case decodingFailed
    case unknown
}

public struct SBApiError: Decodable {
    let error: Bool
    let message: String
    let code: Int
}

final class SBNetworkClientImpl: SBNetworkClient {
    
    var applicationId: String?
    var apiToken: String?
    
    func request<R>(request: R, completionHandler: @escaping (Result<R.Response, Error>) -> Void) where R : Request {
        
        guard let applicationId, let apiToken else {
            completionHandler(.failure(SBNetworkError.notInitialized))
            return
        }
        
        guard let urlRequest = try? (request as? RequestProperties)?.urlRequest(applicationId: applicationId, apiToken: apiToken) else {
            completionHandler(.failure(SBNetworkError.requestFailed))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completionHandler(.failure(SBNetworkError.unknown))
                return
            }
            
            guard let data = data else {
                completionHandler(.failure(SBNetworkError.emptyData))
                return
            }
            
            guard (200...299).contains(response.statusCode) else {
                let apiError = try? JSONDecoder().decode(SBApiError.self, from: data)
                completionHandler(.failure(SBNetworkError.httpError(statusCode: response.statusCode, apiError: apiError)))
                return
            }
            
            guard let type = R.Response.self as? Decodable.Type, let decoded = try? JSONDecoder().decode(type, from: data) as? R.Response else {
                completionHandler(.failure(SBNetworkError.decodingFailed))
                return
            }
            
            completionHandler(.success(decoded))
        }.resume()
    }
}

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
    case throughputLimitExceeded
    case unknown
}

public struct SBApiError: Decodable {
    let error: Bool
    let code: Int
    let message: String
}

final class SBNetworkClientImpl: SBNetworkClient {
    
    var applicationId: String?
    var apiToken: String?
    
    var apiRequestQueue = ApiRequestQueue()
    
    func request<R>(request: R, completionHandler: @escaping (Result<R.Response, Error>) -> Void) where R : Request {
        
        guard let applicationId, let apiToken else {
            completionHandler(.failure(SBNetworkError.notInitialized))
            return
        }
        
        guard let urlRequest = try? (request as? RequestProperties)?.urlRequest(applicationId: applicationId, apiToken: apiToken) else {
            completionHandler(.failure(SBNetworkError.requestFailed))
            return
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) {
            completionHandler(self.dataTaskResult($0, $1, $2))
        }
        
        do {
            try apiRequestQueue.enqueue(task)
        } catch {
            if error as? ApiRequestQueueError == .queueFull {
                completionHandler(.failure(SBNetworkError.throughputLimitExceeded))
            } else {
                completionHandler(.failure(SBNetworkError.unknown))
            }
        }
    }
}

extension SBNetworkClientImpl {
    private func dataTaskResult<T: Decodable>(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Result<T, Error> {
        if let error = error {
            return .failure(error)
        }
        
        guard let response = response as? HTTPURLResponse else {
            return .failure(SBNetworkError.unknown)
        }
        
        guard let data = data else {
            return .failure(SBNetworkError.emptyData)
        }
        
        guard (200...299).contains(response.statusCode) else {
            let apiError = try? JSONDecoder().decode(SBApiError.self, from: data)
            return .failure(SBNetworkError.httpError(statusCode: response.statusCode, apiError: apiError))
        }
        
        guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return .failure(SBNetworkError.decodingFailed)
        }
        
        return .success(decoded)
    }
}

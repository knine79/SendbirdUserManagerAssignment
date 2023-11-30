//
//  NetworkClientImpl.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation


public enum SBNetworkError: Error {
    case applicationNotInitialized
    case requestFailed
    case httpError(statusCode: Int, apiError: SBApiError?)
    case emptyData
    case decodingFailed
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
    
    func request<R>(request: R, completionHandler: @escaping (Result<R.Response, Error>) -> Void) where R : Request {
        
        var printError: (Error) -> Void = {
            Log.error("ERROR: \($0)")
        }
        
        do {
            guard let applicationId, let apiToken else {
                throw SBNetworkError.applicationNotInitialized
            }
            
            guard let urlRequest = try? (request as? RequestProperties)?.urlRequest(applicationId: applicationId, apiToken: apiToken) else {
                throw SBNetworkError.requestFailed
            }
            
            printError = {
                Log.error("ERROR: \(urlRequest.url?.absoluteString ?? "")\n\($0)")
            }
            
            Log.info("Request \(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "")")
            let task = URLSession.shared.dataTask(with: urlRequest) {
                do {
                    completionHandler(.success(try self.decodeData($0, $1, $2)))
                } catch {
                    printError(error)
                    completionHandler(.failure(error))
                }
            }
            
            task.resume()
        } catch {
            printError(error)
            completionHandler(.failure(error))
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
    
    private func decodeData<T: Decodable>(_ data: Data?, _ response: URLResponse?, _ error: Error?) throws -> T {
        if let error = error {
            throw error
        }
        
        guard let response = response as? HTTPURLResponse else {
            throw SBNetworkError.unknown
        }
        
        guard let data = data else {
            throw SBNetworkError.emptyData
        }
        
        guard (200...299).contains(response.statusCode) else {
            let apiError = try? JSONDecoder().decode(SBApiError.self, from: data)
            throw SBNetworkError.httpError(statusCode: response.statusCode, apiError: apiError)
        }
        
        guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            throw SBNetworkError.decodingFailed
        }
        
        return decoded
    }
}

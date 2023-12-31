//
//  SendbirdUserManagerTests.swift
//  SendbirdUserManagerTests
//
//  Created by Sendbird
//

import XCTest
@testable import SendbirdUserManager

final class UserManagerTests: UserManagerBaseTests {
    override func userManagerType() -> SBUserManager.Type! {
        MockUserManager.self
    }
}

final class UserStorageTests: UserStorageBaseTests {
    override func userStorageType() -> SBUserStorage.Type! {
        MockUserStorage.self
    }
}

//final class NetworkClientTests: NetworkClientBaseTests {
//    override func networkClientType() -> SBNetworkClient.Type! {
//        MockNetworkClient.self
//    }
//}

typealias MockUserStorage = SBUserStorageImpl

final class MockUserManager: SBUserManagerImpl {
    required init() {
        super.init()
    }
    
    private let _networkClient = MockNetworkClient()
    override var networkClient: SBNetworkClient {
        _networkClient
    }
    
    override func initApplication(applicationId: String, apiToken: String) {
        super.initApplication(applicationId: applicationId, apiToken: apiToken)
    }
}

final class MockNetworkClient: SBNetworkClient {
    
    var userDB: [String: SBUser] = [:]
    
    func request<R>(request: R, completionHandler: @escaping (Result<R.Response, Error>) -> Void) where R : Request {
        
        if let request = request as? CreateUserRequest,
           let params = request.bodyParams as? UserCreationParams {
            
            let user = SBUser(userId: params.userId, nickname: params.nickname, profileURL: params.profileURL)
            userDB[params.userId] = user
            
            completionHandler(.success(user as! R.Response))
            
        } else if let request = request as? UpdateUserRequest,
                  let params = request.bodyParams as? UserUpdateParams {
            
            guard userDB[params.userId] != nil else {
                completionHandler(.failure(NSError(domain: "", code: -1)))
                return
            }
            
            let user = SBUser(userId: params.userId, nickname: params.nickname, profileURL: params.profileURL)
            userDB[params.userId] = user
            
            completionHandler(.success(user as! R.Response))
            
        } else if let request = request as? GetUserRequest {
            
            guard userDB[request.userId] != nil else {
                completionHandler(.failure(NSError(domain: "", code: -1)))
                return
            }
            
            completionHandler(.success(userDB[request.userId] as! R.Response))
            
        } else if let request = request as? GetUsersRequest,
                  let nickname = request.queryParams["nickname"],
                  let limit = request.queryParams["limit"] {
            
            let limit = Int(limit) ?? 10
            let token = request.queryParams["token"] ?? "0"
            
            let filtered = userDB.values.filter {
                $0.nickname?.replacingOccurrences(of: nickname, with: "") != $0.nickname
            }
            
            let startIndex = Int(token) ?? 0
            let pageSize = min(filtered.count - startIndex, limit)
            let endIndex = startIndex + pageSize - 1
            let paged = filtered.isEmpty ? [] : Array(filtered[startIndex...endIndex])
            
            let next = paged.count < userDB.values.count ? "\(endIndex + 1)" : ""
            
            completionHandler(.success(GetUsersResponse(users: paged, next: next) as! R.Response))
        }
    }
}

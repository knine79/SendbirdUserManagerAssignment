//
//  UserManagerImpl.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

public enum SBUserManagerError: Error {
    case creationLimitExceeded
    case creationFailedPartially([String: Error])
}

public final class SBUserManagerImpl: SBUserManager {
    public init() {}
    
    private var _networkClient = SBNetworkClientImpl()
    public var networkClient: SBNetworkClient {
        _networkClient
    }

    private var _userStorage = SBUserStorageImpl()
    public var userStorage: SBUserStorage {
        _userStorage
    }
    
    
    public func initApplication(applicationId: String, apiToken: String) {
        _networkClient.applicationId = applicationId
        _networkClient.apiToken = apiToken
    }
    
    public func createUser(params: UserCreationParams, completionHandler: ((UserResult) -> Void)?) {
        let request = CreateUserRequest(bodyParams: params)
        _networkClient.request(request: request, completionHandler: completionHandler ?? { _ in })
    }
    
    public func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?) {
        guard params.count <= 10 else {
            completionHandler?(.failure(SBUserManagerError.creationLimitExceeded))
            return
        }
        var users: [SBUser] = []
        var errors: [String: Error] = [:]
        params.forEach { eachParams in
            createUser(params: eachParams) {
                switch $0 {
                case .success(let user): users.append(user)
                case .failure(let error): errors[eachParams.userId] = error
                }
            }
        }
        
        if users.count == params.count, errors.isEmpty {
            completionHandler?(.success(users))
        } else {
            completionHandler?(.failure(SBUserManagerError.creationFailedPartially(errors)))
        }
    }
    
    public func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?) {
        let request = UpdateUserRequest(userId: params.userId, bodyParams: params)
        _networkClient.request(request: request, completionHandler: completionHandler ?? { _ in })
    }
    
    public func getUser(userId: String, completionHandler: ((UserResult) -> Void)?) {
        let request = GetUserRequest(userId: userId)
        _networkClient.request(request: request, completionHandler: completionHandler ?? { _ in })
    }
    
    private struct UsersGetParams: Encodable {
        let nickname: String
        let limit: Int
    }
    
    public func getUsers(nicknameMatches nickname: String, completionHandler: ((UsersResult) -> Void)?) {
        let request = GetUsersRequest(queryParams: UsersGetParams(nickname: nickname, limit: 10))
        _networkClient.request(request: request, completionHandler: completionHandler ?? { _ in })
    }
}

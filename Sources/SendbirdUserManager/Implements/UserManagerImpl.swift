//
//  UserManagerImpl.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

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
        _networkClient.request(request: request) { result in
            switch result {
            case .success(let user):
                completionHandler?(.success(user))
            case .failure(let error):
                completionHandler?(.failure(error))
            }
        }
        
    }
    
    public func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?) {
    }
    
    public func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?) {
        
    }
    
    public func getUser(userId: String, completionHandler: ((UserResult) -> Void)?) {
        
        let request = GetUserRequest(userId: userId)
        _networkClient.request(request: request) { result in
            switch result {
            case .success(let user):
                completionHandler?(.success(user))
            case .failure(let error):
                completionHandler?(.failure(error))
            }
        }
    }
    
    public func getUsers(nicknameMatches: String, completionHandler: ((UsersResult) -> Void)?) {
        
    }
}

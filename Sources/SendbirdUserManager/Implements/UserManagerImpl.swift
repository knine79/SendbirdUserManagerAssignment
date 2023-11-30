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
    case invalidParameters(String)
    case uniqueKeyConstaintViolated
}

public final class SBUserManagerImpl: SBUserManager {
    public init() {}
    public static var shared: SBUserManager = SBUserManagerImpl()
    
    private let maxUserIdLength = 80
    private let maxNicknameLength = 80
    private let maxProfileURLLength = 2048
    
    public var networkClient: SBNetworkClient = SBNetworkClientImpl()
    
    public var userStorage: SBUserStorage = SBUserStorageImpl()
    
    private var applicationId: String? {
        didSet {
            if applicationId != oldValue {
                userStorage = SBUserStorageImpl()
                (networkClient as? SBNetworkClientImpl)?.applicationId = applicationId
            }
        }
    }
    
    private var apiToken: String? {
        didSet {
            (networkClient as? SBNetworkClientImpl)?.apiToken = apiToken
        }
    }
}

// MARK: - pubilc methods
extension SBUserManagerImpl {
    public func initApplication(applicationId: String, apiToken: String) {
        self.applicationId = applicationId
        self.apiToken = apiToken
    }
    
    public func createUser(params: UserCreationParams, completionHandler: ((UserResult) -> Void)?) {
    
        do {
            try validateParams(params)
        } catch {
            completionHandler?(.failure(error))
            return
        }
        
        let request = CreateUserRequest(bodyParams: params)
        networkClient.request(request: request) { [weak self] in
            if case .success(let user) = $0 {
                self?.userStorage.upsertUser(user)
            }
            completionHandler?($0)
        }
    }
    
    public func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?) {
        
        do {
            try validateParams(params)
        } catch {
            completionHandler?(.failure(error))
            return
        }
        
        var users: [SBUser] = []
        var errors: [String: Error] = [:]
        params.enumerated().forEach { eachParams in
            createUser(params: eachParams.element) { [weak self] in
                switch $0 {
                case .success(let user): 
                    users.append(user)
                    self?.userStorage.upsertUser(user)
                case .failure(let error):
                    errors[eachParams.element.userId] = error
                }
                
                if eachParams.offset == params.count - 1 {
                    if users.count == params.count, errors.isEmpty {
                        completionHandler?(.success(users))
                    } else {
                        completionHandler?(.failure(SBUserManagerError.creationFailedPartially(errors)))
                    }
                }
            }
        }
    }
    
    public func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?) {
        
        do {
            try validateParams(params)
        } catch {
            completionHandler?(.failure(error))
            return
        }
        
        let request = UpdateUserRequest(userId: params.userId, bodyParams: params)
        networkClient.request(request: request) { [weak self] in
            if case .success(let user) = $0 {
                self?.userStorage.upsertUser(user)
            }
            completionHandler?($0)
        }
    }
    
    public func getUser(userId: String, completionHandler: ((UserResult) -> Void)?) {
        
        do {
            try validateUserId(userId, isCreating: false)
        } catch {
            completionHandler?(.failure(error))
            return
        }
        
        if let user = userStorage.getUser(for: userId) {
            completionHandler?(.success(user))
            return
        }
        
        let request = GetUserRequest(userId: userId)
        networkClient.request(request: request) { [weak self] in
            if case .success(let user) = $0 {
                self?.userStorage.upsertUser(user)
            }
            completionHandler?($0)
        }
    }
    
    private struct UsersGetParams: Encodable {
        let nickname: String
        let limit: Int
    }
    
    public func getUsers(nicknameMatches nickname: String, completionHandler: ((UsersResult) -> Void)?) {
        
        do {
            try validateNickname(nickname, required: false)
        } catch {
            completionHandler?(.failure(error))
            return
        }
        
        let request = GetUsersRequest(queryParams: UsersGetParams(nickname: nickname, limit: 10))
        networkClient.request(request: request) { [weak self] in
            switch $0 {
            case .success(let response):
                response.users.forEach { user in
                    self?.userStorage.upsertUser(user)
                }
                completionHandler?(.success(response.users))
            case .failure(let error):
                completionHandler?(.failure(error))
            }
        }
    }
}

// MARK: - parameter validation
extension SBUserManagerImpl {
    private func validateParams(_ params: UserCreationParams) throws {
        try validateUserId(params.userId, isCreating: true)
        try validateNickname(params.nickname, required: true)
        try validateProfileURL(params.profileURL)
    }
    
    private func validateParams(_ params: [UserCreationParams]) throws {
        guard params.count <= 10 else {
            throw SBUserManagerError.creationLimitExceeded
        }
    }
    
    private func validateParams(_ params: UserUpdateParams) throws {
        try validateUserId(params.userId, isCreating: false)
        try validateNickname(params.nickname, required: false)
        try validateProfileURL(params.profileURL)
    }
    
    private func validateUserId(_ userId: String, isCreating: Bool) throws {
        guard !userId.isEmpty else {
            throw SBUserManagerError.invalidParameters("userId is empty")
        }
        
        guard userId.count <= maxUserIdLength else {
            throw SBUserManagerError.invalidParameters("userId is too long")
        }
        
        guard !isCreating || userStorage.getUser(for: userId) == nil else {
            throw SBUserManagerError.uniqueKeyConstaintViolated
        }
    }
    
    private func validateNickname(_ nickname: String?, required: Bool) throws {
        guard !required || nickname?.isEmpty != true else {
            throw SBUserManagerError.invalidParameters("nickname is empty")
        }
        
        guard nickname?.count ?? 0 <= maxNicknameLength else {
            throw SBUserManagerError.invalidParameters("nickname is too long")
        }
    }
    
    private func validateProfileURL(_ profileURL: String?) throws {
        guard profileURL?.count ?? 0 <= maxProfileURLLength else {
            throw SBUserManagerError.invalidParameters("profileURL is too long")
        }
        
        guard profileURL == nil || URL(string: profileURL!) != nil else {
            throw SBUserManagerError.invalidParameters("profileURL is invalid url")
        }
    }
}

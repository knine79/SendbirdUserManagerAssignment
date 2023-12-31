//
//  UserManagerImpl.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

// MARK: - error type
public enum SBUserManagerError: Error {
    case creationLimitExceeded
    case creationFailedPartially([String: Error])
    case invalidParameters(String)
    case uniqueKeyConstaintViolated
    case rateLimitExceeded
}

// MARK: - class definition
public class SBUserManagerImpl: SBUserManager {
    
    // MARK: - private data
    private var applicationId: String?
    private var apiToken: String?
    private var rateLimiter: LeakyBucketRateLimiter
    private var _networkClient: SBNetworkClient
    private var _userStorage: SBUserStorage
    
    private init(networkClient: SBNetworkClient, userStorage: SBUserStorage) {
        self.rateLimiter = LeakyBucketRateLimiter(bucketSize: 10, rate: 1)
        self._networkClient = networkClient
        self._userStorage = userStorage
    }
    
    // MARK: - public interfaces
    required public init() {
        self.applicationId = SBUserManagerImpl.shared.applicationId
        self.apiToken = SBUserManagerImpl.shared.apiToken
        self.rateLimiter = SBUserManagerImpl.shared.rateLimiter
        self._networkClient = SBUserManagerImpl.shared.networkClient
        self._userStorage = SBUserManagerImpl.shared.userStorage
    }

    public var networkClient: SBNetworkClient {
        _networkClient
    }
    
    public var userStorage: SBUserStorage {
        _userStorage
    }
    
    public static var shared: SBUserManagerImpl = SBUserManagerImpl(networkClient: SBNetworkClientImpl(), userStorage: SBUserStorageImpl())

    public func initApplication(applicationId: String, apiToken: String) {
        
        Log.verbose("\(#function) called")
        
        if applicationId != self.applicationId || apiToken != self.apiToken {
            let networkClient = SBNetworkClientImpl()
            networkClient.applicationId = applicationId
            networkClient.apiToken = apiToken
            self._networkClient = networkClient
            Log.verbose("\(#function) networkClient reset")
        }
        if applicationId != self.applicationId {
            self._userStorage = SBUserStorageImpl()
            Log.verbose("\(#function) userStorage reset")
        }
        self.applicationId = applicationId
        self.apiToken = apiToken
    }
    
    public func createUser(params: UserCreationParams, completionHandler: ((UserResult) -> Void)?) {
        
        Log.verbose("\(#function) called")
        
        do {
            try validateParams(params)
        } catch {
            Log.error("\(#function) \(error)")
            completionHandler?(.failure(error))
            return
        }
        
        let request = CreateUserRequest(bodyParams: params)
        limitedRequest(request: request) { [weak self] in
            switch $0 {
            case .success(let user):
                Log.verbose("\(#function) user(\(params.userId)) created and cached")
                self?.userStorage.upsertUser(user)
            case .failure(let error):
                Log.error("\(#function) \(error)")
            }
            completionHandler?($0)
        }
    }
    
    public func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?) {
        
        Log.verbose("\(#function) called")
        
        do {
            try validateParams(params)
        } catch {
            Log.error("\(#function) \(error)")
            completionHandler?(.failure(error))
            return
        }
        
        var users: [SBUser] = []
        var errors: [String: Error] = [:]
        params.enumerated().forEach { [weak self] eachParams in
            guard let self else { return }
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
                        Log.verbose("\(#function) \(params.count) users created and cached")
                        completionHandler?(.success(users))
                    } else {
                        let error = SBUserManagerError.creationFailedPartially(errors)
                        Log.error("\(#function) \(error)")
                        completionHandler?(.failure(error))
                    }
                }
            }
        }
    }
    
    public func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?) {
        
        Log.verbose("\(#function) called")
        
        do {
            try validateParams(params)
        } catch {
            Log.error("\(#function) \(error)")
            completionHandler?(.failure(error))
            return
        }
        
        let request = UpdateUserRequest(userId: params.userId, bodyParams: params)
        limitedRequest(request: request) { [weak self] in
            switch $0 {
            case .success(let user):
                Log.verbose("\(#function) user(\(params.userId)) data updated and cached")
                self?.userStorage.upsertUser(user)
            case .failure(let error):
                Log.error("\(#function) \(error)")
            }
            completionHandler?($0)
        }
    }
    
    public func getUser(userId: String, completionHandler: ((UserResult) -> Void)?) {
        
        Log.verbose("\(#function) called")
        
        do {
            try validateUserId(userId, isCreating: false)
        } catch {
            Log.error("\(#function) \(error)")
            completionHandler?(.failure(error))
            return
        }
        
        if let user = userStorage.getUser(for: userId) {
            Log.verbose("\(#function) user(\(userId)) cache hit")
            completionHandler?(.success(user))
            return
        }
        
        let request = GetUserRequest(userId: userId)
        limitedRequest(request: request) { [weak self] in
            switch $0 {
            case .success(let user):
                Log.verbose("\(#function) user(\(userId)) data fetched and cached")
                self?.userStorage.upsertUser(user)
            case .failure(let error):
                Log.error("\(#function) \(error)")
            }
            completionHandler?($0)
        }
    }
    
    public func getUsers(nicknameMatches nickname: String, completionHandler: ((UsersResult) -> Void)?) {
        getUsers(nicknameMatches: nickname, token: nil) {
            switch $0 {
            case .success(let response):
                completionHandler?(.success(response.users))
            case .failure(let error):
                completionHandler?(.failure(error))
            }
        }
    }
    
    public func getUsers(nicknameMatches nickname: String, token: String?, completionHandler: ((UsersNextResult) -> Void)?) {
        
        Log.verbose("\(#function) called")
        
        do {
            try validateNickname(nickname, required: true)
        } catch {
            Log.error("\(#function) \(error)")
            completionHandler?(.failure(error))
            return
        }
        
        let request = GetUsersRequest(queryParams: ["nickname": nickname, "limit": "10", "token": token ?? ""])
        limitedRequest(request: request) { [weak self] in
            switch $0 {
            case .success(let response):
                response.users.forEach { user in
                    self?.userStorage.upsertUser(user)
                }
                Log.verbose("\(#function) \(response.users.count) users data fetched and cached")
                completionHandler?(.success((users: response.users, next: response.next)))
            case .failure(let error):
                Log.error("\(#function) \(error)")
                completionHandler?(.failure(error))
            }
        }
    }
}

// MARK: - rate limit
extension SBUserManagerImpl {
    private func limitedRequest<R>(request: R, completionHandler: @escaping (Result<R.Response, Error>) -> Void) where R : Request {
        let isAllowed = rateLimiter.add { [weak self] in
            guard let self else { return }
            networkClient.request(request: request, completionHandler: completionHandler)
        }
        if !isAllowed {
            completionHandler(.failure(SBUserManagerError.rateLimitExceeded))
        }
    }
}

// MARK: - parameter validation
extension SBUserManagerImpl {
    
    private var maxUserIdLength: Int { 80 }
    private var maxNicknameLength: Int { 80 }
    private var maxProfileURLLength: Int { 2048 }
    
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
        guard !userId.trimmed.isEmpty else {
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
        guard !required || nickname?.trimmed.isEmpty != true else {
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
    }
}

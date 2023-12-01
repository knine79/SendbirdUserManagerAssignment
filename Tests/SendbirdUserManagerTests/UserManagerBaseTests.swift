//
//  UserManagerBaseTests.swift
//  SendbirdUserManager
//
//  Created by Sendbird
//

import Foundation
import XCTest
@testable import SendbirdUserManager

/// Unit Testing을 위해 제공되는 base test suite입니다.
/// 사용을 위해서는 해당 클래스를 상속받고,
/// `open func userManagerType() -> SBUserManager.Type!`를 override한뒤, 본인이 구현한 SBUserManager의 타입을 반환하도록 합니다.
open class UserManagerBaseTests: XCTestCase {
    open func userManagerType() -> SBUserManager.Type! {
        return nil
    }
    
    public func testInitApplicationWithDifferentAppIdClearsData() {
        let userManager = userManagerType().init()
        
        // First init
        userManager.initApplication(applicationId: "AppID1", apiToken: "Token1")
        
        let userId = UUID().uuidString
        let initialUser = UserCreationParams(userId: userId, nickname: "Initial", profileURL: nil)
        userManager.createUser(params: initialUser) { _ in }
        
        // Second init with a different App ID
        userManager.initApplication(applicationId: "AppID2", apiToken: "Token2")
        
        // Check if the data is cleared
        let users = userManager.userStorage.getUsers()
        XCTAssertEqual(users.count, 0, "Data should be cleared after initializing with a different Application ID")
    }
    
    public func testCreateUser() {
        let userManager = userManagerType().init()
        
        let userId = UUID().uuidString
        let params = UserCreationParams(userId: userId, nickname: "John Doe", profileURL: nil)
        let expectation = self.expectation(description: "Wait for user creation")
        
        userManager.createUser(params: params) { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertEqual(user.nickname, "John Doe")
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testCreateUsers() {
        let userManager = userManagerType().init()

        let userId1 = UUID().uuidString
        let userId2 = UUID().uuidString
        let params1 = UserCreationParams(userId: userId1, nickname: "John", profileURL: nil)
        let params2 = UserCreationParams(userId: userId2, nickname: "Jane", profileURL: nil)
        
        let expectation = self.expectation(description: "Wait for users creation")
    
        userManager.createUsers(params: [params1, params2]) { result in
            switch result {
            case .success(let users):
                XCTAssertEqual(users.count, 2)
                XCTAssertEqual(users[0].nickname, "John")
                XCTAssertEqual(users[1].nickname, "Jane")
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testUpdateUser() {
        let userManager = userManagerType().init()

        let userId = UUID().uuidString
        let initialParams = UserCreationParams(userId: userId, nickname: "InitialName", profileURL: nil)
        let updatedParams = UserUpdateParams(userId: userId, nickname: "UpdatedName", profileURL: nil)
        
        let expectation = self.expectation(description: "Wait for user update")
        
        userManager.createUser(params: initialParams) { creationResult in
            switch creationResult {
            case .success(_):
                userManager.updateUser(params: updatedParams) { updateResult in
                    switch updateResult {
                    case .success(let updatedUser):
                        XCTAssertEqual(updatedUser.nickname, "UpdatedName")
                    case .failure(let error):
                        XCTFail("Failed with error: \(error)")
                    }
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testGetUser() {
        let userManager = userManagerType().init()

        let userId = UUID().uuidString
        let params = UserCreationParams(userId: userId, nickname: "John", profileURL: nil)
        
        let expectation = self.expectation(description: "Wait for user retrieval")
        
        userManager.createUser(params: params) { creationResult in
            switch creationResult {
            case .success(let createdUser):
                userManager.getUser(userId: createdUser.userId) { getResult in
                    switch getResult {
                    case .success(let retrievedUser):
                        XCTAssertEqual(retrievedUser.nickname, "John")
                    case .failure(let error):
                        XCTFail("Failed with error: \(error)")
                    }
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testGetUsersWithNicknameFilter() {
        let userManager = userManagerType().init()

        let userId1 = UUID().uuidString
        let userId2 = UUID().uuidString
        let params1 = UserCreationParams(userId: userId1, nickname: "John", profileURL: nil)
        let params2 = UserCreationParams(userId: userId2, nickname: "Jane", profileURL: nil)
        
        let expectation = self.expectation(description: "Wait for users retrieval with nickname filter")
        
        userManager.createUsers(params: [params1, params2]) { creationResult in
            switch creationResult {
            case .success(_):
                userManager.getUsers(nicknameMatches: "John") { getResult in
                    switch getResult {
                    case .success(let users):
                        XCTAssertEqual(users.count, 1)
                        XCTAssertEqual(users[0].nickname, "John")
                    case .failure(let error):
                        XCTFail("Failed with error: \(error)")
                    }
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // Test that trying to create more than 10 users at once should fail
    public func testCreateUsersLimit() {
        let userManager = userManagerType().init()

        let users = (0..<11).map { UserCreationParams(userId: "\(UUID().uuidString)\($0)", nickname: "User\($0)", profileURL: nil) }
        
        let expectation = self.expectation(description: "Wait for users creation with limit")
        
        userManager.createUsers(params: users) { result in
            switch result {
            case .success(_):
                XCTFail("Shouldn't successfully create more than 10 users at once")
            case .failure(let error):
                // Ideally, check for a specific error related to the limit
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // Test race condition when simultaneously trying to update and fetch a user
    public func testUpdateUserRaceCondition() {
        let userManager = userManagerType().init()

        let userId = UUID().uuidString
        let initialParams = UserCreationParams(userId: userId, nickname: "InitialName", profileURL: nil)
        let updatedParams = UserUpdateParams(userId: userId, nickname: "UpdatedName", profileURL: nil)
        
        let expectation1 = self.expectation(description: "Wait for user update")
        let expectation2 = self.expectation(description: "Wait for user retrieval")
        
        userManager.createUser(params: initialParams) { creationResult in
            guard let createdUser = try? creationResult.get() else {
                XCTFail("Failed to create user")
                return
            }
            
            DispatchQueue.global().async {
                userManager.updateUser(params: updatedParams) { _ in
                    expectation1.fulfill()
                }
            }
            
            DispatchQueue.global().async {
                userManager.getUser(userId: createdUser.userId) { getResult in
                    if case .success(let user) = getResult {
                        XCTAssertTrue(user.nickname == "InitialName" || user.nickname == "UpdatedName")
                    } else {
                        XCTFail("Failed to retrieve user")
                    }
                    expectation2.fulfill()
                }
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }
    
    // Test for potential deadlock situations
    public func testPotentialDeadlockWhenFetchingUsers() {
        let userManager = userManagerType().init()

        let expectation = self.expectation(description: "Detect potential deadlocks when fetching users")
        expectation.expectedFulfillmentCount = 2

        DispatchQueue.global().async {
            userManager.getUsers(nicknameMatches: "John") { _ in
                expectation.fulfill()
            }
        }

        DispatchQueue.global().async {
            userManager.getUsers(nicknameMatches: "Jane") { _ in
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    // Test for edge cases where the nickname to be matched is either empty or consists of spaces
    public func testGetUsersWithEmptyNickname() {
        let userManager = userManagerType().init()

        let expectation = self.expectation(description: "Wait for users retrieval with empty nickname filter")
        
        userManager.getUsers(nicknameMatches: "") { result in
            if case .failure(let error) = result {
                // Ideally, check for a specific error related to the invalid nickname
                XCTAssertNotNil(error)
            } else {
                XCTFail("Fetching users with empty nickname should not succeed")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testRateLimitGetUser() {
        let userManager = userManagerType().init()

        // Concurrently get user info for 11 users
        let dispatchGroup = DispatchGroup()
        var results: [UserResult] = []
        
        userManager.initApplication(applicationId: "AppID1", apiToken: "Token1")
        
        let paramsArray = (0..<11).map { UserCreationParams(userId: "user\($0)", nickname: "user\($0)", profileURL: nil) }

        dispatchGroup.enter()
        userManager.createUsers(params: paramsArray.dropLast()) { result in
            if case .success = result {
                dispatchGroup.enter()
                userManager.createUser(params: paramsArray.last!) { result in
                    if case .success = result {
                        userManager.initApplication(applicationId: "AppID2", apiToken: "Token2")
                        
                        userManager.initApplication(applicationId: "AppID1", apiToken: "Token1")
                        
                        for i in 0..<11 {
                            dispatchGroup.enter()
                            userManager.getUser(userId: "user\(i)") { result in
                                results.append(result)
                                dispatchGroup.leave()
                            }
                        }
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()

        // Expect 10 successful and 1 rateLimitExceeded response
        let successResults = results.filter {
            if case .success = $0 { return true }
            return false
        }
        let rateLimitResults = results.filter {
            if case .failure(let error) = $0 { return true }
            return false
        }

        XCTAssertEqual(successResults.count, 10)
        XCTAssertEqual(rateLimitResults.count, 1)
    }
    
    public func testRateLimitCreateUser() {
        let userManager = userManagerType().init()
        
        // Concurrently create 11 users
        let dispatchGroup = DispatchGroup()
        var results: [UserResult] = []
        let params = UserCreationParams(userId: UUID().uuidString, nickname: "JohnDoe", profileURL: nil)

        for _ in 0..<11 {
            dispatchGroup.enter()
            userManager.createUser(params: params) { result in
                results.append(result)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()

        // Assess the results
        let successResults = results.filter {
            if case .success = $0 { return true }
            return false
        }
        let rateLimitResults = results.filter {
            if case .failure(_) = $0 { return true }
            return false
        }

        XCTAssertEqual(successResults.count, 10)
        XCTAssertEqual(rateLimitResults.count, 1)
    }
    
    public func testRateLimitCreateUsers() {
        let userManager = userManagerType().init()

        let paramsArray = [UserCreationParams(userId: UUID().uuidString, nickname: "JohnDoe", profileURL: nil), UserCreationParams(userId: UUID().uuidString, nickname: "JaneDoe", profileURL: nil)]

        // Concurrently create 6 batches of users (to exceed the limit with 12 requests)
        let dispatchGroup = DispatchGroup()
        var results: [UsersResult] = []

        for _ in 0..<6 {
            dispatchGroup.enter()
            userManager.createUsers(params: paramsArray) { result in
                results.append(result)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()

        // Assess the results
        let successResults = results.filter {
            if case .success = $0 { return true }
            return false
        }
        let rateLimitResults = results.filter {
            if case .failure(_) = $0 { return true }
            return false
        }

        XCTAssertEqual(successResults.count, 5) // 5 successful batch creations
        XCTAssertEqual(rateLimitResults.count, 1) // 1 rate-limited batch creation
    }
    
    public func testRateLimitUpdateUser() {
        let userManager = userManagerType().init()
        
        let createParams = UserCreationParams(userId: "user", nickname: "NewNick", profileURL: nil)
        let updateParams = UserUpdateParams(userId: "user", nickname: "NewNick", profileURL: nil)

        // Concurrently update 11 users
        let dispatchGroup = DispatchGroup()
        var results: [UserResult] = []

        dispatchGroup.enter()
        userManager.createUser(params: createParams) { result in
            if case .success = result {
                for _ in 0..<11 {
                    dispatchGroup.enter()
                    userManager.updateUser(params: updateParams) { result in
                        results.append(result)
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.leave()
            }
        }
                
        dispatchGroup.wait()

        // Assess the results
        let successResults = results.filter {
            if case .success = $0 { return true }
            return false
        }
        let rateLimitResults = results.filter {
            if case .failure(_) = $0 { return true }
            return false
        }

        XCTAssertEqual(successResults.count, 10)
        XCTAssertEqual(rateLimitResults.count, 1)
    }
}

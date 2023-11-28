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

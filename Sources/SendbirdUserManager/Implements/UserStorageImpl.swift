//
//  UserStorageImpl.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

final class SBUserStorageImpl: SBUserStorage {
    var usersMap: [String: SBUser] = [:]
    
    func upsertUser(_ user: SBUser) {
        usersMap[user.userId] = user
    }
    
    func getUsers() -> [SBUser] {
        Array(usersMap.values)
    }
    
    func getUsers(for nickname: String) -> [SBUser] {
        usersMap.values.filter { $0.nickname == nickname }
    }
    
    func getUser(for userId: String) -> (SBUser)? {
        usersMap[userId]
    }
}

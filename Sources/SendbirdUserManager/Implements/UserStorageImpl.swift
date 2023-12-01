//
//  UserStorageImpl.swift
//
//
//  Created by Samuel Kim on 11/28/23.
//

import Foundation

// MARK: - class definition
final class SBUserStorageImpl: SBUserStorage {
    // MARK: - private data
    private var usersMap: [String: SBUser] = [:]
    private let serialQueue = DispatchQueue(label: "com.sendbird.user-manager.user-storage.serial-queue", qos: .default)
    
    // MARK: - public interfaces
    func upsertUser(_ user: SBUser) {
        serialQueue.sync {
            usersMap[user.userId] = user
        }
    }
    
    func getUsers() -> [SBUser] {
        var result: [SBUser] = []
        serialQueue.sync {
            result = Array(usersMap.values)
        }
        return result
    }
    
    func getUsers(for nickname: String) -> [SBUser] {
        var result: [SBUser] = []
        serialQueue.sync {
            result = usersMap.values.filter { $0.nickname == nickname }
        }
        return result
    }
    
    func getUser(for userId: String) -> (SBUser)? {
        var result: SBUser?
        serialQueue.sync {
            result = usersMap[userId]
        }
        return result
    }
}

//
//  Scheduler.swift
//  
//
//  Created by Samuel Kim on 11/30/23.
//

import Foundation

final class ThrottlingScheduler {
    var lastDispatch: DispatchTime
    let queue: DispatchQueue
    let throttlingTime: TimeInterval
    
    init(throttlingTime: TimeInterval, queue: DispatchQueue = .global()) {
        self.queue = queue
        lastDispatch = .now() - throttlingTime
        self.throttlingTime = throttlingTime
    }

    func schedule(action: @escaping () -> Void) -> Bool {
        guard .now() >= lastDispatch + throttlingTime else {
            return false
        }
        lastDispatch = .now()
        queue.asyncAfter(deadline: lastDispatch) {
            Log.debug("dispatched")
            action()
        }
        return true
    }
}

final class DelayedScheduler {
    var lastDispatch: DispatchTime
    let queue: DispatchQueue
    let dispatchDelay: TimeInterval
    
    init(delay: TimeInterval, queue: DispatchQueue = .global()) {
        self.queue = queue
        lastDispatch = .now() - delay
        dispatchDelay = delay
    }

    func schedule(action: @escaping () -> Void) {
        
        lastDispatch = max(lastDispatch + dispatchDelay, .now())
        Log.debug("lastDispatch: \(lastDispatch.date.string("HH:mm:ss.SSS"))")
        queue.asyncAfter(deadline: lastDispatch) {
            Log.debug("dispatched")
            action()
        }
    }
}

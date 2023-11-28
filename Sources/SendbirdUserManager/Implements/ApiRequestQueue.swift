//
//  ApiRequestQueue.swift
//
//
//  Created by Samuel Kim on 11/29/23.
//

import Foundation

final class ApiRequestQueue {
    private var requestQueue: [URLSessionTask] = []
    
    private let requestsPerSecond: Int
    private var firstRequestTimeAfterLimitation: Date?
    private var requestCountSinceBeginning: Int = 0
    private let lock = NSLock()
    
    private lazy var timer: Timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: resumeByTimeout(_:))
    
    init(requestsPerSecond: Int = 1) {
        self.requestsPerSecond = requestsPerSecond
    }
    
    func enqueue(_ task: URLSessionTask) {
        NSLog("enqueued")
        requestQueue.append(task)
        if canResumeImmediately {
            resumeImmediately()
            resetTimer()
        }
    }
    
    private var canResumeImmediately: Bool {
        lock.lock(); defer { lock.unlock() }
        NSLog("\(requestCountSinceBeginning), \(Date().addingTimeInterval(-(firstRequestTimeAfterLimitation?.timeIntervalSince1970 ?? 0)).timeIntervalSince1970)")
        return requestCountSinceBeginning < requestsPerSecond || Date().addingTimeInterval(-(firstRequestTimeAfterLimitation?.timeIntervalSince1970 ?? 0)).timeIntervalSince1970 >= 1
    }
    
    private func dequeue() -> URLSessionTask? {
        guard !requestQueue.isEmpty else { return nil }
        NSLog("dequeued")
        return requestQueue.removeFirst()
    }
    
    private func resumeImmediately() {
        resumeTask(byTimeout: false)
    }
    
    private func resumeByTimeout(_ timer: Timer) {
        resumeTask(byTimeout: true)
    }
    
    private func resumeTask(byTimeout: Bool) {
        lock.lock(); defer { lock.unlock() }
        if byTimeout {
            requestCountSinceBeginning = 0
        }
        while requestCountSinceBeginning < requestsPerSecond {
            guard let task = dequeue() else { break }
            task.resume()
            if let request = (task as? URLSessionDataTask)?.currentRequest {
                NSLog("Request \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
            } else {
                NSLog("Request unknown")
            }
            if requestCountSinceBeginning == 0 {
                firstRequestTimeAfterLimitation = Date()
            }
            requestCountSinceBeginning += 1
        }
    }
    
    private func resetTimer() {
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: resumeByTimeout(_:))
    }
}


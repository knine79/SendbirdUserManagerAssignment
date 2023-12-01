//
//  LeakyBucketRateLimiter.swift
//
//
//  Created by Samuel Kim on 11/29/23.
//

import Foundation

final class LeakyBucketRateLimiter {
    private var bucket: [() -> Void] = []
    private let serialQueue = DispatchQueue(label: "com.sendbird.leaky-bucket.serial-queue", qos: .background)
    private let bucketMaxSize: Int
    private let rate: Int
    private var timer: Timer!
    
    init(bucketSize: Int, rate: Int) {
        self.bucketMaxSize = bucketSize
        self.rate = rate
        
        DispatchQueue.global().async {
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.leak), userInfo: nil, repeats: true)
            RunLoop.current.run()
        }
    }

    func add(_ job: @escaping () -> Void) -> Bool {
        serialQueue.sync { [weak self] in
            guard let self else { return false }
            if bucket.count >= bucketMaxSize {
                return false
            } else {
                bucket.append(job)
                return true
            }
        }
    }

    @objc func leak() {
        serialQueue.sync { [weak self] in
            guard let self else { return }
            for _ in 0..<rate {
                if bucket.count > 0 {
                    let job = bucket.removeFirst()
                    DispatchQueue.global(qos: .background).async {
                        job()
                    }
                }
            }
        }
    }
}

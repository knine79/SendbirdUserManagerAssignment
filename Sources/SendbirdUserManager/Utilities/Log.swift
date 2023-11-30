//
//  Log.swift
//
//
//  Created by Samuel Kim on 11/29/23.
//

import Foundation

struct Log {
    enum Level: String, Comparable {
        case error = "⛔️"
        case warning = "⚠️"
        case info = "ℹ️"
        case debug = "🐞"
        case verbose = "🗣️"
        
        static func < (lhs: Log.Level, rhs: Log.Level) -> Bool {
            switch lhs {
            case .error:
                return false
            case .warning:
                return rhs == .error
            case .info:
                return [.error, .warning].contains(rhs)
            case .debug:
                return [.error, .warning, .info].contains(rhs)
            case .verbose:
                return [.error, .warning, .info, .debug].contains(rhs)
            }
        }
    }
    
    public static var logLevelToOuput: Level = .verbose
    
    public static func print(_ level: Level, _ items: Any, file: String = #file, line: Int = #line) {
#if DEBUG
        if level >= logLevelToOuput {
            let filename = String(file.split(separator: "/").last ?? "")
            Swift.print("\(level.rawValue)\(Date().string("yyyy/MM/dd HH:mm:ss.SSS")) \(filename):\(line) ‣ \(items)")
        }
#endif
    }
    
    public static func error(_ items: Any, file: String = #file, line: Int = #line) {
        print(.error, items, file: file, line: line)
    }
    
    public static func warning(_ items: Any, file: String = #file, line: Int = #line) {
        print(.warning, items, file: file, line: line)
    }
    
    public static func info(_ items: Any, file: String = #file, line: Int = #line) {
        print(.info, items, file: file, line: line)
    }
    
    public static func debug(_ items: Any, file: String = #file, line: Int = #line) {
        print(.debug, items, file: file, line: line)
    }
    
    public static func verbose(_ items: Any, file: String = #file, line: Int = #line) {
        print(.verbose, items, file: file, line: line)
    }
}

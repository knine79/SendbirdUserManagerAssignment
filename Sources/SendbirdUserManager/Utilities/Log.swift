//
//  Log.swift
//
//
//  Created by Samuel Kim on 11/29/23.
//

import Foundation

public func printLog(_ items: Any, file: String = #file, line: Int = #line) {
    #if DEBUG
    let filename = String(file.split(separator: "/").last ?? "")
    print("\(filename):\(line) 👉 \(items)")
    #endif
}

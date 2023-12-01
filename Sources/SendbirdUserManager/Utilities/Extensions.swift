//
//  File.swift
//  
//
//  Created by Samuel Kim on 11/30/23.
//

import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Date {
    public func string(_ format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    public func string(style: DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = style
        dateFormatter.timeStyle = style
        return dateFormatter.string(from: self)
    }
    
    public func timeString(style: DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = style
        return dateFormatter.string(from: self)
    }
    
    public func dateString(style: DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = style
        return dateFormatter.string(from: self)
    }
}

extension DispatchTime {
    var uptimeSeconds: TimeInterval {
        Double(uptimeNanoseconds) / 1_000_000_000
    }
    
    var date: Date {
        Date().addingTimeInterval((self.uptimeSeconds - DispatchTime.now().uptimeSeconds))
    }
}

extension Encodable {
    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        let jsonData = try JSONSerialization.jsonObject(with: data)
        return jsonData as? [String: Any]
    }
}

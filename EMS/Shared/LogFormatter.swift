//
//  LogFormatter.swift
//

import Foundation
import CocoaLumberjack

class LogFormatter : NSObject, DDLogFormatter {
    let dateFormatter : NSDateFormatter
    
    override init() {
        dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'+UTC'"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
    }
    
    @objc func formatLogMessage(logMessage : DDLogMessage) -> String {
        var logPrefix : String
        
        switch (logMessage.flag) {
        case DDLogFlag.Error:
            logPrefix = "E"
        case DDLogFlag.Warning:
            logPrefix = "W"
        case DDLogFlag.Info:
            logPrefix = "I"
        case DDLogFlag.Debug:
            logPrefix = "D"
        default:
            logPrefix = "V"
        }
        
        return "\(dateFormatter.stringFromDate(logMessage.timestamp)) \(logPrefix): [\(logMessage.queueLabel)/\(logMessage.threadID)] \(logMessage.fileName) \(logMessage.function) \(logMessage.line) \(logMessage.message)"
    }
}
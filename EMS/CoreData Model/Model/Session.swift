//
//  Session.swift
//  EMS
//
//  Created by Chris Searle on 04/05/16.
//  Copyright © 2016 Chris Searle. All rights reserved.
//

import Foundation
import CoreData

enum DateFormatterError : ErrorType {
    case InvalidFormat, InvalidDate
}

@objc(Session)
class Session: NSManagedObject {
    struct Token {
        static var token : dispatch_once_t = 0
    }
    
    struct Formatters {
        static var dateFormatter : NSDateFormatter? = nil
        static var timeFormatter : NSDateFormatter? = nil
    }
    
    struct Parsers {
        static var dateParser : NSDateFormatter? = nil
        static var timeParser : NSDateFormatter? = nil
    }


    func sanitizedTitle() -> String {
        let allowedChars = Set("abcdefghijklmnopqrstuvwxyz".characters)

        return String(self.title?.lowercaseString.characters.filter {allowedChars.contains($0)})
    }
    
    func sectionTitle() -> String {
        dispatch_once(&Token.token) {
            Formatters.dateFormatter = NSDateFormatter()
            Formatters.dateFormatter!.locale = NSLocale.autoupdatingCurrentLocale()
            Formatters.dateFormatter!.dateFormat = "EEEE"
            
            Formatters.timeFormatter = NSDateFormatter()
            Formatters.timeFormatter!.locale = NSLocale.autoupdatingCurrentLocale()
            Formatters.timeFormatter!.dateStyle = .NoStyle
            Formatters.timeFormatter!.timeStyle = .ShortStyle
            
            Parsers.dateParser = NSDateFormatter()
            Parsers.dateParser!.dateFormat = "yyyy-MM-dd"
            
            Parsers.timeParser = NSDateFormatter()
            Parsers.timeParser!.dateFormat = "HH:mm"
        }
        
        do {
            return try formatSectionName(self.slotName)
        } catch {
            return self.slotName!
        }
    }
    
    private func formatSectionName(name: String?)  throws -> String {
        guard let parts = name?.characters.split(" ")
            else { throw DateFormatterError.InvalidFormat }
        
        guard parts.count >= 4
            else { throw DateFormatterError.InvalidFormat }
        
        guard let dateStr = Parsers.dateParser!.dateFromString(String(parts[0]))
            else { throw DateFormatterError.InvalidDate }
        
        guard let startTimeStr = Parsers.timeParser!.dateFromString(String(parts[1]))
            else { throw DateFormatterError.InvalidDate }
        
        guard let endTimeStr = Parsers.timeParser!.dateFromString(String(parts[3]))
            else { throw DateFormatterError.InvalidDate }
        
        let date = Formatters.dateFormatter!.stringFromDate(dateStr).uppercaseString
        let startTime = Formatters.timeFormatter!.stringFromDate(startTimeStr)
        let endTime = Formatters.timeFormatter!.stringFromDate(endTimeStr)
        
        return "\(date) \(startTime) - \(endTime)"
    }
}

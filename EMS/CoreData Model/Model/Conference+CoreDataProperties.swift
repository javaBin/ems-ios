//
//  Conference+CoreDataProperties.swift
//

import Foundation
import CoreData

extension Conference {

    @NSManaged var end: NSDate?
    @NSManaged var hintCount: NSNumber?
    @NSManaged var href: String?
    @NSManaged var name: String?
    @NSManaged var roomCollection: String?
    @NSManaged var sessionCollection: String?
    @NSManaged var slotCollection: String?
    @NSManaged var start: NSDate?
    @NSManaged var venue: String?
    @NSManaged var conferenceKeywords: NSSet?
    @NSManaged var conferenceLevels: NSSet?
    @NSManaged var conferenceTypes: NSSet?
    @NSManaged var rooms: NSSet?
    @NSManaged var sessions: NSSet?
    @NSManaged var slots: NSSet?

}

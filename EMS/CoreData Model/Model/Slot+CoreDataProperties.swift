//
//  Slot+CoreDataProperties.swift
//

import Foundation
import CoreData

extension Slot {

    @NSManaged var end: NSDate?
    @NSManaged var href: String?
    @NSManaged var start: NSDate?
    @NSManaged var conference: Conference?
    @NSManaged var sessions: NSSet?

}

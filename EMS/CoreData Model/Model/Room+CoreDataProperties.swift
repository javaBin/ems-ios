//
//  Room+CoreDataProperties.swift
//

import Foundation
import CoreData

extension Room {

    @NSManaged var href: String?
    @NSManaged var name: String?
    @NSManaged var conference: Conference?
    @NSManaged var sessions: NSSet?

}

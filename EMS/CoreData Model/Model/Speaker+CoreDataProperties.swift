//
//  Speaker+CoreDataProperties.swift
//

import Foundation
import CoreData

extension Speaker {

    @NSManaged var bio: String?
    @NSManaged var href: String?
    @NSManaged var lastUpdated: NSDate?
    @NSManaged var name: String?
    @NSManaged var thumbnailUrl: String?
    @NSManaged var session: Session?

}

//
//  Rating+CoreDataProperties.swift
//

import Foundation
import CoreData

extension Rating {

    @NSManaged var comments: String?
    @NSManaged var content: NSNumber?
    @NSManaged var href: String?
    @NSManaged var overall: NSNumber?
    @NSManaged var quality: NSNumber?
    @NSManaged var relevance: NSNumber?

}

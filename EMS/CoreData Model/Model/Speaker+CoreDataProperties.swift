//
//  Speaker+CoreDataProperties.swift
//  EMS
//
//  Created by Chris Searle on 04/05/16.
//  Copyright © 2016 Chris Searle. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
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

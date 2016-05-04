//
//  Slot+CoreDataProperties.swift
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

extension Slot {

    @NSManaged var end: NSDate?
    @NSManaged var href: String?
    @NSManaged var start: NSDate?
    @NSManaged var conference: Conference?
    @NSManaged var sessions: NSSet?

}

//
//  SpeakerPic+CoreDataProperties.swift
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

extension SpeakerPic {

    @NSManaged var lastUpdated: NSDate?
    @NSManaged var url: String?

}

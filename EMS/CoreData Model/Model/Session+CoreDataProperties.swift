//
//  Session+CoreDataProperties.swift
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

extension Session {

    @NSManaged var attachmentCollection: String?
    @NSManaged var audience: String?
    @NSManaged var body: String?
    @NSManaged var favourite: NSNumber?
    @NSManaged var format: String?
    @NSManaged var href: String?
    @NSManaged var language: String?
    @NSManaged var level: String?
    @NSManaged var roomName: String?
    @NSManaged var slotName: String?
    @NSManaged var speakerCollection: String?
    @NSManaged var state: String?
    @NSManaged var summary: String?
    @NSManaged var title: String?
    @NSManaged var videoLink: String?
    @NSManaged var conference: Conference?
    @NSManaged var keywords: NSSet?
    @NSManaged var room: Room?
    @NSManaged var slot: Slot?
    @NSManaged var speakers: NSSet?

}

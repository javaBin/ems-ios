//
//  Slot.swift
//  EMS
//
//  Created by Chris Searle on 04/05/16.
//  Copyright © 2016 Chris Searle. All rights reserved.
//

import Foundation
import CoreData

@objc(Slot)
class Slot: NSManagedObject {

    func duration() -> NSTimeInterval? {
        if let st = self.start, ed = self.end {
            return ed.timeIntervalSinceDate(st)
        }
        
        return nil
    }
}

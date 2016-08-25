//
//  Slot.swift
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

import Foundation

@objc class EMSSlot: NSObject {
    var start: NSDate?

    var href: NSURL?

    var slotDuration: Int?

    // Obj-c wrapping requirement - can't see Int?
    var duration: NSNumber? {
        set(newDuration) {
            self.slotDuration = newDuration?.integerValue
        }
        get {
            return slotDuration
        }
    }

    func end() -> NSDate? {
        if let date = self.start, duration = self.slotDuration {
            return NSDate(timeInterval: Double(duration * 60), sinceDate: date)
        }
        
        return nil
    }


    override var description: String {
        return "<\(self.dynamicType): self.start=\(self.start), self.end=\(self.end), self.href=\(self.href), self.slotDuration=\(self.slotDuration)>"
    }
}
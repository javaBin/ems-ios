import Foundation

@objc class EMSConference: NSObject {
    var name: String?
    var venue: String?

    var start: NSDate?
    var end: NSDate?

    var href: NSURL?

    var slotCollection: NSURL?
    var roomCollection: NSURL?
    var sessionCollection: NSURL?

    var count: Int?

    // Obj-c wrapping requirement - can't see Int?
    var hintCount: NSNumber? {
        set(newHintCount) {
            self.count = newHintCount?.integerValue
        }
        get {
            return count
        }
    }

    override var description: String {
        return "<\(self.dynamicType): self.name=\(self.name), self.start=\(self.start), self.end=\(self.end), self.href=\(self.href), self.slotCollection=\(self.slotCollection), self.roomCollection=\(self.roomCollection), self.sessionCollection=\(self.sessionCollection), self.hintCount=\(self.count)>"
    }
}
import Foundation

@objc class EMSSpeaker: NSObject {
    var name: String?

    var href: NSURL?

    var bio: String?

    var thumbnailUrl: NSURL?

    var lastUpdated: NSDate?

    override var description: String {
        return "<\(self.dynamicType): self.name=\(self.name), self.href=\(self.href), self.bio=\(self.bio), self.thumbnailUrl=\(self.thumbnailUrl), self.lastUpdated=\(self.lastUpdated)>"
    }
}
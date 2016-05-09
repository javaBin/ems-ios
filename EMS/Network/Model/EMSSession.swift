import Foundation

@objc class EMSSession: NSObject {
    var href: NSURL?

    var format: String?
    var body: String?
    var state: String?
    var audience: String?
    var keywords: [String]?
    var title: String?
    var language: String?
    var summary: String?
    var level: String?

    var link: NSURL?
    var videoLink: NSURL?

    var speakers: [EMSSpeaker]?

    var attachmentCollection: NSURL?
    var speakerCollection: NSURL?

    var roomItem: NSURL?
    var slotItem: NSURL?


    override var description: String {
        return "<\(self.dynamicType): self.href=\(self.href), self.format=\(self.format), self.body=\(self.body), self.state=\(self.state), self.audience=\(self.audience), self.keywords=\(self.keywords), self.title=\(self.title), self.language=\(self.language), self.summary=\(self.summary), self.level=\(self.level), self.link=\(self.link), self.videoLink=\(self.videoLink), self.speakers=\(self.speakers), self.attachmentCollection=\(self.attachmentCollection), self.speakerCollection=\(self.speakerCollection), self.roomItem=\(self.roomItem), self.slotItem=\(self.slotItem)>"
    }
}

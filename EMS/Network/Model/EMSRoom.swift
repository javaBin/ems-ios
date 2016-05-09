import Foundation

@objc class EMSRoom: NSObject {
    var name: String?

    var href: NSURL?

    override var description: String {
        return "<\(self.dynamicType): self.name=\(self.name), self.href=\(self.href)>"
    }
}
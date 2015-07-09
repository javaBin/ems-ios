import Foundation
import CoreData

public class Rating: NSManagedObject {
    @NSManaged var href: String
    @NSManaged var overall: NSNumber
    @NSManaged var relevance: NSNumber
    @NSManaged var quality: NSNumber
    @NSManaged var content: NSNumber
}

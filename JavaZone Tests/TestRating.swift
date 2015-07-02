import UIKit
import CoreData
import XCTest
import JavaZone

class TestRating: XCTestCase {
    var moc : NSManagedObjectContext? = nil

    override func setUp() {
        super.setUp()
        
        let modelUrl = NSBundle.mainBundle().URLForResource("EMSCoreDataModel", withExtension: "momd")!
        let mom = NSManagedObjectModel(contentsOfURL: modelUrl)!
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)

        psc.addPersistentStoreWithType(NSInMemoryStoreType,
            configuration: nil,
            URL: nil,
            options: nil,
            error: nil)
        
        self.moc = NSManagedObjectContext()
        self.moc!.persistentStoreCoordinator = psc
    }
    
    func testUrl() {
        let session = NSEntityDescription.insertNewObjectForEntityForName("Session", inManagedObjectContext: self.moc!) as! Session
        
        session.href = "http://javazone.no/ems/server/events/0e6d98e9-5b06-42e7-b275-6abadb498c81/sessions/d0e180a3-2aa6-468d-a65f-12859cf1bc66"
        
        let api = RatingApi(server: "http://localhost")
        
        if let url = api.urlFromSession(session) {
            XCTAssertEqual(url.absoluteString!, "http://localhost/events/0e6d98e9-5b06-42e7-b275-6abadb498c81/sessions/d0e180a3-2aa6-468d-a65f-12859cf1bc66/feedbacks", "Incorrect url generated")
        } else {
            XCTFail("No url returned")
        }
    }

}

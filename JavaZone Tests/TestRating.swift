//import UIKit
//import CoreData
//import XCTest
//import EMS
//
//
//class TestRating: XCTestCase {
//    var moc : NSManagedObjectContext? = nil
//
//    override func setUp() {
//        super.setUp()
//        
//        do {
//            let modelUrl = NSBundle.mainBundle().URLForResource("EMSCoreDataModel", withExtension: "momd")!
//            let mom = NSManagedObjectModel(contentsOfURL: modelUrl)!
//            let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
//
//            try psc.addPersistentStoreWithType(NSInMemoryStoreType,
//                configuration: nil,
//                URL: nil,
//                options: nil)
//        
//            self.moc = NSManagedObjectContext()
//            self.moc!.persistentStoreCoordinator = psc
//        } catch {
//            XCTFail("Unable to set up")
//        }
//    }
//    
//    func testUrl() {
//        let session = NSEntityDescription.insertNewObjectForEntityForName("Session", inManagedObjectContext: self.moc!) as! Session
//        
//        session.href = "http://javazone.no/ems/server/events/0e6d98e9-5b06-42e7-b275-6abadb498c81/sessions/d0e180a3-2aa6-468d-a65f-12859cf1bc66"
//        
//        let api = RatingApi(server: "http://javazone.no/devnull/server/")
//        
//        if let url = api.urlFromSession(session) {
//            XCTAssertEqual(url.absoluteString, "http://javazone.no/devnull/server/events/0e6d98e9-5b06-42e7-b275-6abadb498c81/sessions/d0e180a3-2aa6-468d-a65f-12859cf1bc66/feedbacks", "Incorrect url generated")
//        } else {
//            XCTFail("No url returned")
//        }
//    }
//
//}

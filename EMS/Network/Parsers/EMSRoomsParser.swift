import Foundation
import CocoaLumberjack

@objc protocol EMSRoomsParserDelegate {
    optional func finishedRooms(rooms: [EMSRoom], forHref href:NSURL, error:NSError?)
}

@objc class EMSRoomsParser : NSObject {
    var delegate : EMSRoomsParserDelegate?
    
    func processData(data: NSData, forHref href:NSURL) throws -> [EMSRoom] {
        
        do {
            let collection = try CJCollection(forNSData:data)
            
            return collection.items.map({ item in
                let room = EMSRoom()
                
                room.href = item.href
                
                for datum in item.data {
                    if let field = datum["name"] as? String {
                        if let value = datum["value"] as? String {
                            switch (field) {
                            case "name":
                                room.name = value
                            default:
                                DDLogDebug("Ignored string field \(field) for room")
                            }
                        }
                    }
                }
                
                return room
            })
        } catch let error as NSError {
            DDLogError("Failed to retrieve rooms \(href) - \(error)")
            
            throw error
        }
    }
    
    func parseData(data: NSData, forHref url: NSURL) {
        do {
            let collection = try self.processData(data, forHref: url)
            
            self.delegate?.finishedRooms?(collection, forHref: url, error: nil)
        } catch let error as NSError {
            self.delegate?.finishedRooms?([], forHref: url, error: error)
        }
    }
}

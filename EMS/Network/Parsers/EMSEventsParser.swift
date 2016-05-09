import Foundation
import CocoaLumberjack

@objc protocol EMSEventsParserDelegate {
    optional func finishedEvents(conferences: [EMSConference], forHref href:NSURL, error:NSError?)
}

@objc class EMSEventsParser : NSObject {
    var delegate : EMSEventsParserDelegate?
    
    func processData(data: NSData, forHref href:NSURL) throws -> [EMSConference] {
        
        do {
            let collection = try CJCollection(forNSData:data)
            
            return collection.items.map({ item in
                let conference = EMSConference()
                
                conference.href = item.href

                for datum in item.data {
                    if let field = datum["name"] as? String, value = datum["value"] as? String {
                        switch (field) {
                        case "name":
                            conference.name = value
                        case "venue":
                            conference.venue = value
                        case "start":
                            conference.start = EMSDateConverter.dateFromString(value)
                        case "end":
                            conference.end = EMSDateConverter.dateFromString(value)
                        default:
                            DDLogInfo("Unknown field \(field) for conference")
                        }
                    }
                }
                
                for link in item.links {
                    switch (link.rel) {
                        case "session collection":
                        conference.sessionCollection = link.href
                        case "slot collection":
                        conference.slotCollection = link.href
                        case "room collection":
                        conference.roomCollection = link.href
                    default:
                        DDLogInfo("Unknwon rel \(link.rel) for conference")
                    }
                    
                    // Ugly - otherFields is coming in as implicitly unwrapped optional of dictionary
                    if let count = link.otherFields!["count"] as? NSNumber {
                        conference.hintCount = count
                    }
                }

                return conference
            })
        } catch let error as NSError {
            DDLogError("Failed to retrieve conferences \(href) - \(error)")
            
            throw error
        }
    }
    
    func parseData(data: NSData, forHref url: NSURL) {
        do {
            let collection = try self.processData(data, forHref: url)
            
            self.delegate?.finishedEvents?(collection, forHref: url, error: nil)
        } catch let error as NSError {
            self.delegate?.finishedEvents?([], forHref: url, error: error)
        }
    }
}

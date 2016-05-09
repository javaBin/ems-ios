import Foundation
import CocoaLumberjack

@objc protocol EMSSlotsParserDelegate {
    optional func finishedSlots(slots: [EMSSlot], forHref href:NSURL, error:NSError?)
}

@objc class EMSSlotsParser : NSObject {
    var delegate : EMSSlotsParserDelegate?
    
    func processData(data: NSData, forHref href:NSURL) throws -> [EMSSlot] {
        
        do {
            let collection = try CJCollection(forNSData:data)
            
            return collection.items.map({ item in
                let slot = EMSSlot()
                
                slot.href = item.href
                
                for datum in item.data {
                    if let field = datum["name"] as? String {
                        if let value = datum["value"] as? String {
                            switch (field) {
                            case "start":
                                slot.start = EMSDateConverter.dateFromString(value)
                            default:
                                DDLogDebug("Ignored string field \(field) for slot")
                            }
                        }
                    
                        if let value = datum["value"] as? Int {
                            switch (field) {
                            case "duration":
                                slot.slotDuration = value
                            default:
                                DDLogDebug("Ignored integer field \(field) for slot")
                            }
                        }
                    }
                }

                return slot
            })
        } catch let error as NSError {
            DDLogError("Failed to retrieve slots \(href) - \(error)")
            
            throw error
        }
    }
    
    func parseData(data: NSData, forHref url: NSURL) {
        DDLogDebug("Hofbnveopbne49+bn49+ubn+e9")
        do {
            let collection = try self.processData(data, forHref: url)
            
            self.delegate?.finishedSlots?(collection, forHref: url, error: nil)
        } catch let error as NSError {
            self.delegate?.finishedSlots?([], forHref: url, error: error)
        }
    }
}

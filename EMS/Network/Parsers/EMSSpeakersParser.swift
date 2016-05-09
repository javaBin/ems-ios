import Foundation
import CocoaLumberjack

@objc protocol EMSSpeakersParserDelegate {
    optional func finishedSpeakers(speakers: [EMSSpeaker], forHref href:NSURL, error:NSError?)
}

@objc class EMSSpeakersParser : NSObject {
    var delegate : EMSSpeakersParserDelegate?
    
    func processData(data: NSData, forHref href:NSURL) throws -> [EMSSpeaker] {
        
        do {
            let collection = try CJCollection(forNSData:data)
            
            return collection.items.map({ item in
                let speaker = EMSSpeaker()
                
                speaker.href = item.href
                
                for datum in item.data {
                    if let field = datum["name"] as? String {
                        if let value = datum["value"] as? String {
                            switch (field) {
                            case "name":
                                speaker.name = value
                            case "bio":
                                speaker.bio = value
                            default:
                                DDLogDebug("Ignored string field \(field) for speaker")
                            }
                        }
                    }
                }
                
                for link in item.links {
                    switch (link.rel) {
                    case "thumbnail":
                        speaker.thumbnailUrl = link.href
                    default:
                        DDLogDebug("Ignored rel \(link.rel) for speaker")
                    }
                }
                
                speaker.lastUpdated = NSDate()

                return speaker
            })
        } catch let error as NSError {
            DDLogError("Failed to retrieve speakers \(href) - \(error)")
            
            throw error
        }
    }
    
    func parseData(data: NSData, forHref url: NSURL) {
        do {
            let collection = try self.processData(data, forHref: url)
            
            self.delegate?.finishedSpeakers?(collection, forHref: url, error: nil)
        } catch let error as NSError {
            self.delegate?.finishedSpeakers?([], forHref: url, error: error)
        }
    }
}

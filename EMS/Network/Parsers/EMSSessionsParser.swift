import Foundation
import CocoaLumberjack

@objc protocol EMSSessionsParserDelegate {
    optional func finishedSessions(sessions: [EMSSession], forHref href:NSURL, error:NSError?)
}

@objc class EMSSessionsParser : NSObject {
    var delegate : EMSSessionsParserDelegate?
    
    func processData(data: NSData, forHref href:NSURL) throws -> [EMSSession] {
        
        do {
            let collection = try CJCollection(forNSData:data)
            
            return collection.items.map({ item in
                let session = EMSSession()
                
                session.href = item.href
                
                for datum in item.data {
                    if let field = datum["name"] as? String {
                        if let value = datum["value"] as? String {
                            switch (field) {
                            case "format":
                                session.format = value
                            case "body":
                                session.body = value
                            case "state":
                                session.state = value
                            case "audience":
                                session.audience = value
                            case "title":
                                session.title = value
                            case "lang":
                                session.language = value
                            case "summary":
                                session.summary = value
                            case "level":
                                session.level = value
                            default:
                                DDLogDebug("Ignored string field \(field) for session")
                            }
                        }
                        
                        if let value = datum["array"] as? [String] {
                            switch (field) {
                            case "keywords":
                                session.keywords = value
                            default:
                                DDLogDebug("Ignored [string] field \(field) for session")
                            }
                        }
                    }
                }
                
                var speakers : [EMSSpeaker] = []
                
                for link in item.links {
                    switch (link.rel) {
                    case "alternate video":
                        session.videoLink = link.href
                    case "alternate":
                        session.link = link.href
                    case "attachment collection":
                        session.attachmentCollection = link.href
                    case "speaker collection":
                        session.speakerCollection = link.href
                    case "room item":
                        session.roomItem = link.href
                    case "slot item":
                        session.slotItem = link.href
                    case "speaker item":
                        let speaker = EMSSpeaker()
                        
                        speaker.href = link.href
                        speaker.name = link.prompt
                        
                        speakers.append(speaker)
                    default:
                        DDLogDebug("Ignored rel \(link.rel) for session")
                    }
                }
                
                session.speakers = speakers
                
                return session
            })
        } catch let error as NSError {
            DDLogError("Failed to retrieve sessions \(href) - \(error)")
            
            throw error
        }
    }
    
    func parseData(data: NSData, forHref url: NSURL) {
        do {
            let collection = try self.processData(data, forHref: url)
            
            self.delegate?.finishedSessions?(collection, forHref: url, error: nil)
        } catch let error as NSError {
            self.delegate?.finishedSessions?([], forHref: url, error: error)
        }
    }
}

import Foundation
import CocoaLumberjack

@objc protocol EMSRootParserDelegate {
    optional func finishedRoot(links: [String:NSURL], forHref href:NSURL, error:NSError?)
}

@objc class EMSRootParser : NSObject {
    var delegate : EMSRootParserDelegate?
    
    func processData(data: NSData, forHref href:NSURL) throws -> [String:NSURL] {
        
        do {
            let collection = try CJCollection(forNSData:data)
            
            var links : [String:NSURL] = [:]
            
            for link in collection.links {
                links[link.rel] = link.href
            }
            
            return links
        } catch let error as NSError {
            DDLogError("Failed to retrieve root \(href) - \(error)")
            
            throw error
        }
    }
    
    func parseData(data: NSData, forHref url: NSURL) {
        do {
            let collection = try self.processData(data, forHref: url)
            
            self.delegate?.finishedRoot?(collection, forHref: url, error: nil)
        } catch let error as NSError {
            self.delegate?.finishedRoot?([:], forHref: url, error: error)
        }
    }
}

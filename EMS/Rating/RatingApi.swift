import UIKit

public class RatingApi {
    let server : String
    
    public init(server : String) {
        self.server = server
    }
    
    public func urlFromSession(session : Session) -> NSURL? {
        if let parts = extractParts(session) {
            return NSURL(string: "\(server)/events/\(parts.event)/sessions/\(parts.session)/feedbacks")
        }
        
        return nil;
    }
    
    func extractParts(session : Session) -> (event:String, session:String)? {
        let url = session.href
        let nsUrl = url as NSString
        
        var matchError: NSError?
        
        let matcher = NSRegularExpression(pattern: ".*/events/(.*)/sessions/(.*)", options: nil, error: &matchError)
        
        if let seenError = matchError {
            println(seenError.description)
            return nil
        }
        
        let matches = matcher?.matchesInString(url, options: nil, range: NSMakeRange(0, nsUrl.length)) as! [NSTextCheckingResult]

        if (matches.count > 0) {
            let match = matches[0]

            return (event: nsUrl.substringWithRange(match.rangeAtIndex(1)), session: nsUrl.substringWithRange(match.rangeAtIndex(2)))
        } else {
            return nil
        }
    }
}

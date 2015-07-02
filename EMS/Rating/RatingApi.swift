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
    
    public func postFeedback(session: Session, overall: Int, relevance: Int, content: Int, quality: Int) {
        let deviceId = UIDevice.currentDevice().identifierForVendor
        
        let data = ["template":
            ["data": [
                ["name": "overall", "value": overall],
                ["name": "relevance", "value": relevance],
                ["name": "content", "value": content],
                ["name": "quality", "value": quality]
                ]
            ]
        ]
        
        var jsonError : NSError?
        
        let json = NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions(0), error: &jsonError)
        
        if let seenError = jsonError {
            println(seenError.description)
            return
        }
        
        if let url = urlFromSession(session),
            let body = json {
                post(url, body: body)
        }
        
    }
    
    
    func post(url : NSURL, body : NSData) {
        var request = NSMutableURLRequest(URL: url)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        var err: NSError?
        
        request.HTTPBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            // Do we even get a response?
        })
        
        task.resume()
    }
}

import UIKit

public class RatingApi : NSObject {
    let server : String
    
    public init(server : String) {
        self.server = server
    }
    
    public func urlFromSession(session : Session) -> NSURL? {
        if let parts = extractParts(session) {
            return NSURL(string: "\(server)events/\(parts.event)/sessions/\(parts.session)/feedbacks")
        }
        
        return nil;
    }
    
    func extractParts(session : Session) -> (event:String, session:String)? {
        let url = session.href
        let nsUrl = url as NSString
        
        var matchError: NSError?
        
        let matcher: NSRegularExpression?
        do {
            matcher = try NSRegularExpression(pattern: ".*/events/(.*)/sessions/(.*)", options: [])
        } catch var error as NSError {
            matchError = error
            matcher = nil
        }
        
        if let seenError = matchError {
            Log.warn("\(seenError)")
            return nil
        }
        
        let matches = matcher?.matchesInString(url, options: [], range: NSMakeRange(0, nsUrl.length)) as! [NSTextCheckingResult]
        
        if (matches.count > 0) {
            let match = matches[0]
            
            return (event: nsUrl.substringWithRange(match.rangeAtIndex(1)), session: nsUrl.substringWithRange(match.rangeAtIndex(2)))
        } else {
            return nil
        }
    }
    
    public func postRating(session: Session, rating: Rating?) {
        Log.debug("Posting feedback for session \(session.href)")
        if let postRating = rating {
            let data = ["template":
                ["data": [
                    ["name": "overall", "value": postRating.overall],
                    ["name": "relevance", "value": postRating.relevance],
                    ["name": "content", "value": postRating.content],
                    ["name": "quality", "value": postRating.quality]
                    ]
                ]
            ]

            Log.debug("Posting feedback for session \(session.href) with data \(data)")
            
            var jsonError : NSError?
            
            let json: NSData?
            do {
                json = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions(rawValue: 0))
            } catch var error as NSError {
                jsonError = error
                json = nil
            }
            
            if let seenError = jsonError {
                Log.warn("\(seenError)")
                return
            }
            
            if let url = urlFromSession(session),
                let body = json {
                    post(url, body: body)
            }
        }
        
    }
    
    
    func post(url : NSURL, body : NSData) {
        let deviceId = UIDevice.currentDevice().identifierForVendor
        
        var request = NSMutableURLRequest(URL: url)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        var err: NSError?
        
        request.HTTPBody = body
        request.addValue("application/vnd.collection+json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(deviceId.UUIDString, forHTTPHeaderField: "Voter-ID")
        
        let timer = NSDate()
        
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            Log.debug("Sent feedback to URL \(url)")

            EMSTracking.trackTimingWithCategory("feedback", interval: NSDate().timeIntervalSinceDate(timer), name: "feedback")

            if (error != nil) {
                Log.warn("Failed to send feedback \(error)")
                
                EMSTracking.trackException("Unable to send feedback due to Code: \(error.code), Domain: \(error.domain), Info: \(error.userInfo)")
            }

            if let httpResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode >= 300) {
                    let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    
                    EMSTracking.trackException("Unable to send feedback with status code: \(httpResponse.statusCode) for url \(url)")

                    Log.debug("Feedback got status \(httpResponse.statusCode) with data \(dataString)")
                } else {
                    Log.debug("Feedback OK with status \(httpResponse.statusCode)")
                }
            }
            
            EMSTracking.dispatch()
        })
        
        task.resume()
    }
}

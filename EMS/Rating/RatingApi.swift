import UIKit
import CocoaLumberjack

public class RatingApi : NSObject {
    let server : String
    
    public init(server : String) {
        self.server = server
    }
    
    func urlFromSession(session : Session) -> NSURL? {
        if let parts = extractParts(session) {
            return NSURL(string: "\(server)events/\(parts.event)/sessions/\(parts.session)/feedbacks")
        }
        
        return nil;
    }
    
    func extractParts(session : Session) -> (event:String, session:String)? {
        let url = session.href
        
        if (url == nil) {
            return nil
        }

        let nsUrl = url! as NSString
        
        var matchError: NSError?
        
        let matcher: NSRegularExpression?
        
        do {
            matcher = try NSRegularExpression(pattern: ".*/events/(.*)/sessions/(.*)", options: [])
        } catch let error as NSError {
            matchError = error
            matcher = nil
        }
        
        if let seenError = matchError {
            DDLogWarn("\(seenError)")
            return nil
        }
        
        if let matches = matcher?.matchesInString(url!, options: [], range: NSMakeRange(0, nsUrl.length)) {
            if (matches.count > 0) {
                let match = matches[0]
            
                return (event: nsUrl.substringWithRange(match.rangeAtIndex(1)), session: nsUrl.substringWithRange(match.rangeAtIndex(2)))
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    func postRating(session: Session, rating: Rating?) {
        DDLogDebug("Posting feedback for session \(session.href)")
        if let postRating = rating {
            
            let data : [String : [ String : [[String: AnyObject]]]] = ["template":
                ["data":
                    [
                        ["name": "overall", "value": postRating.overall ?? 0],
                        ["name": "relevance", "value": postRating.relevance ?? 0],
                        ["name": "content", "value": postRating.content ?? 0],
                        ["name": "quality", "value": postRating.quality ?? 0],
                        ["name": "comments", "value": postRating.comments ?? ""]
                    ]
                ]
            ]

            DDLogDebug("Posting feedback for session \(session.href) with data \(data)")
            
            var jsonError : NSError?
            
            let json: NSData?
            do {
                json = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions(rawValue: 0))
            } catch let error as NSError {
                jsonError = error
                json = nil
            }
            
            if let seenError = jsonError {
                DDLogWarn("\(seenError)")
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
        
        let request = NSMutableURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        request.HTTPBody = body
        request.addValue("application/vnd.collection+json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(deviceId!.UUIDString, forHTTPHeaderField: "Voter-ID")
        
        let timer = NSDate()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            DDLogDebug("Sent feedback to URL \(url)")

            EMSTracking.trackTimingWithCategory("feedback", interval: NSDate().timeIntervalSinceDate(timer), name: "feedback")

            if (error != nil) {
                DDLogWarn("Failed to send feedback \(error)")
                
                EMSTracking.trackException("Unable to send feedback due to Code: \(error!.code), Domain: \(error!.domain), Info: \(error!.userInfo)")
            }

            if let httpResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode >= 300) {
                    let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    
                    EMSTracking.trackException("Unable to send feedback with status code: \(httpResponse.statusCode) for url \(url)")

                    DDLogDebug("Feedback got status \(httpResponse.statusCode) with data \(dataString)")
                } else {
                    DDLogDebug("Feedback OK with status \(httpResponse.statusCode)")
                }
            }
            
            EMSTracking.dispatch()
        })
        
        task.resume()
    }
}

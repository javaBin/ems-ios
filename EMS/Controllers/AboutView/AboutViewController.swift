import UIKit
import CocoaLumberjack

class AboutViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var web : UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let path = NSBundle.mainBundle().bundlePath
        let baseURL = NSURL(fileURLWithPath: path)

        if let docPath = NSBundle.mainBundle().pathForResource("about", ofType: "html") {
            let docURL = NSURL(fileURLWithPath: docPath)

            let info = NSBundle.mainBundle().infoDictionary
        
            do {
                var content = try String(contentsOfURL: docURL)
                
                if let version = info?["CFBundleShortVersionString"] as? String, let build = info?["CFBundleVersion"] as? String {
                    content = content.stringByReplacingOccurrencesOfString("VERSION", withString: version)
                    content = content.stringByReplacingOccurrencesOfString("BUILD", withString: build)

                    self.web.loadHTMLString(content, baseURL: baseURL)
                }
            } catch {
                DDLogError("Unable to load about content")
            }
        } else {
            DDLogError("Unable to get doc path")
        }
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType == .LinkClicked) {
            if (request.URL!.scheme.hasPrefix("http")) {
                UIApplication.sharedApplication().openURL(request.URL!)
                return false
            }
        }
        
        return true
    }
}

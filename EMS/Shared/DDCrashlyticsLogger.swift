import UIKit

import CocoaLumberjack
import Crashlytics

let ddloglevel = DDLogLevel.Debug

class DDCrashlyticsLogger: DDAbstractLogger {
    
    override func logMessage(logMessage: DDLogMessage!) {
        var message = logMessage.message
        
        if let formatter = self.logFormatter {
            message = formatter.formatLogMessage(logMessage)
        }
        
        CLSLogv("%@", getVaList([message]))
    }
}

//
//  Loggers.swift
//

import CocoaLumberjack

@objc class Loggers : NSObject {
    class func setupLoggers() {
        defaultDebugLevel = DDLogLevel.Debug
        
        let formatter = LogFormatter()
        
        DDTTYLogger.sharedInstance().logFormatter = formatter
        DDASLLogger.sharedInstance().logFormatter = formatter
        
        DDLog.addLogger(DDTTYLogger.sharedInstance())
        DDLog.addLogger(DDASLLogger.sharedInstance())
        
        DDLogDebug("Logging setup")
    }
}

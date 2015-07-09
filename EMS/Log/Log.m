#import "Log.h"

@implementation Log

+ (void) error:(NSString *)message {
    DDLogError(@"%@", message);
}

+ (void) warn:(NSString *)message {
    DDLogWarn(@"%@", message);
}

+ (void) info:(NSString *)message {
    DDLogInfo(@"%@", message);
}

+ (void) debug:(NSString *)message {
    DDLogDebug(@"%@", message);
}


@end
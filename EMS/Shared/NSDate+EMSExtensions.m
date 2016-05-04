//
// NSDate+EMSExtensions.m
//

#import "EMS-Swift.h"

#import "NSDate+EMSExtensions.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation NSDate (EMSExtensions)

+ (NSDate *)dateForDate:(NSDate *)date fromDate:(NSDate *)fromDate {
#ifdef USE_TEST_DATE
    DDLogWarn(@"RUNNING IN USE_TEST_DATE mode");
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *timeComp = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    NSDateComponents *dateComp = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:fromDate];
    
    static NSDateFormatter *inputFormatter;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"];
        [inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    
    return [inputFormatter dateFromString:[NSString stringWithFormat:@"%04ld-%02ld-%02ld %02ld:%02ld:00 +0200", (long) [dateComp year], (long) [dateComp month], (long) [dateComp day], (long) [timeComp hour], (long) [timeComp minute]]];
#else
    return date;
#endif
}

@end
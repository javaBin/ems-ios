//
//  EMSDateConverter.m
//

#import "EMSDateConverter.h"

@implementation EMSDateConverter

+ (NSDate *)dateFromString:(NSString *)dateString {
    static NSDateFormatter *inputFormatter;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });

    return [inputFormatter dateFromString:dateString];
}

@end

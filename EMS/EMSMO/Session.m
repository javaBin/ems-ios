//
//  Session.m
//

#import "Session.h"
#import "Slot.h"


@implementation Session

@dynamic attachmentCollection;
@dynamic audience;
@dynamic body;
@dynamic favourite;
@dynamic format;
@dynamic href;
@dynamic language;
@dynamic level;
@dynamic roomName;
@dynamic slotName;
@dynamic speakerCollection;
@dynamic state;
@dynamic summary;
@dynamic title;
@dynamic conference;
@dynamic keywords;
@dynamic room;
@dynamic slot;
@dynamic speakers;
@dynamic videoLink;


- (NSString *)sanitizedTitle {
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz"] invertedSet];
    return [[[self.title lowercaseString] componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
}

- (NSString *) sectionTitle {
    
    static NSDateFormatter *dateFormatter;
    static NSDateFormatter *timeFormatter;

    static NSDateFormatter *dateParser;
    static NSDateFormatter *timeParser;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale autoupdatingCurrentLocale];
        dateFormatter.dateFormat = @"EEEE";
        
        timeFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale autoupdatingCurrentLocale];
        timeFormatter.dateStyle = NSDateFormatterNoStyle;
        timeFormatter.timeStyle = NSDateFormatterShortStyle;

        dateParser = [[NSDateFormatter alloc] init];
        [dateParser setDateFormat:@"yyyy-MM-dd"];

        timeParser = [[NSDateFormatter alloc] init];
        [timeParser setDateFormat:@"HH:mm"];
    });

    NSArray *parts = [self.slotName componentsSeparatedByString:@" "];

    NSString *date = [[dateFormatter stringFromDate:[dateParser dateFromString:parts[0]]] uppercaseString];
    NSString *startTime = [timeFormatter stringFromDate:[timeParser dateFromString:parts[1]]];
    NSString *endTime = [timeFormatter stringFromDate:[timeParser dateFromString:parts[3]]];

    if (date == nil || startTime == nil || endTime == nil) {
        return self.slotName;
    }

    return  [NSString stringWithFormat:@"%@ %@ - %@", date, startTime, endTime];
}

@end

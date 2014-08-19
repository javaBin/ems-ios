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
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.dateStyle = NSDateFormatterNoStyle;
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    
    NSString *date = [dateFormatter stringFromDate:self.slot.start];
    NSString *startTime = [timeFormatter stringFromDate:self.slot.start];
    NSString *endTime = [timeFormatter stringFromDate:self.slot.end];
    
    return  [NSString stringWithFormat:@"%@ %@ - %@", date, startTime, endTime];
}

@end

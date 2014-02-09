//
//  Session.m
//

#import "Session.h"


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
@dynamic slug;
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

@end

//
//  EMSSpeaker.m
//

#import "EMSSpeaker.h"

@implementation EMSSpeaker

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.name=%@", self.name];
    [description appendFormat:@", self.href=%@", self.href];
    [description appendFormat:@", self.bio=%@", self.bio];
    [description appendFormat:@", self.thumbnailUrl=%@", self.thumbnailUrl];
    [description appendFormat:@", self.lastUpdated=%@", self.lastUpdated];
    [description appendString:@">"];
    return description;
}

@end

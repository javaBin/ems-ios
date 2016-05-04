//
//  EMSConference.m
//

#import "EMSConference.h"

@implementation EMSConference

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.name=%@", self.name];
    [description appendFormat:@", self.venue=%@", self.venue];
    [description appendFormat:@", self.start=%@", self.start];
    [description appendFormat:@", self.end=%@", self.end];
    [description appendFormat:@", self.href=%@", self.href];
    [description appendFormat:@", self.slotCollection=%@", self.slotCollection];
    [description appendFormat:@", self.roomCollection=%@", self.roomCollection];
    [description appendFormat:@", self.sessionCollection=%@", self.sessionCollection];
    [description appendFormat:@", self.hintCount=%@", self.hintCount];
    [description appendString:@">"];
    return description;
}

@end

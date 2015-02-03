//
//  EMSSession.m
//

#import "EMSSession.h"

@implementation EMSSession

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.href=%@", self.href];
    [description appendFormat:@", self.format=%@", self.format];
    [description appendFormat:@", self.body=%@", self.body];
    [description appendFormat:@", self.state=%@", self.state];
    [description appendFormat:@", self.audience=%@", self.audience];
    [description appendFormat:@", self.keywords=%@", self.keywords];
    [description appendFormat:@", self.title=%@", self.title];
    [description appendFormat:@", self.language=%@", self.language];
    [description appendFormat:@", self.summary=%@", self.summary];
    [description appendFormat:@", self.level=%@", self.level];
    [description appendFormat:@", self.videoLink=%@", self.videoLink];
    [description appendFormat:@", self.speakers=%@", self.speakers];
    [description appendFormat:@", self.attachmentCollection=%@", self.attachmentCollection];
    [description appendFormat:@", self.speakerCollection=%@", self.speakerCollection];
    [description appendFormat:@", self.roomItem=%@", self.roomItem];
    [description appendFormat:@", self.slotItem=%@", self.slotItem];
    [description appendString:@">"];
    return description;
}

@end

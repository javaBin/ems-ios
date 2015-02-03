//
//  EMSSlot.m
//

#import "EMSSlot.h"

@implementation EMSSlot

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.start=%@", self.start];
    [description appendFormat:@", self.end=%@", self.end];
    [description appendFormat:@", self.href=%@", self.href];
    [description appendString:@">"];
    return description;
}

@end

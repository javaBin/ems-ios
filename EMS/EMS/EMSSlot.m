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

- (NSDate *)end {
   
    return [NSDate dateWithTimeInterval:self.duration*60 sinceDate:self.start];
}

@end

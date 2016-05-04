//
//  EMSRoom.m
//

#import "EMSRoom.h"

@implementation EMSRoom

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.name=%@", self.name];
    [description appendFormat:@", self.href=%@", self.href];
    [description appendString:@">"];
    return description;
}

@end

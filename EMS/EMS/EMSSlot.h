//
//  EMSSlot.h
//

#import <Foundation/Foundation.h>

@interface EMSSlot : NSObject

@property(strong, nonatomic) NSDate *start;
@property(readonly, nonatomic) NSDate *end;

@property(strong, nonatomic) NSURL *href;

@property(nonatomic) NSInteger duration;

- (NSString *)description;

@end

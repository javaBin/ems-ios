//
//  EMSSlot.h
//

#import <Foundation/Foundation.h>

@interface EMSSlot : NSObject

@property (strong, nonatomic) NSDate   *start;
@property (strong, nonatomic) NSDate   *end;

@property (strong, nonatomic) NSURL *href;

@end

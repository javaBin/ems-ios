//
//  EMSRoom.h
//

#import <Foundation/Foundation.h>

@interface EMSRoom : NSObject

@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) NSURL *href;

- (NSString *)description;

@end

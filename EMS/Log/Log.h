// Wraps DDLog to make it swift accessible. Lumberjack has development on a swift compatible version but it's not ready yet

#import <Foundation/Foundation.h>

@interface Log : NSObject

+ (void) debug:(NSString *)message;
+ (void) info:(NSString *)message;
+ (void) warn:(NSString *)message;
+ (void) error:(NSString *)message;

@end
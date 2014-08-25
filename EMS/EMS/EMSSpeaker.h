//
//  EMSSpeaker.h
//

#import <Foundation/Foundation.h>

@interface EMSSpeaker : NSObject

@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) NSURL *href;
@property(strong, nonatomic) NSString *bio;
@property(strong, nonatomic) NSURL *thumbnailUrl;
@property(strong, nonatomic) NSDate *lastUpdated;

@end

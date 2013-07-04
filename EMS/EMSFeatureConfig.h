//
//  EMSFeatureConfig.h
//

#import <Foundation/Foundation.h>

@interface EMSFeatureConfig : NSObject

typedef enum EMSFeature : NSUInteger {
    fLocalNotifications, fBioPics, fMarkdown
} EMSFeature;

+ (BOOL)isFeatureEnabled:(EMSFeature) feature;

- (void) refreshConfigFile;

@end

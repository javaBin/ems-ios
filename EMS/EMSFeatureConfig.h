//
//  EMSFeatureConfig.h
//

#import <Foundation/Foundation.h>

@interface EMSFeatureConfig : NSObject

typedef enum EMSFeature : NSUInteger {
    fLocalNotifications
} EMSFeature;

+ (BOOL)isFeatureEnabled:(EMSFeature) feature;

@end

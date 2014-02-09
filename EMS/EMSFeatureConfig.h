//
//  EMSFeatureConfig.h
//

#import <Foundation/Foundation.h>

@interface EMSFeatureConfig : NSObject

typedef enum EMSFeature : NSUInteger {
    fLocalNotifications, fBioPics, fMarkdown, fLinks, fRemoteNotifications
} EMSFeature;

+ (BOOL)isFeatureEnabled:(EMSFeature)feature;

- (void)refreshConfigFile;

@end

//
//  EMSFeatureConfig.m
//

#import "EMSFeatureConfig.h"

@implementation EMSFeatureConfig

+ (BOOL) isFeatureEnabled:(EMSFeature)feature {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    NSDictionary *features = [prefs objectForKey:@"features"];

    if (feature == fLocalNotifications) {
        return [[features objectForKey:@"local-notifications"] boolValue];
    }

    return NO;
}

@end

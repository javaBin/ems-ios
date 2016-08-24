//
//  EMSFeatureConfig.m
//

@implementation EMSFeatureConfig

+ (NSDictionary *)openDict:(NSString *)name {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];

    return dict;
}

+ (NSDictionary *)configDictionary {
    return [self openDict:@"EMS-Config"];
}

+ (NSDictionary *)keyDictionary {
    return [self openDict:@"EMS-Keys"];
}

+ (BOOL)isFeatureEnabled:(EMSFeature)feature {
    NSDictionary *config = [EMSFeatureConfig configDictionary];
    NSDictionary *features = config[@"features"];

    if (feature == fLocalNotifications) {
        return [features[@"local-notifications"] boolValue];
    }

    if (feature == fBioPics) {
        return [features[@"speaker-thumbnails"] boolValue];
    }

    if (feature == fLinks) {
        return [features[@"links"] boolValue];
    }

    if (feature == fRemoteNotifications) {
        return [features[@"remote-notifications"] boolValue];
        return NO;
    }

    return NO;
}

+ (BOOL)isGoogleAnalyticsEnabled {
    return ([self keyDictionary][@"google-analytics-tracking-id"] != nil);
}

+ (BOOL)isRatingEnabled {
    return ([self configDictionary][@"rating-server"] != nil);
}

@end

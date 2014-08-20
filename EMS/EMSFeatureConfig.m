//
//  EMSFeatureConfig.m
//

@implementation EMSFeatureConfig

+ (NSDictionary *)featureFlagDictionary {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];

    return prefs;
}

+ (BOOL)isFeatureEnabled:(EMSFeature)feature {
    NSDictionary *prefs = [EMSFeatureConfig featureFlagDictionary];
    NSDictionary *features = prefs[@"features"];

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
        if ([self isParseEnabled]) {
            return [features[@"remote-notifications"] boolValue];
        } else {
            return NO;
        }
    }

    return NO;
}

+ (BOOL)isCrashlyticsEnabled {
    return ([self getKeys][@"crashlytics-api-key"] != nil);
}

+ (BOOL)isGoogleAnalyticsEnabled {
    return ([self getKeys][@"google-analytics-tracking-id"] != nil);
}

+ (BOOL)isParseEnabled {
    NSDictionary *prefs = [self getKeys];

    NSString *idKey = @"parse-app-id";
    NSString *clientKey = @"parse-client-key";

#ifdef DEBUG
#ifdef TEST_PROD_NOTIFICATIONS
    idKey = @"parse-app-id-prod";
    clientKey = @"parse-client-key-prod";
#endif
#else
    idKey = @"parse-app-id-prod";
    clientKey = @"parse-client-key-prod";
#endif

    return ([[prefs allKeys] containsObject:idKey] && [[prefs allKeys] containsObject:clientKey]);
}


+ (NSDictionary *)getKeys {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Keys" ofType:@"plist"];

    return [[NSDictionary alloc] initWithContentsOfFile:filePath];
}

@end

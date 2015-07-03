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
        if ([self isParseEnabled]) {
            return [features[@"remote-notifications"] boolValue];
        } else {
            return NO;
        }
    }

    return NO;
}

+ (BOOL)isCrashlyticsEnabled {
    return ([self keyDictionary][@"crashlytics-api-key"] != nil);
}

+ (BOOL)isGoogleAnalyticsEnabled {
    return ([self keyDictionary][@"google-analytics-tracking-id"] != nil);
}

+ (BOOL)isRatingEnabled {
    return ([self configDictionary][@"rating-server"] != nil);
}

+ (BOOL)isParseEnabled {
    NSDictionary *keys = [self keyDictionary];

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

    return ([[keys allKeys] containsObject:idKey] && [[keys allKeys] containsObject:clientKey]);
}



@end

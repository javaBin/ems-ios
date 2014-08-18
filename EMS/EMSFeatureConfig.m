//
//  EMSFeatureConfig.m
//

#import "EMSFeatureConfig.h"
#import "EMSAppDelegate.h"

@implementation EMSFeatureConfig

+ (NSString *)workingFile {
    return [[[[EMSAppDelegate sharedAppDelegate] applicationCacheDirectory] URLByAppendingPathComponent:@"EMS-Config.plist"] path];
}

+ (NSDictionary *)defaultDictionary {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];

    return prefs;
}

+ (NSDictionary *)workingDictionary {
    EMS_LOG(@"Looking for config");

    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:[EMSFeatureConfig workingFile]];

    if (prefs == nil) {
        EMS_LOG(@"Looking for default config");

        prefs = [EMSFeatureConfig defaultDictionary];
    }

    return prefs;
}

+ (BOOL)isFeatureEnabled:(EMSFeature)feature {
    NSDictionary *prefs = [EMSFeatureConfig workingDictionary];
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

- (void)refreshConfigFile {
    NSDictionary *prefs = [EMSFeatureConfig defaultDictionary];

    if (![[prefs allKeys] containsObject:@"ems-config-url"]) {
        EMS_LOG(@"No config file to poll");
        return;
    }

    NSURL *onlineConfig = [NSURL URLWithString:prefs[@"ems-config-url"]];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    dispatch_async(queue, ^{
        NSError *error = nil;

        EMS_LOG(@"Checking for config file");

        NSData *data = [NSData dataWithContentsOfURL:onlineConfig options:NSDataReadingMappedIfSafe error:&error];

        if (data == nil) {
            EMS_LOG(@"Retrieved nil config %@ - %@ - %@", onlineConfig, error, [error userInfo]);

            [[EMSAppDelegate sharedAppDelegate] stopNetwork];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                EMS_LOG(@"Storing config file");

                [data writeToFile:[EMSFeatureConfig workingFile] atomically:YES];

                [[EMSAppDelegate sharedAppDelegate] stopNetwork];
            });
        }
    });
}

@end

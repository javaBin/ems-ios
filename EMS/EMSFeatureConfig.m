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
    CLS_LOG(@"Looking for config");

    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:[EMSFeatureConfig workingFile]];

    if (prefs == nil) {
        CLS_LOG(@"Looking for default config");

        prefs = [EMSFeatureConfig defaultDictionary];
    }

    return prefs;
}

+ (BOOL)isFeatureEnabled:(EMSFeature)feature {
    NSDictionary *prefs = [EMSFeatureConfig workingDictionary];
    NSDictionary *features = [prefs objectForKey:@"features"];

    if (feature == fLocalNotifications) {
        return [[features objectForKey:@"local-notifications"] boolValue];
    }

    if (feature == fBioPics) {
        return [[features objectForKey:@"speaker-thumbnails"] boolValue];
    }

    if (feature == fMarkdown) {
        return [[features objectForKey:@"markdown"] boolValue];
    }

    if (feature == fLinks) {
        return [[features objectForKey:@"links"] boolValue];
    }

    return NO;
}

- (void)refreshConfigFile {
    NSDictionary *prefs = [EMSFeatureConfig defaultDictionary];

    if (![[prefs allKeys] containsObject:@"ems-config-url"]) {
        CLS_LOG(@"No config file to poll");
        return;
    }

    NSURL *onlineConfig = [NSURL URLWithString:[prefs objectForKey:@"ems-config-url"]];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    dispatch_async(queue, ^{
        NSError *error = nil;

        CLS_LOG(@"Checking for config file");

        NSData *data = [NSData dataWithContentsOfURL:onlineConfig options:NSDataReadingMappedIfSafe error:&error];

        if (data == nil) {
            CLS_LOG(@"Retrieved nil config %@ - %@ - %@", onlineConfig, error, [error userInfo]);

            [[EMSAppDelegate sharedAppDelegate] stopNetwork];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                CLS_LOG(@"Storing config file");

                [data writeToFile:[EMSFeatureConfig workingFile] atomically:YES];

                [[EMSAppDelegate sharedAppDelegate] stopNetwork];
            });
        }
    });
}

@end

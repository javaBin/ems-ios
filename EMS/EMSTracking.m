//
// EMSTracking.m
//

#import "EMSTracking.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"


@implementation EMSTracking

+ (void)initializeTrackerWithKey:(NSString *)key {
    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        [[GAI sharedInstance] trackerWithTrackingId:key];

#ifdef DEBUG
        [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
#endif
    }

}

+ (void)trackScreen:(NSString *)name {
    EMS_LOG(@"Tracking Screen %@", name);

    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker set:kGAIScreenName value:name];

        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
}

+ (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label {
    [self trackEventWithCategory:category action:action label:label value:nil];

}

+ (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value {
    EMS_LOG(@"Tracking Event with Category %@, action %@, label %@ and value %@", category, action, label, value);

    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                              action:action
                                                               label:label
                                                               value:value] build]];
    }

}

+ (void)dispatch {
    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        [[GAI sharedInstance] dispatch];
    }
}

+ (void)trackException:(NSString *)description {
    EMS_LOG(@"Tracking Exception with Description %@", description);

    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker send:[[GAIDictionaryBuilder createExceptionWithDescription:description withFatal:@NO] build]];
    }
}

+ (void)trackSocialWithNetwork:(NSString *)network action:(NSString *)action target:(NSString *)target {
    EMS_LOG(@"Tracking Social with network %@, action %@ and target %@", network, action, target);

    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker send:[[GAIDictionaryBuilder createSocialWithNetwork:network
                                                              action:action
                                                              target:target] build]];
    }
}

+ (void)trackTimingWithCategory:(NSString *)category interval:(NSNumber *)interval name:(NSString *)name {
    EMS_LOG(@"Tracking Timing with Category %@, interval %@ and name %@", category, interval, name);

    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker send:[[GAIDictionaryBuilder createTimingWithCategory:category
                                                             interval:interval
                                                                 name:name
                                                                label:nil] build]];
    }
}

@end
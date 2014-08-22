//
// Created by Chris Searle on 22/08/14.
// Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EMSTracking : NSObject

+ (void) initializeTrackerWithKey:(NSString *)key;
+ (void) trackScreen:(NSString *)name;
+ (void) trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label;
+ (void) trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value;

+ (void)dispatch;

+ (void)trackException:(NSString *)description;

+ (void)trackSocialWithNetwork:(NSString *)network action:(NSString *)action target:(NSString *)target;

+ (void)trackTimingWithCategory:(NSString *)category interval:(NSNumber *)interval name:(NSString *)name;
@end
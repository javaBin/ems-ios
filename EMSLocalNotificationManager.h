//
//  EMSLocalNotificationManager2.h
//  EMS
//
//  Created by Jobb on 22.08.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMSLocalNotificationManager : NSObject

+ (EMSLocalNotificationManager *) sharedInstance;

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;

@end

//
//  EMSNotificationManager.m
//  EMS
//
//  Created by Jobb on 22.08.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "EMSLocalNotificationManager.h"
#import "EMSAppDelegate.h"
#import "EMSMainViewController.h"
#import "EMSDetailViewController.h"
#import "EMSTracking.h"

// This class is not Thread safe. Call all methods on main Thread.

@interface EMSLocalNotificationManager ()<UIAlertViewDelegate>

@end

@implementation EMSLocalNotificationManager {
    @private
    
    NSMutableDictionary *_notificationDictionary;

    NSInteger _nextAlertViewTag;
    
}

- (id)init {
    self = [super init];
    if (self) {
        _notificationDictionary = [NSMutableDictionary dictionary];
        _nextAlertViewTag = 0;
    }
    return self;
}


+ (EMSLocalNotificationManager *) sharedInstance {
    
    static EMSLocalNotificationManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMSLocalNotificationManager alloc] init];
    });
    
    return sharedInstance;
}

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if ([EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
        [EMSTracking trackEventWithCategory:@"system" action:@"notification" label:@"initialize"];
        
        UILocalNotification *notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
        if (notification) {
            [[EMSLocalNotificationManager sharedInstance] activateWithNotification:notification];
        }
        
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if ([EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
        
        [EMSTracking trackEventWithCategory:@"system" action:@"notification" label:@"receive"];
        
        NSString *sessionUrl = [notification userInfo][@"sessionhref"];
        
        Session *session = [[[EMSAppDelegate sharedAppDelegate] model] sessionForHref:sessionUrl];
        
        if (!session) {
            //If we don´t find a session we assume database have been deleted together with favorites, so no need to continue.
            return;
        }
        
        UIApplicationState state = [[UIApplication sharedApplication] applicationState];
        if (state == UIApplicationStateActive) {
            [self presentLocalNotificationAlert:notification];
        } else {
            //Notification received when running in background, the system already showed an alert.
            [self activateWithNotification:notification];
        }
        
        
    }
}

#pragma mark - Present Session

- (void)navigationController:(UINavigationController *)navController presentSessionUrl:(NSString *)sessionUrl {
    [navController popToRootViewControllerAnimated:NO];

    
    UIViewController *controller = navController.viewControllers[0];
    
    
    
    if ([controller isKindOfClass:[EMSMainViewController class]]) {
        
        EMSMainViewController *emsView = (EMSMainViewController *) controller;
        
        [emsView pushDetailViewForHref:sessionUrl];
    }
}

- (void)activateWithNotification:(UILocalNotification *)notification {
    
    if (![EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
        return;
    }
    
    NSAssert(notification, @"notification was nil");
    
    NSDictionary *userInfo = [notification userInfo];
    
    EMS_LOG(@"Starting with a notification with userInfo %@", userInfo);
    
    NSString *sessionUrl = userInfo[@"sessionhref"];
    
    if (sessionUrl) {

        if ([EMSFeatureConfig isCrashlyticsEnabled]) {
            [Crashlytics setObjectValue:sessionUrl forKey:@"lastDetailSessionFromNotification"];
        }
        
      
        [EMSTracking trackEventWithCategory:@"listView" action:@"detailFromNotification" label:sessionUrl];
        
        
        Session *session = [[[EMSAppDelegate sharedAppDelegate] model] sessionForHref:sessionUrl];
        
        if (session) {//If we don´t find session, assume database have been deleted together with favorite, so don´t show alert.
            if (![session.conference.href isEqualToString:[[EMSAppDelegate currentConference] absoluteString]]) {
                [EMSAppDelegate storeCurrentConference:[NSURL URLWithString:session.conference.href]];
            }
            
            EMS_LOG(@"Preparing detail view from passed href %@", session);
            
            UIViewController *rootViewController = [[[EMSAppDelegate sharedAppDelegate] window] rootViewController];
            
            if ([rootViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navController = (UINavigationController *) rootViewController;
    
                if (navController.visibleViewController.presentingViewController) {
                    [navController dismissViewControllerAnimated:YES completion:^{
                        [self navigationController:navController presentSessionUrl:sessionUrl];
                    }];
                } else {
                    [self navigationController:navController presentSessionUrl:sessionUrl];
                }
                
            }
            
        }
        
       
    }
    
}



#pragma mark - Present Notification

- (void)presentLocalNotificationAlert:(UILocalNotification *)notification {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Reminder", @"Title for local notification about upcoming session.")
                                                    message:notification.alertBody
                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:notification.alertAction, nil];
    
    alert.delegate = self;
    alert.tag = _nextAlertViewTag++;
    
    _notificationDictionary[@(alert.tag)] = notification;
    
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        
        UILocalNotification *notification = _notificationDictionary[@(alertView.tag)];
        
        if (notification) {
            [_notificationDictionary removeObjectForKey:@(alertView.tag)];
            
            
           
            [self activateWithNotification:notification];
        }
    }
    
}

@end


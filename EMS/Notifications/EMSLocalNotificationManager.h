//
//  EMSLocalNotificationManager.h
//

#import <Foundation/Foundation.h>

extern NSString *const EMSUserRequestedSessionNotification;
extern NSString *const EMSUserRequestedSessionNotificationSessionKey;

@interface EMSLocalNotificationManager : NSObject

+ (EMSLocalNotificationManager *) sharedInstance;

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;

@end

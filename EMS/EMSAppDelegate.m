//
//  EMSAppDelegate.m
//

#import "EMSAppDelegate.h"
#import "EMSMainViewController.h"

#import "EMSFeatureConfig.h"

@implementation EMSAppDelegate

int networkCount = 0;

@synthesize managedObjectContext = __managedObjectContext;
@synthesize uiManagedObjectContext = __uiManagedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize model = __model;


- (void)handleIncomingRemoteNotification:(NSDictionary *)dictionary {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        CLS_LOG(@"Incoming remote notification: %@", dictionary);

        [PFPush handlePush:dictionary];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Keys" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];

#ifndef DO_NOT_USE_CRASHLYTICS
    [Crashlytics startWithAPIKey:prefs[@"crashlytics-api-key"]];
#endif

#ifndef DO_NOT_USE_GA
    [GAI sharedInstance].trackUncaughtExceptions = YES;
#ifdef DEBUG
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
#endif
#endif

    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
#ifdef DEBUG
#ifdef TEST_PROD_NOTIFICATIONS
        [Parse setApplicationId:prefs[@"parse-app-id-prod"]
                      clientKey:prefs[@"parse-client-key-prod"]];
#else
        [Parse setApplicationId:prefs[@"parse-app-id"]
                      clientKey:prefs[@"parse-client-key"]];
#endif
#else
    [Parse setApplicationId:prefs[@"parse-app-id-prod"]
                  clientKey:prefs[@"parse-client-key-prod"]];
#endif
    }

    [self cleanup];

#ifndef DO_NOT_USE_GA
    id <GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:prefs[@"google-analytics-tracking-id"]];
    [GAI sharedInstance].trackUncaughtExceptions = NO; //GAI runs the main runloop after a crash occured. This might lead to asyncronous events being executed which in turn can lead to serious bugs. The main reason for disabling was that it leaded to deadlock in core data. 
#endif

    if ([EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
#ifndef DO_NOT_USE_GA
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                              action:@"notification"
                                                               label:@"initialize"
                                                               value:nil] build]];
#endif

        UILocalNotification *notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];

        [self activateWithNotification:notification];
    }

    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
#ifndef DO_NOT_USE_GA
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                              action:@"remotenotification"
                                                               label:@"initialize"
                                                               value:nil] build]];
#endif
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];

        if (launchOptions != nil) {
            NSDictionary *dictionary = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
            if (dictionary != nil) {
#ifndef DO_NOT_USE_GA
                [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                                      action:@"remotenotification"
                                                                       label:@"init-receive"
                                                                       value:nil] build]];
#endif

                CLS_LOG(@"Launched from push notification: %@", dictionary);
                [self handleIncomingRemoteNotification:dictionary];
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (![[[EMSAppDelegate sharedAppDelegate] model] conferencesWithDataAvailable]) {
            CLS_LOG(@"Retrieving conferences");
            [[EMSRetriever sharedInstance] refreshConferences];
        }
        
    });

    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
#ifndef DO_NOT_USE_GA
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                              action:@"remotenotification"
                                                               label:@"receive"
                                                               value:nil] build]];

        [[GAI sharedInstance] dispatch];
#endif

        [self handleIncomingRemoteNotification:userInfo];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
#ifndef DO_NOT_USE_GA
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    

        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                              action:@"remotenotification"
                                                               label:@"register"
                                                               value:nil] build]];
#endif

        [[GAI sharedInstance] dispatch];

        CLS_LOG(@"My token is: %@", deviceToken);

        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setDeviceTokenFromData:deviceToken];
        [currentInstallation addUniqueObject:@"Conference" forKey:@"channels"];
        [currentInstallation saveInBackground];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        CLS_LOG(@"Failed to get token, error: %@ [%@]", error, [error userInfo]);
    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
    networkCount = 0;
    [self stopNetwork];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    networkCount = 0;
    [self stopNetwork];

#ifndef SKIP_CONFIG_REFRESH
    EMSFeatureConfig *featureConfig = [[EMSFeatureConfig alloc] init];
    [featureConfig refreshConfigFile];
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self syncManagedObjectContext];
}


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if ([EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
#ifndef DO_NOT_USE_GA
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                              action:@"notification"
                                                               label:@"receive"
                                                               value:nil] build]];

        [[GAI sharedInstance] dispatch];
#endif
        [self activateWithNotification:notification];
    }
}

- (void)remove:(NSString *)path {
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        CLS_LOG(@"Deleting %@", path);

        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            CLS_LOG("Failed to delete %@ - %@ - %@", path, error, [error userInfo]);
        }
    }
}

- (void)cleanup {
    [self remove:[[[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"incogito.sqlite"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"bioIcons"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"labelIcons"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"levelIcons"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"SHK"] path]];
}

- (void)activateWithNotification:(UILocalNotification *)notification {
    if (![EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
        return;
    }

    if (notification != nil) {
        NSDictionary *userInfo = [notification userInfo];

        CLS_LOG(@"Starting with a notification with userInfo %@", userInfo);

        if (userInfo != nil && [[userInfo allKeys] containsObject:@"sessionhref"]) {
            NSString *url = [userInfo valueForKey:@"sessionhref"];

            Conference *conference = [self.model conferenceForSessionHref:url];

            [EMSAppDelegate storeCurrentConference:[NSURL URLWithString:conference.href]];

            UIViewController *rootViewController = [[self window] rootViewController];

            if ([rootViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navController = (UINavigationController *) rootViewController;

                [navController popToRootViewControllerAnimated:YES];

                UIViewController *controller = [navController visibleViewController];

                if ([controller isKindOfClass:[EMSMainViewController class]]) {

                    EMSMainViewController *emsView = (EMSMainViewController *) controller;

                    [emsView pushDetailViewForHref:url];
                }
            }
        }
    }
}

- (EMSModel *)model {
    if (__model != nil) {
        return __model;
    }

    CLS_LOG(@"No model - initializing");

    __model = [[EMSModel alloc] initWithManagedObjectContext:[self uiManagedObjectContext]];

    return __model;
}


#pragma mark -
#pragma mark Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }

    CLS_LOG(@"No moc - initializing");

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    CLS_LOG(@"No moc - initialized");

    return __managedObjectContext;
}

- (NSManagedObjectContext *)uiManagedObjectContext {
    if (__uiManagedObjectContext != nil) {
        return __uiManagedObjectContext;
    }

    CLS_LOG(@"No UI moc - initializing");

    NSManagedObjectContext *parent = [self managedObjectContext];
    if (parent != nil) {
        __uiManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [__uiManagedObjectContext setUndoManager:nil];
        [__uiManagedObjectContext setParentContext:parent];
    }

    CLS_LOG(@"No moc - initialized");

    return __uiManagedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }

    CLS_LOG(@"No mom - initializing");

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EMSCoreDataModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    CLS_LOG(@"No mom - initialized");

    return __managedObjectModel;
}

- (EMSModel *)modelForBackground {
    CLS_LOG(@"Creating background model");

    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    [backgroundContext setUndoManager:nil];
    [backgroundContext setParentContext:self.uiManagedObjectContext];

    EMSModel *backgroundModel = [[EMSModel alloc] initWithManagedObjectContext:backgroundContext];

    return backgroundModel;
}

- (void)syncManagedObjectContext {
    NSError *error = nil;
    if (__uiManagedObjectContext != nil) {
        if ([__uiManagedObjectContext hasChanges] && ![__uiManagedObjectContext save:&error]) {
            CLS_LOG(@"Failed to save ui data at shutdown %@, %@", error, [error userInfo]);
        }
    }
    error = nil;
    if (__managedObjectContext != nil) {
        if ([__managedObjectContext hasChanges] && ![__managedObjectContext save:&error]) {
            CLS_LOG(@"Failed to save data at shutdown %@, %@", error, [error userInfo]);
        }
    }
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }

    CLS_LOG(@"No persistent store - initializing");

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"EMSCoreDataModel.sqlite"];

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES};

    NSError *error = nil;
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        CLS_LOG(@"Failed to set up SQL database. Deleting. %@, %@", error, [error userInfo]);

        //delete the sqlite file and try again
        NSError *deleteError = nil;

        if (![[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&deleteError]) {
            CLS_LOG(@"Failed to delete database on failed first attempt %@, %@", deleteError, [deleteError userInfo]);
        }

        NSError *error2 = nil;

        if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error2]) {
            CLS_LOG(@"Failed to set up database on second attempt %@, %@", error2, [error2 userInfo]);

            [self showErrorAlertWithTitle:@"Database error" andMessage:@"We failed to create the database. If this happens again after an application restart please delete and re-install."];
        }
    }

    CLS_LOG(@"No persistent store - initialized");

    return __persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationCacheDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)showErrorAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *errorAlert = [[UIAlertView alloc]
            initWithTitle:title
                  message:message
                 delegate:nil
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
    [errorAlert show];
}

+ (EMSAppDelegate *)sharedAppDelegate {
    return (EMSAppDelegate *) [[UIApplication sharedApplication] delegate];
}

- (void)startNetwork {
    networkCount++;

    UIApplication *app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = YES;

    CLS_LOG(@"startNetwork finished with %d", networkCount);
}

- (void)stopNetwork {
    CLS_LOG(@"stopNetwork started with %d", networkCount);

    networkCount--;

    if (networkCount < 0) {
        networkCount = 0;
    }

    if (networkCount == 0) {
        UIApplication *app = [UIApplication sharedApplication];
        app.networkActivityIndicatorVisible = NO;
    }
}

+ (void)storeCurrentConference:(NSURL *)href {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setURL:href forKey:@"activeConference"];

    [defaults synchronize];

    
    // Refresh sessions for conference if neccesary.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (![EMSAppDelegate currentConference]) {
            return ;
        }
        
        if (![[[EMSAppDelegate sharedAppDelegate] model] sessionsAvailableForConference:[[EMSAppDelegate currentConference] absoluteString]]) {
            CLS_LOG(@"Checking for existing data found no data - forced refresh");
            [[EMSRetriever sharedInstance] refreshActiveConference];
            
        }
    }];

#ifndef DO_NOT_USE_CRASHLYTICS
    [Crashlytics setObjectValue:href forKey:@"lastStoredConference"];
#endif
}

+ (NSURL *)currentConference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSURL *href = [defaults URLForKey:@"activeConference"];

#ifndef DO_NOT_USE_CRASHLYTICS
    [Crashlytics setObjectValue:href forKey:@"lastRetrievedConference"];
#endif

    return href;
}

@end

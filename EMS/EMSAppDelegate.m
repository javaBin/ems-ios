//
//  EMSAppDelegate.m
//

#import "EMSAppDelegate.h"
#import "EMSMainViewController.h"

@implementation EMSAppDelegate

int networkCount = 0;

@synthesize managedObjectContext = __managedObjectContext;
@synthesize uiManagedObjectContext = __uiManagedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize model = __model;


- (void)handleIncomingRemoteNotification:(NSDictionary *)dictionary {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        EMS_LOG(@"Incoming remote notification: %@", dictionary);

        [PFPush handlePush:dictionary];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    EMS_LOG(@"WE STARTED");

    NSDictionary *prefs = [EMSFeatureConfig getKeys];

    if ([EMSFeatureConfig isCrashlyticsEnabled]) {
#ifdef DEBUG
        [[Crashlytics sharedInstance] setDebugMode:YES];
#endif
        [Crashlytics startWithAPIKey:prefs[@"crashlytics-api-key"] delegate:self];
    }


    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        [GAI sharedInstance].trackUncaughtExceptions = YES;
#ifdef DEBUG
        [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
#endif
    }

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

    id <GAITracker> tracker = nil;

    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        tracker = [[GAI sharedInstance] trackerWithTrackingId:prefs[@"google-analytics-tracking-id"]];
        [GAI sharedInstance].trackUncaughtExceptions = NO; //GAI runs the main runloop after a crash occured. This might lead to asyncronous events being executed which in turn can lead to serious bugs. The main reason for disabling was that it leaded to deadlock in core data.
    }

    if ([EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
        if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                                  action:@"notification"
                                                                   label:@"initialize"
                                                                   value:nil] build]];
        }

        UILocalNotification *notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];

        [self activateWithNotification:notification];
    }

    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                                  action:@"remotenotification"
                                                                   label:@"initialize"
                                                                   value:nil] build]];
        }

        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];

        if (launchOptions != nil) {
            NSDictionary *dictionary = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
            if (dictionary != nil) {
                if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
                    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                                          action:@"remotenotification"
                                                                           label:@"init-receive"
                                                                           value:nil] build]];
                }

                EMS_LOG(@"Launched from push notification: %@", dictionary);
                [self handleIncomingRemoteNotification:dictionary];
            }
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{

        if (![[[EMSAppDelegate sharedAppDelegate] model] conferencesWithDataAvailable]) {
            EMS_LOG(@"Retrieving conferences");
            [[EMSRetriever sharedInstance] refreshConferences];
        }

    });

    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
            id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                                  action:@"remotenotification"
                                                                   label:@"receive"
                                                                   value:nil] build]];

            [[GAI sharedInstance] dispatch];
        }

        [self handleIncomingRemoteNotification:userInfo];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
            id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];


            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                                  action:@"remotenotification"
                                                                   label:@"register"
                                                                   value:nil] build]];

            [[GAI sharedInstance] dispatch];
        }


        EMS_LOG(@"My token is: %@", deviceToken);

        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setDeviceTokenFromData:deviceToken];
        [currentInstallation addUniqueObject:@"Conference" forKey:@"channels"];

        [currentInstallation saveEventually:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                NSString *log = [NSString stringWithFormat:@"Unable to save Conference channel due to Code: %ld, Domain: %@, Info: %@", (long)error.code, [error domain], [error userInfo]];

                EMS_LOG(@"%@", log);

                if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
                    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
                        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                        
                        [tracker send:[[GAIDictionaryBuilder createExceptionWithDescription:log withFatal:@NO] build]];
                    }
                }
            }
        }];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        EMS_LOG(@"Failed to get token, error: %@ [%@]", error, [error userInfo]);
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
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self syncManagedObjectContext];
}


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if ([EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
        if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
            id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"system"
                                                                  action:@"notification"
                                                                   label:@"receive"
                                                                   value:nil] build]];

            [[GAI sharedInstance] dispatch];
        }

        [self activateWithNotification:notification];
    }
}

- (void)remove:(NSString *)path {
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        EMS_LOG(@"Deleting %@", path);

        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            EMS_LOG(@"Failed to delete %@ - %@ - %@", path, error, [error userInfo]);
        }
    }
}

- (void)cleanup {
    [self remove:[[[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"incogito.sqlite"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"bioIcons"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"labelIcons"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"levelIcons"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"SHK"] path]];
    [self remove:[[[self applicationCacheDirectory] URLByAppendingPathComponent:@"EMS-Config.plist"] path]];
}

- (void)activateWithNotification:(UILocalNotification *)notification {
    if (![EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
        return;
    }

    if (notification != nil) {
        NSDictionary *userInfo = [notification userInfo];

        EMS_LOG(@"Starting with a notification with userInfo %@", userInfo);

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

    EMS_LOG(@"No model - initializing");

    __model = [[EMSModel alloc] initWithManagedObjectContext:[self uiManagedObjectContext]];

    return __model;
}


#pragma mark -
#pragma mark Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }

    EMS_LOG(@"No moc - initializing");

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    EMS_LOG(@"No moc - initialized");

    return __managedObjectContext;
}

- (NSManagedObjectContext *)uiManagedObjectContext {
    if (__uiManagedObjectContext != nil) {
        return __uiManagedObjectContext;
    }

    EMS_LOG(@"No UI moc - initializing");

    NSManagedObjectContext *parent = [self managedObjectContext];
    if (parent != nil) {
        __uiManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [__uiManagedObjectContext setUndoManager:nil];
        [__uiManagedObjectContext setParentContext:parent];
    }

    EMS_LOG(@"No moc - initialized");

    return __uiManagedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }

    EMS_LOG(@"No mom - initializing");

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EMSCoreDataModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    EMS_LOG(@"No mom - initialized");

    return __managedObjectModel;
}

- (EMSModel *)modelForBackground {
    EMS_LOG(@"Creating background model");

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
            EMS_LOG(@"Failed to save ui data at shutdown %@, %@", error, [error userInfo]);
        }
    }
    if (__managedObjectContext != nil) {
        __block NSError *mocError;
        __block BOOL savedOK = NO;

        [__managedObjectContext performBlockAndWait:^{
            if ([__managedObjectContext hasChanges]) {
                // Do lots of things with the context.
                savedOK = [__managedObjectContext save:&mocError];

                if (!savedOK) {
                    EMS_LOG(@"Failed to save data at shutdown %@, %@", mocError, [mocError userInfo]);
                }
            }
        }];
    }
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }

    EMS_LOG(@"No persistent store - initializing");

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"EMSCoreDataModel.sqlite"];

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES};

    NSError *error = nil;
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        EMS_LOG(@"Failed to set up SQL database. Deleting. %@, %@", error, [error userInfo]);

        //delete the sqlite file and try again
        NSError *deleteError = nil;

        if (![[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&deleteError]) {
            EMS_LOG(@"Failed to delete database on failed first attempt %@, %@", deleteError, [deleteError userInfo]);
        }

        NSError *error2 = nil;

        if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error2]) {
            EMS_LOG(@"Failed to set up database on second attempt %@, %@", error2, [error2 userInfo]);

            [self showErrorAlertWithTitle:@"Database error" andMessage:@"We failed to create the database. If this happens again after an application restart please delete and re-install."];
        }
    }

    EMS_LOG(@"No persistent store - initialized");

    return __persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationCacheDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)showErrorAlertWithTitle:(NSString *)title
                     andMessage:
                             (NSString *)message {
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

    EMS_LOG(@"startNetwork finished with %d", networkCount);
}

- (void)stopNetwork {
    EMS_LOG(@"stopNetwork started with %d", networkCount);

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
            return;
        }

        if (![[[EMSAppDelegate sharedAppDelegate] model] sessionsAvailableForConference:[[EMSAppDelegate currentConference] absoluteString]]) {
            EMS_LOG(@"Checking for existing data found no data - forced refresh");
            [[EMSRetriever sharedInstance] refreshActiveConference];

        }
    }];

    if ([EMSFeatureConfig isCrashlyticsEnabled]) {
        [Crashlytics setObjectValue:href forKey:@"lastStoredConference"];
    }
}

+ (NSURL *)currentConference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSURL *href = [defaults URLForKey:@"activeConference"];

    if ([EMSFeatureConfig isCrashlyticsEnabled]) {
        [Crashlytics setObjectValue:href forKey:@"lastRetrievedConference"];
    }

    return href;
}

- (void)crashlyticsDidDetectCrashDuringPreviousExecution:(Crashlytics *)crashlytics {
    EMS_LOG(@"Crash detected - clearing advanced search");

    EMSAdvancedSearch *advancedSearch = [[EMSAdvancedSearch alloc] init];
    [advancedSearch clear];
}

@end

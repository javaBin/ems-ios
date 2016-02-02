
//
//  EMSAppDelegate.m
//

#import <CrashlyticsLumberjack/CrashlyticsLogger.h>
#import "EMSAppDelegate.h"
#import "EMSMainViewController.h"
#import "EMSLocalNotificationManager.h"
#import "EMSTracking.h"
#import "EMSDetailViewController.h"


@implementation EMSAppDelegate

int networkCount = 0;

@synthesize managedObjectContext = __managedObjectContext;
@synthesize backgroundManagedObjectContext = __backgroundManagedObjectContext;
@synthesize uiManagedObjectContext = __uiManagedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize model = __model;


- (void)handleIncomingRemoteNotification:(NSDictionary *)dictionary {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        DDLogVerbose(@"Incoming remote notification: %@", dictionary);
    }
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    DDLogVerbose(@"WE STARTED");

    NSDictionary *prefs = [EMSFeatureConfig keyDictionary];

    if ([EMSFeatureConfig isCrashlyticsEnabled]) {
#ifdef DEBUGCRASHLYTICS
        [[Crashlytics sharedInstance] setDebugMode:YES];
#endif
        [Crashlytics startWithAPIKey:prefs[@"crashlytics-api-key"] delegate:self];
        [DDLog addLogger:[CrashlyticsLogger sharedInstance]];

        DDLogVerbose(@"Connected to crashlytics");
    }

    [EMSTracking initializeTrackerWithKey:prefs[@"google-analytics-tracking-id"]];

    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        // TODO
    }
    
    if ([self.window.rootViewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        
        splitViewController.delegate = self;
        
        splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }
    
    

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self cleanup];


    [[EMSLocalNotificationManager sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];


    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        [EMSTracking trackEventWithCategory:@"system" action:@"remotenotification" label:@"initialize"];

#if !(TARGET_IPHONE_SIMULATOR)
            [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil]];

            [application registerForRemoteNotifications];
#endif

        if (launchOptions != nil) {
            NSDictionary *dictionary = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
            if (dictionary != nil) {
                [EMSTracking trackEventWithCategory:@"system" action:@"remotenotification" label:@"init-receive"];

                DDLogInfo(@"Launched from push notification: %@", dictionary);
                [self handleIncomingRemoteNotification:dictionary];
            }
        }
    }

    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        [EMSTracking trackEventWithCategory:@"system" action:@"remotenotification" label:@"receive"];
        [EMSTracking dispatch];

        [self handleIncomingRemoteNotification:userInfo];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        [EMSTracking trackEventWithCategory:@"system" action:@"remotenotification" label:@"register"];
        [EMSTracking dispatch];

        DDLogDebug(@"My token is: %@", deviceToken);
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
        DDLogError(@"Failed to get token, error: %@ [%@]", error, [error userInfo]);
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self syncManagedObjectContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self syncManagedObjectContext];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {

    [[EMSLocalNotificationManager sharedInstance] application:application didReceiveLocalNotification:notification];

}

- (void)remove:(NSString *)path {
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        DDLogVerbose(@"Deleting %@", path);

        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            DDLogError(@"Failed to delete %@ - %@ - %@", path, error, [error userInfo]);
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


- (EMSModel *)model {
    if (__model != nil) {
        return __model;
    }

    DDLogInfo(@"No model - initializing");

    __model = [[EMSModel alloc] initWithManagedObjectContext:[self uiManagedObjectContext]];

    return __model;
}


#pragma mark -
#pragma mark Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }

    DDLogInfo(@"No moc - initializing");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [__managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    });

    DDLogVerbose(@"No moc - initialized");

    return __managedObjectContext;
}

- (NSManagedObjectContext *)uiManagedObjectContext {
    if (__uiManagedObjectContext != nil) {
        return __uiManagedObjectContext;
    }

    DDLogInfo(@"No UI moc - initializing");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSManagedObjectContext *parent = [self managedObjectContext];
        if (parent != nil) {
            __uiManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [__uiManagedObjectContext setUndoManager:nil];
            [__uiManagedObjectContext setParentContext:parent];
        }
    });

    DDLogVerbose(@"No UI moc - initialized");

    return __uiManagedObjectContext;
}

- (NSManagedObjectContext *)backgroundManagedObjectContext {
    if (__backgroundManagedObjectContext != nil) {
        return __backgroundManagedObjectContext;
    }

    DDLogInfo(@"No background moc - initializing");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSManagedObjectContext *parent = [self uiManagedObjectContext];
        if (parent != nil) {
            __backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [__backgroundManagedObjectContext setUndoManager:nil];
            [__backgroundManagedObjectContext setParentContext:parent];
        }
    });

    DDLogVerbose(@"No background moc - initialized");

    return __backgroundManagedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }

    DDLogInfo(@"No mom - initializing");

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EMSCoreDataModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    DDLogVerbose(@"No mom - initialized");

    return __managedObjectModel;
}

- (EMSModel *)modelForBackground {
    DDLogInfo(@"Creating background model");

    NSManagedObjectContext *backgroundContext = [self backgroundManagedObjectContext];

    EMSModel *backgroundModel = [[EMSModel alloc] initWithManagedObjectContext:backgroundContext];

    return backgroundModel;
}

- (void)syncManagedObjectContext {
    NSError *error = nil;
    if (__uiManagedObjectContext != nil) {
        if ([__uiManagedObjectContext hasChanges] && ![__uiManagedObjectContext save:&error]) {
            DDLogError(@"Failed to save ui data at shutdown %@, %@", error, [error userInfo]);
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
                    DDLogError(@"Failed to save data at shutdown %@, %@", mocError, [mocError userInfo]);
                }
            }
        }];
    }
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }

    DDLogInfo(@"No persistent store - initializing");

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"EMSCoreDataModel.sqlite"];

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES};

    NSError *error = nil;
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        DDLogError(@"Failed to set up SQL database. Deleting. %@, %@", error, [error userInfo]);

        //delete the sqlite file and try again
        NSError *deleteError = nil;

        if (![[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&deleteError]) {
            DDLogError(@"Failed to delete database on failed first attempt %@, %@", deleteError, [deleteError userInfo]);
        }

        NSError *error2 = nil;

        if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error2]) {
            DDLogError(@"Failed to set up database on second attempt %@, %@", error2, [error2 userInfo]);

            [self showErrorAlertWithTitle:NSLocalizedString(@"Database error", "Database error dialog title")
                               andMessage:NSLocalizedString(@"We failed to create the database. If this happens again after an application restart please delete and re-install.", "Database error dialog message")];
        }
    }

    DDLogVerbose(@"No persistent store - initialized");

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
        cancelButtonTitle:NSLocalizedString(@"OK", "Error dialog dismiss button")
        otherButtonTitles:nil];
    [errorAlert show];
}

+ (EMSAppDelegate *)sharedAppDelegate {
    return (EMSAppDelegate *) [[UIApplication sharedApplication] delegate];
}

- (void)startNetwork {
    dispatch_async(dispatch_get_main_queue(), ^{
        networkCount++;

        UIApplication *app = [UIApplication sharedApplication];
        app.networkActivityIndicatorVisible = YES;

        DDLogVerbose(@"startNetwork finished with %d", networkCount);
    });
}

- (void)stopNetwork {
    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogVerbose(@"stopNetwork started with %d", networkCount);

        networkCount--;

        if (networkCount < 0) {
            [EMSTracking trackEventWithCategory:@"system"
                                         action:@"stopNetwork"
                                          label:[NSString stringWithFormat:@"stopNetwork went negative to %d", networkCount]];

            networkCount = 0;
        }

        if (networkCount == 0) {
            UIApplication *app = [UIApplication sharedApplication];
            app.networkActivityIndicatorVisible = NO;
        }
    });
}

- (void)crashlyticsDidDetectCrashDuringPreviousExecution:(Crashlytics *)crashlytics {
    DDLogVerbose(@"Crash detected - clearing advanced search");

    EMSAdvancedSearch *advancedSearch = [[EMSAdvancedSearch alloc] init];
    [advancedSearch clear];
}

#pragma mark - State restoration

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    NSString *archivedVersion = [coder decodeObjectForKey:UIApplicationStateRestorationBundleVersionKey];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleVersionKey];

    if (![archivedVersion isEqual:version]) { // Don´t restore across updates
        DDLogInfo(@"Bundle version is: %@, archived version is %@. Skipping state restore.", version, archivedVersion);
        return NO;
    }

    UIUserInterfaceIdiom archivedIdiom = [[coder decodeObjectForKey:UIApplicationStateRestorationUserInterfaceIdiomKey] integerValue];

    UIUserInterfaceIdiom idiom = UI_USER_INTERFACE_IDIOM();

    if (archivedIdiom != idiom) { // Don´t restore if idiom changed. E.g user restored from iPad to iPhone etc.
        DDLogInfo(@"User interface idiom in bundle %ld, does not match current user interface idiom %ld. Skipping state restore.", archivedIdiom, idiom);
        return NO;
    }

    NSString *archivedSystemVersion = [coder decodeObjectForKey:UIApplicationStateRestorationSystemVersionKey];

    NSString *systemVersion = [UIDevice currentDevice].systemVersion;

    if (![archivedSystemVersion isEqual:systemVersion]) { // Don´t restore across system versions
        DDLogInfo(@"System version in archive %@ does not match current system version %@. Skipping state restore.", archivedSystemVersion, systemVersion);
        return NO;
    }

    return YES;
}





#pragma mark - UISplitViewControllerDelegate


- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    // Never collapse...
    BOOL collapseHandled = YES;
    
    // Unless we are showing session details
    if ([self secondaryViewControllerIsShowingSessionDetails:secondaryViewController]) {
        collapseHandled = NO;
    }
    
    return collapseHandled;
}


- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    
    UINavigationController *primaryNavigationController = (UINavigationController *) primaryViewController;
    EMSMainViewController *mainViewController = (EMSMainViewController *)primaryNavigationController.viewControllers.firstObject;
    
    if (primaryNavigationController.visibleViewController == mainViewController) {
        return [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"No Session Selected Navigation Controller"];
    } 
    
    return nil;

}

- (BOOL) secondaryViewControllerIsShowingSessionDetails: (UIViewController *)secondaryViewController {
    
    BOOL isShowingSessionDetails = NO;
    
    
    UINavigationController *secondaryNavigationController = (UINavigationController *) secondaryViewController;
    if ([secondaryNavigationController.topViewController isKindOfClass:[EMSDetailViewController class]]) {
        EMSDetailViewController *detailViewController = (EMSDetailViewController *) secondaryNavigationController.topViewController;
        if (detailViewController.session != nil) {
            isShowingSessionDetails = YES;
        }
    }
    
    return isShowingSessionDetails;
}

@end

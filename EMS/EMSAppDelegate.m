//
//  EMSAppDelegate.m
//

#import "EMSAppDelegate.h"
#import "EMSModel.h"
#import "EMSMainViewController.h"

#import "Conference.h"

@implementation EMSAppDelegate

int networkCount = 0;

@synthesize managedObjectContext=__managedObjectContext;
@synthesize managedObjectModel=__managedObjectModel;
@synthesize persistentStoreCoordinator=__persistentStoreCoordinator;
@synthesize model=__model;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Keys" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    [Crashlytics startWithAPIKey:[prefs objectForKey:@"crashlytics-api-key"]];

    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    [self activateWithNotification:notification];
    
    [[self window] rootViewController];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    networkCount = 0;
    [self stopNetwork];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    networkCount = 0;
    [self stopNetwork];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSError *error = nil;
    if (__managedObjectContext != nil) {
        if ([__managedObjectContext hasChanges] && ![__managedObjectContext save:&error]) {
            CLS_LOG(@"Failed to save data at shutdown %@, %@", error, [error userInfo]);
        } 
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self activateWithNotification:notification];
}

- (void)activateWithNotification:(UILocalNotification *)notification {
    if (notification != nil) {
        NSDictionary *userInfo = [notification userInfo];

        CLS_LOG(@"Starting with a notification with userInfo %@", userInfo);

        if (userInfo != nil && [[userInfo allKeys] containsObject:@"sessionhref"]) {
            NSString *url = [userInfo valueForKey:@"sessionhref"];
            
            Conference *conference = [self.model conferenceForSessionHref:url];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setURL:[NSURL URLWithString: conference.href] forKey:@"activeConference"];
            
            UIViewController *rootViewController = [[self window] rootViewController];
            
            if ([rootViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navController = (UINavigationController *)rootViewController;
            
                [navController popToRootViewControllerAnimated:YES];
                
                UIViewController *controller = [navController visibleViewController];
            
                if ([controller isKindOfClass:[EMSMainViewController class]]) {

                    EMSMainViewController *emsView = (EMSMainViewController *)controller;
                    
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
    
    __model = [[EMSModel alloc] initWithManagedObjectContext:[self managedObjectContext]];
    
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
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    CLS_LOG(@"No moc - initialized");
    
    return __managedObjectContext;
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


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }

    NSURL *oldStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"incogito.sqlite"];
    [[NSFileManager defaultManager] removeItemAtPath:oldStoreURL.path error:nil]; // Not interested in error - just removing old cruft

    CLS_LOG(@"No persistent store - initializing");

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"EMSCoreDataModel.sqlite"];
    
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

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

- (void)saveContext{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            CLS_LOG(@"Failed to save data %@, %@", error, [error userInfo]);

            [self showErrorAlertWithTitle:@"Database error" andMessage:@"We failed to save data to the database. If this happens again after an application restart please delete and re-install."];
        }
    }
}

- (void)showErrorAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle: title
                               message: message
                               delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil];
    [errorAlert show];
}

+ (EMSAppDelegate *)sharedAppDelegate
{
    return (EMSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void) startNetwork {
    networkCount++;

    UIApplication *app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = YES;
    
    CLS_LOG(@"startNetwork finished with %d", networkCount);
}

- (void) stopNetwork {
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

@end

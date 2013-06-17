//
//  EMSAppDelegate.m
//

#import "EMSAppDelegate.h"
#import "EMSModel.h"

@implementation EMSAppDelegate

@synthesize managedObjectContext=__managedObjectContext;
@synthesize managedObjectModel=__managedObjectModel;
@synthesize persistentStoreCoordinator=__persistentStoreCoordinator;
@synthesize model=__model;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Keys" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    [Crashlytics startWithAPIKey:[prefs objectForKey:@"crashlytics-api-key"]];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSError *error = nil;
    if (__managedObjectContext != nil) {
        if ([__managedObjectContext hasChanges] && ![__managedObjectContext save:&error]) {
            
			UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle: @"Unable to save data state to the data store at shutdown"
									   message: @"This is not an error we can recover from - please exit using the home button."
									   delegate:nil
									   cancelButtonTitle:@"OK"
									   otherButtonTitles:nil];
			[errorAlert show];

			CLS_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
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
    
    CLS_LOG(@"No persistent store - initializing");
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"EMSCoreDataModel.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle: @"Unable to load data store"
								   message: @"The data store failed to load and without it this application has no data to show. This is not an error we can recover from - please exit using the home button."
								   delegate:nil
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		[errorAlert show];
        
        CLS_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
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
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle: @"Unable to update data store"
                                       message: @"The data store failed to update and without it this application has no data to show. This is not an error we can recover from - please exit using the home button."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            
            CLS_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

+ (EMSAppDelegate *)sharedAppDelegate
{
    return (EMSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end

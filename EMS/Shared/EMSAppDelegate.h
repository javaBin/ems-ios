//
//  EMSAppDelegate.h
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <Crashlytics/Crashlytics.h>

#import "EMSModel.h"

@interface EMSAppDelegate : UIResponder <UIApplicationDelegate, CrashlyticsDelegate, UISplitViewControllerDelegate>

@property(strong, nonatomic) UIWindow *window;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSManagedObjectContext *uiManagedObjectContext;
@property(nonatomic, strong) NSManagedObjectContext *backgroundManagedObjectContext;
@property(nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property(nonatomic, strong) EMSModel *model;

- (NSURL *)applicationDocumentsDirectory;

- (NSURL *)applicationCacheDirectory;

+ (EMSAppDelegate *)sharedAppDelegate;

- (void)startNetwork;

- (void)stopNetwork;

- (EMSModel *)modelForBackground;

- (void)syncManagedObjectContext;

- (void)crashlyticsDidDetectCrashDuringPreviousExecution:(Crashlytics *)crashlytics;

@end

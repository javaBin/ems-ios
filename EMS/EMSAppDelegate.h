//
//  EMSAppDelegate.h
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "EMSModel.h"

@interface EMSAppDelegate : UIResponder <UIApplicationDelegate, CrashlyticsDelegate>

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END

- (void)crashlyticsDidDetectReportForLastExecution:(CLSReport * __nonnull)report completionHandler:(void (^ __nonnull)(BOOL))completionHandler;

@end

//
//  EMSAppDelegate.h
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "EMSModel.h"

@interface EMSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) EMSModel *model;

- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;

+ (EMSAppDelegate *)sharedAppDelegate;

@end

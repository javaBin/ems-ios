//
//  EMSModel.h
//

#import <Foundation/Foundation.h>

@interface EMSModel : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void) storeConferences:(NSArray *)conferences error:(NSError **)error;
- (NSManagedObject *)conferenceForHref:(NSString *)url;

- (void) storeSlots:(NSArray *)slots forConference:(NSString *)href error:(NSError **)error;
- (void) storeRooms:(NSArray *)rooms forConference:(NSString *)href error:(NSError **)error;
- (void) storeSessions:(NSArray *)sessions forConference:(NSString *)href error:(NSError **)error;

- (NSManagedObject *)slotForHref:(NSString *)url;

@end

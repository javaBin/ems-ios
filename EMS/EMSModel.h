//
//  EMSModel.h
//

#import <Foundation/Foundation.h>

@interface EMSModel : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void) storeConferences:(NSArray *)conferences error:(NSError **)error;
- (NSManagedObject *)conferenceForHref:(NSString *)url;
- (NSManagedObject *)conferenceForSessionHref:(NSString *)url;

- (void) storeSlots:(NSArray *)slots forHref:(NSString *)href error:(NSError **)error;
- (void) storeRooms:(NSArray *)rooms forHref:(NSString *)href error:(NSError **)error;
- (void) storeSessions:(NSArray *)sessions forHref:(NSString *)href error:(NSError **)error;
- (void) storeSpeakers:(NSArray *)speakers forHref:(NSString *)href error:(NSError **)error;

- (NSSet *) activeSlotNamesForConference:(NSManagedObject *)conference;

- (NSManagedObject *)sessionForHref:(NSString *)url;
- (NSManagedObject *)slotForHref:(NSString *)url;

- (BOOL)conferencesWithDataAvailable;
- (BOOL)sessionsAvailableForConference:(NSString *)href;

- (NSManagedObject *)toggleFavourite:(NSManagedObject *)session;

@end

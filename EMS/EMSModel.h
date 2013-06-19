//
//  EMSModel.h
//

#import <Foundation/Foundation.h>

#import "Conference.h"
#import "Session.h"
#import "Slot.h"

@interface EMSModel : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void) storeConferences:(NSArray *)conferences error:(NSError **)error;
- (Conference *)conferenceForHref:(NSString *)url;
- (Conference *)conferenceForSessionHref:(NSString *)url;

- (void) storeSlots:(NSArray *)slots forHref:(NSString *)href error:(NSError **)error;
- (void) storeRooms:(NSArray *)rooms forHref:(NSString *)href error:(NSError **)error;
- (void) storeSessions:(NSArray *)sessions forHref:(NSString *)href error:(NSError **)error;
- (void) storeSpeakers:(NSArray *)speakers forHref:(NSString *)href error:(NSError **)error;

- (NSSet *) activeSlotNamesForConference:(Conference *)conference;

- (Session *)sessionForHref:(NSString *)url;
- (Slot *)slotForHref:(NSString *)url;

- (BOOL)conferencesWithDataAvailable;
- (BOOL)sessionsAvailableForConference:(NSString *)href;

- (Session *)toggleFavourite:(Session *)session;

@end

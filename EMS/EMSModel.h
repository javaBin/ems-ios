//
//  EMSModel.h
//

#import <Foundation/Foundation.h>

#import "Conference.h"
#import "Session.h"
#import "Slot.h"

@interface EMSModel : NSObject

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (Conference *)conferenceForHref:(NSString *)url;

- (Conference *)conferenceForSessionHref:(NSString *)url;

- (BOOL)storeConferences:(NSArray *)conferences error:(NSError **)error;

- (BOOL)storeSlots:(NSArray *)slots forHref:(NSString *)href error:(NSError **)error;

- (BOOL)storeRooms:(NSArray *)rooms forHref:(NSString *)href error:(NSError **)error;

- (BOOL)storeSessions:(NSArray *)sessions forHref:(NSString *)href error:(NSError **)error;

- (BOOL)storeSpeakers:(NSArray *)speakers forHref:(NSString *)href error:(NSError **)error;

- (NSSet *)activeSlotNamesForConference:(Conference *)conference;

- (Session *)sessionForHref:(NSString *)url;

- (Slot *)slotForHref:(NSString *)url;

- (BOOL)conferencesWithDataAvailable;

- (BOOL)sessionsAvailableForConference:(NSString *)href;

- (Session *)toggleFavourite:(Session *)session;

- (void)clearConference:(Conference *)conference;

- (NSDate *)dateForConference:(Conference *)conference andDate:(NSDate *)date;

@end

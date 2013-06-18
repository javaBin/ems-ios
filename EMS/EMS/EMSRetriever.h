//
//  EMSRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSRetriever : NSObject

@property (nonatomic, weak) id <EMSRetrieverDelegate> delegate;

- (void) refreshConferences;
- (void) refreshSlots:(NSURL *) slotCollection;
- (void) refreshSessions:(NSURL *) sessionCollection;
- (void) refreshRooms:(NSURL *) roomCollection;

@end

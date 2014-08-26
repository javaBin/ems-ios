//
//  EMSRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSRetriever : NSObject

+ (instancetype) sharedInstance;

@property(nonatomic, weak) id <EMSRetrieverDelegate> delegate;

@property(readonly) BOOL refreshingConferences;

@property(readonly) BOOL refreshingSlots;

@property(readonly) BOOL refreshingSessions;

@property(readonly) BOOL refreshingRooms;

@property(readonly) BOOL refreshingSpeakers;

- (void)refreshRoot;

- (void)refreshActiveConference;

- (void)refreshSpeakers:(NSURL *)speakerCollection;

@end

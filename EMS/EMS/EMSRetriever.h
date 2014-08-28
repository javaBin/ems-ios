//
//  EMSRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSSpeakersRetrieverDelegate.h"
#import "Conference.h"

@interface EMSRetriever : NSObject

+ (instancetype) sharedInstance;

@property(nonatomic, weak) id <EMSSpeakersRetrieverDelegate> delegate;

@property(nonatomic, readonly) BOOL refreshingConferences;

@property(nonatomic, readonly) BOOL refreshingSessions;

@property(nonatomic, readonly) BOOL refreshingSpeakers;

- (void)refreshAllConferences;

- (void)refreshActiveConference;

- (void)refreshSpeakers:(NSURL *)url;

- (NSDate *)lastUpdatedAllConferences;
- (NSDate *)lastUpdatedActiveConference;

- (Conference *)activeConference;
- (NSURL *)currentConference;
- (void)storeCurrentConference:(NSURL *)href;

@end

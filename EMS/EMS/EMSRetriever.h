//
//  EMSRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSSpeakersRetrieverDelegate.h"
#import "Conference.h"

@interface EMSRetriever : NSObject

+ (instancetype) sharedInstance;

@property(nonatomic, weak) id <EMSSpeakersRetrieverDelegate> delegate;

@property(readonly) BOOL refreshingConferences;

@property(readonly) BOOL refreshingSessions;

@property(readonly) BOOL refreshingSpeakers;

@property(nonatomic, strong) NSError *conferenceError;

@property(nonatomic, strong) NSError *sessionError;

- (void)refreshAllConferences;

- (void)refreshActiveConference;

- (void)refreshSpeakers:(NSURL *)url;

- (NSDate *)lastUpdatedAllConferences;
- (NSDate *)lastUpdatedActiveConference;

- (Conference *)activeConference;
- (NSURL *)currentConference;
- (void)storeCurrentConference:(NSURL *)href;

@end

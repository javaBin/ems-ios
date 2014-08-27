//
//  EMSRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSSpeakersRetrieverDelegate.h"

@interface EMSRetriever : NSObject

+ (instancetype) sharedInstance;

@property(nonatomic, weak) id <EMSSpeakersRetrieverDelegate> delegate;

@property(readonly) BOOL refreshingConferences;

@property(readonly) BOOL refreshingSessions;

@property(readonly) BOOL refreshingSpeakers;

@property(nonatomic, strong) NSError *conferenceError;

@property(nonatomic, strong) NSError *sessionError;

@property(nonatomic, strong) NSDate *conferenceLastUpdate;

@property(nonatomic, strong) NSDate *sessionLastUpdate;


- (void)refreshRoot;

- (void)refreshActiveConference;

- (void)refreshSpeakers:(NSURL *)url;

@end

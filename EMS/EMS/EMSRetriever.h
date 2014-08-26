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

- (void)refreshRoot;

- (void)refreshActiveConference;

- (void)refreshSpeakers:(NSURL *)url;

@end

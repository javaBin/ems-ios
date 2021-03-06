//
//  EMSRetriever.h
//

#import <Foundation/Foundation.h>

@class Conference;

@interface EMSRetriever : NSObject

+ (instancetype) sharedInstance;

@property(nonatomic, readonly) BOOL refreshingConferences;

@property(nonatomic, readonly) BOOL refreshingSessions;

- (void)refreshAllConferences;

- (void)refreshActiveConference;

- (NSDate *)lastUpdatedAllConferences;
- (NSDate *)lastUpdatedActiveConference;

- (Conference *)activeConference;
- (NSURL *)currentConference;
- (void)storeCurrentConference:(NSURL *)href;

@end

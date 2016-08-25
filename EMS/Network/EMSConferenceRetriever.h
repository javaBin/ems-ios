//
//  EMSActiveConferenceRetriever.h
//

#import <Foundation/Foundation.h>

@class Conference;

@class EMSConferenceRetriever;

@protocol EMSConferenceRetrieverDelegate <NSObject>

- (void) conferenceRetriever:(EMSConferenceRetriever *) conferenceRetriever finishedWithError:(NSError *) error;

@end

@interface EMSConferenceRetriever : NSObject

@property(nonatomic, weak) id<EMSConferenceRetrieverDelegate> delegate;

@property(nonatomic, weak) Conference  *conference;

- (void)refresh;

- (void) cancel;

@end

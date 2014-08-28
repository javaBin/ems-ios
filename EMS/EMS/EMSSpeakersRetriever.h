//
// EMSSpeakersRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSSpeakersRetrieverDelegate.h"

@interface EMSSpeakersRetriever : NSObject

@property(nonatomic, weak) id <EMSSpeakersRetrieverDelegate> delegate;

@property(nonatomic, readonly) BOOL refreshingSpeakers;

- (void)refreshSpeakers:(NSURL *)url;


@end
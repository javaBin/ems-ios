//
//  EMSSpeakersRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSSpeakersRetriever : NSObject

@property(nonatomic, weak) id <EMSRetrieverDelegate> delegate;

- (void)parse:(NSData *)data forHref:(NSURL *)url withParseQueue:(dispatch_queue_t)queue;

@end

//
//  EMSSessionsRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSSessionsRetriever : NSObject

@property (nonatomic, weak) id <EMSRetrieverDelegate> delegate;

- (void) fetch:(NSURL *)url;

@end

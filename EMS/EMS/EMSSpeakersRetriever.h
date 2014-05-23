//
//  EMSSpeakersRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSSpeakersRetriever : NSObject

@property(nonatomic, weak) id <EMSRetrieverDelegate> delegate;

- (void)fetch:(NSURL *)url;

@end

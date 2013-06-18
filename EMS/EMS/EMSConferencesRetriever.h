//
//  EMSConferencesRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSConferencesRetriever : NSObject

@property (nonatomic, weak) id <EMSRetrieverDelegate> delegate;

- (void) fetch:(NSURL *)url;

@end

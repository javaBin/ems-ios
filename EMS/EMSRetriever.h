//
//  EMSRetriever.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSRetriever : NSObject

@property (nonatomic, strong) id <EMSRetrieverDelegate> delegate;

- (void) refreshConferences;
- (void) refreshSlots:(NSURL *) slotCollection;

@end

//
//  EMSRetrieverDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSRetrieverDelegate <NSObject>

@optional

- (void) finishedConferences:(NSArray *)conferences forHref:(NSURL *)href;
- (void) finishedSlots:(NSArray *)slots forHref:(NSURL *)href;

@end

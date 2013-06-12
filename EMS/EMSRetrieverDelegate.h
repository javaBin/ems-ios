//
//  EMSRetrieverDelegate.h
//  TestRig
//
//  Created by Chris Searle on 12.06.13.
//
//

#import <Foundation/Foundation.h>

@protocol EMSRetrieverDelegate <NSObject>

@optional

- (void) finishedConferences:(NSArray *)conferences forHref:(NSURL *)href;
- (void) finishedSlots:(NSArray *)slots forHref:(NSURL *)href;

@end

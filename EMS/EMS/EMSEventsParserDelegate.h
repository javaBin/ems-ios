//
//  EMSEventsParserDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSEventsParserDelegate <NSObject>

@optional

- (void)finishedEvents:(NSArray *)conferences forHref:(NSURL *)href;

@end

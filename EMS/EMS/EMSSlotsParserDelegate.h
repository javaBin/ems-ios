//
//  EMSSlotsParserDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSSlotsParserDelegate <NSObject>

@optional

- (void)finishedSlots:(NSArray *)slots forHref:(NSURL *)href;

@end

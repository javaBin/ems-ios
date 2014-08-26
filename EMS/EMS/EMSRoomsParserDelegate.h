//
//  EMSRoomsParserDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSRoomsParserDelegate <NSObject>

@optional

- (void)finishedRooms:(NSArray *)rooms forHref:(NSURL *)href;

@end

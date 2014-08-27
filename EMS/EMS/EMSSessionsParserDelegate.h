//
//  EMSSessionsParserDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSSessionsParserDelegate <NSObject>

@optional

- (void)finishedSessions:(NSArray *)sessions forHref:(NSURL *)href error:(NSError **)error;

@end

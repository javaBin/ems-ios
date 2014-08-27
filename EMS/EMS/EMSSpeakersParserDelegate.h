//
//  EMSSpeakersParserDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSSpeakersParserDelegate <NSObject>

@optional

- (void)finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href error:(NSError **)error;

@end

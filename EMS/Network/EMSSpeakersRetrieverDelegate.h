//
//  EMSSpeakersRetrieverDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSSpeakersRetrieverDelegate <NSObject>

@optional

- (void)finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href error:(NSError **)error;

@end

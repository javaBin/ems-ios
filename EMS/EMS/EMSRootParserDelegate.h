//
//  EMSRootParserDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSRootParserDelegate <NSObject>

@optional

- (void)finishedRoot:(NSDictionary *)links forHref:(NSURL *)href error:(NSError **)error;

@end

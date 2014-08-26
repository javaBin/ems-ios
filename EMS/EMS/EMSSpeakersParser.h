//
//  EMSSpeakersParser.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSSpeakersParser : NSObject

@property(nonatomic, weak) id <EMSRetrieverDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

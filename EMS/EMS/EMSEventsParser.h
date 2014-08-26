//
//  EMSEventsParser.h
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSEventsParser : NSObject

@property(nonatomic, weak) id <EMSRetrieverDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

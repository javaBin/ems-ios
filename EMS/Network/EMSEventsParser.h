//
//  EMSEventsParser.h
//

#import <Foundation/Foundation.h>
#import "EMSEventsParserDelegate.h"

@interface EMSEventsParser : NSObject

@property(nonatomic, weak) id <EMSEventsParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

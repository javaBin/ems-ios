//
//  EMSEventsParser.h
//

#import <Foundation/Foundation.h>
#import "EMSParserDelegate.h"

@interface EMSEventsParser : NSObject

@property(nonatomic, weak) id <EMSParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

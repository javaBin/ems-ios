//
//  EMSSessionsParser.h
//

#import <Foundation/Foundation.h>
#import "EMSSessionsParserDelegate.h"

@interface EMSSessionsParser : NSObject

@property(nonatomic, weak) id <EMSSessionsParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

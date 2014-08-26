//
//  EMSSessionsParser.h
//

#import <Foundation/Foundation.h>
#import "EMSParserDelegate.h"

@interface EMSSessionsParser : NSObject

@property(nonatomic, weak) id <EMSParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

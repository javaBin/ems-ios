//
// EMSRootParser.h
//

#import <Foundation/Foundation.h>
#import "EMSRootParserDelegate.h"

@interface EMSRootParser : NSObject

@property(nonatomic, weak) id <EMSRootParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end
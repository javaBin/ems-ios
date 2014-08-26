//
//  EMSSlotsParser.h
//

#import <Foundation/Foundation.h>
#import "EMSSlotsParserDelegate.h"

@interface EMSSlotsParser : NSObject

@property(nonatomic, weak) id <EMSSlotsParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

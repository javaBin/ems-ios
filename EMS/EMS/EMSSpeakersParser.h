//
//  EMSSpeakersParser.h
//

#import <Foundation/Foundation.h>
#import "EMSSpeakersParserDelegate.h"

@interface EMSSpeakersParser : NSObject

@property(nonatomic, weak) id <EMSSpeakersParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

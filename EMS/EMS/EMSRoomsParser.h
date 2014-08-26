//
//  EMSRoomsParser.h
//

#import <Foundation/Foundation.h>
#import "EMSSpeakersRetrieverDelegate.h"

@protocol EMSParserDelegate;

@interface EMSRoomsParser : NSObject

@property(nonatomic, weak) id <EMSParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

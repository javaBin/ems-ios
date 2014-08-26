//
//  EMSRoomsParser.h
//

#import <Foundation/Foundation.h>
#import "EMSRoomsParserDelegate.h"

@interface EMSRoomsParser : NSObject

@property(nonatomic, weak) id <EMSRoomsParserDelegate> delegate;

- (void)parseData:(NSData *)data forHref:(NSURL *)url;

@end

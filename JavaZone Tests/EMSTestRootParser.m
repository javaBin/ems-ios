//
//  EMSTestEventsParser.m
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMSEventsParser.h"
#import "EMSRootParser.h"

@interface EMSTestRootParser : XCTestCase <EMSRootParserDelegate>

@end

@implementation EMSTestRootParser {
    EMSRootParser *parser;
    NSData *data;
    NSURL *emsUrl;
}

- (void)setUp {
    [super setUp];

    parser = [[EMSRootParser alloc] init];

    data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"root" ofType:@"json"]];

    emsUrl = [NSURL URLWithString:@"http://javazone.no/ems/server"];

    [parser setDelegate:self];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testParseRoot {
    [parser parseData:data forHref:emsUrl];
}

- (void)testParseRootNil {
    [parser parseData:nil forHref:nil];
}

- (void)finishedRoot:(NSDictionary *)links forHref:(NSURL *)href error:(NSError *)error {
    if (href != nil) {
        XCTAssertNil(error, @"Error was not nil, %@, %@", error, [error userInfo]);

        XCTAssertEqualObjects(href, emsUrl, @"Incorrect URL seen - expected %@ saw %@", emsUrl, href);

        XCTAssertEqual([links count], 1, @"Links count was not correct: %lu", (unsigned long)[links count]);

        XCTAssertTrue(links[@"event collection"], @"Event Collection key missing %@", links);
    } else {
        XCTAssertNotNil(error, @"Error was nil");

        XCTAssertEqualObjects(@"CollectionJSON", [error domain], @"Domain was incorrect - expected %@ saw %@", @"CollectionJSON", [error domain]);
        XCTAssertEqual(100, [error code], @"Code was incorrect - expected %d saw %ld", 100, (long)[error code]);
    }

}

@end

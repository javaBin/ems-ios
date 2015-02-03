//
//  EMSTestEventsParser.m
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMSEventsParser.h"
#import "EMSConference.h"

@interface EMSTestEventsParser : XCTestCase <EMSEventsParserDelegate>

@end

@implementation EMSTestEventsParser {
    EMSEventsParser *parser;
    NSData *data;
    NSURL *emsUrl;
}

- (void)setUp {
    [super setUp];

    parser = [[EMSEventsParser alloc] init];

    data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"events" ofType:@"json"]];

    emsUrl = [NSURL URLWithString:@"http://javazone.no/ems/server/events"];

    [parser setDelegate:self];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testParseEvents {
    [parser parseData:data forHref:emsUrl];
}

- (void)testParseEventsNil {
    [parser parseData:nil forHref:nil];
}

- (void)finishedEvents:(NSArray *)conferences forHref:(NSURL *)href error:(NSError *)error {
    if (href != nil) {
        XCTAssertNil(error, @"Error was not nil, %@, %@", error, [error userInfo]);

        XCTAssertEqualObjects(href, emsUrl, @"Incorrect URL seen - expected %@ saw %@", emsUrl, href);

        XCTAssertEqual([conferences count], 10, @"Conference count was not correct: %lu", (unsigned long)[conferences count]);

        EMSConference *item = conferences[8];

        XCTAssertEqualObjects(item.name, @"JavaZone 2014", @"Incorrect name");
        XCTAssertEqualObjects(item.venue, @"Oslo Spektrum", @"Incorrect venue");

        XCTAssertEqualObjects(item.start, nil, @"Incorrect start");
        XCTAssertEqualObjects(item.end, nil, @"Incorrect end");

        XCTAssertEqualObjects(item.href, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f"], @"Incorrect href");

        XCTAssertEqualObjects(item.roomCollection, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/rooms"], @"Incorrect room collection");
        XCTAssertEqualObjects(item.slotCollection, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/slots"], @"Incorrect room collection");
        XCTAssertEqualObjects(item.sessionCollection, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/sessions"], @"Incorrect room collection");

        XCTAssertEqual([item.hintCount intValue], 158, @"Incorrect hint count");
    } else {
        XCTAssertNotNil(error, @"Error was nil");

        XCTAssertEqualObjects(@"CollectionJSON", [error domain], @"Domain was incorrect - expected %@ saw %@", @"CollectionJSON", [error domain]);
        XCTAssertEqual(100, [error code], @"Code was incorrect - expected %d saw %ld", 100, (long)[error code]);
    }

}

@end

//
//  EMSTestSlotsParser.m
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMSSlotsParser.h"
#import "EMSSlot.h"
#import "EMSDateConverter.h"

@interface EMSTestSlotsParser : XCTestCase <EMSSlotsParserDelegate>

@end

@implementation EMSTestSlotsParser {
    EMSSlotsParser *parser;
    NSData *data;
    NSURL *emsUrl;
}

- (void)setUp {
    [super setUp];

    parser = [[EMSSlotsParser alloc] init];

    data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"slots" ofType:@"json"]];

    emsUrl = [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/slots"];

    [parser setDelegate:self];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testParseSlots {
    [parser parseData:data forHref:emsUrl];
}

- (void)testParseSlotsNil {
    [parser parseData:nil forHref:nil];
}

- (void)finishedSlots:(NSArray *)slots forHref:(NSURL *)href error:(NSError *)error {
    if (href != nil) {
        XCTAssertNil(error, @"Error was not nil, %@, %@", error, [error userInfo]);

        XCTAssertEqual(href, emsUrl, @"Incorrect URL seen - expected %@ saw %@", emsUrl, href);

        XCTAssertEqual([slots count], 117, @"Slots count was not correct: %lu", [slots count]);

        EMSSlot *item = slots[12];

        XCTAssertEqualWithAccuracy([item.start timeIntervalSinceReferenceDate], 432054000, 0.00001, @"Incorrect start");
        XCTAssertEqualWithAccuracy([item.end timeIntervalSinceReferenceDate], 432057600, 0.00001, @"Incorrect end");

        XCTAssertEqualObjects(item.href, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/slots/da429835-db69-4956-e6ff-4a9c0ed2fe11"], @"Incorrect href");
    } else {
        XCTAssertNotNil(error, @"Error was nil");

        XCTAssertEqualObjects(@"CollectionJSON", [error domain], @"Domain was incorrect - expected %@ saw %@", @"CollectionJSON", [error domain]);
        XCTAssertEqual(100, [error code], @"Code was incorrect - expected %d saw %ld", 100, (long)[error code]);
    }
}

@end

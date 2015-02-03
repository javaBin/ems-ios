//
//  EMSTestRoomsParser.m
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMSRoomsParser.h"
#import "EMSRoom.h"

@interface EMSTestRoomsParser : XCTestCase <EMSRoomsParserDelegate>

@end

@implementation EMSTestRoomsParser {
    EMSRoomsParser *parser;
    NSData *data;
    NSURL *emsUrl;
}

- (void)setUp {
    [super setUp];

    parser = [[EMSRoomsParser alloc] init];

    data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"rooms" ofType:@"json"]];

    emsUrl = [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/rooms"];

    [parser setDelegate:self];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testParseRooms {
    [parser parseData:data forHref:emsUrl];
}

- (void)testParseRoomsNil {
    [parser parseData:nil forHref:nil];
}

- (void)finishedRooms:(NSArray *)rooms forHref:(NSURL *)href error:(NSError *)error {
    if (href != nil) {
        XCTAssertNil(error, @"Error was not nil, %@, %@", error, [error userInfo]);

        XCTAssertEqualObjects(href, emsUrl, @"Incorrect URL seen - expected %@ saw %@", emsUrl, href);

        XCTAssertEqual([rooms count], 11, @"Rooms count was not correct: %lu", (unsigned long)[rooms count]);

        EMSRoom *item = rooms[3];

        XCTAssertEqualObjects(item.name, @"Room 4", @"Incorrect name");

        XCTAssertEqualObjects(item.href, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/rooms/870dfc68-4ae4-4c90-88fc-7a927d8bca89"], @"Incorrect href");
    } else {
        XCTAssertNotNil(error, @"Error was nil");

        XCTAssertEqualObjects(@"CollectionJSON", [error domain], @"Domain was incorrect - expected %@ saw %@", @"CollectionJSON", [error domain]);
        XCTAssertEqual(100, [error code], @"Code was incorrect - expected %d saw %ld", 100, (long)[error code]);
    }
}

@end

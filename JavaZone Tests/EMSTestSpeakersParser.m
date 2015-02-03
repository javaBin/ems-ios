//
//  EMSTestSpeakersParser.m
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMSSpeakersParser.h"
#import "EMSSpeaker.h"

@interface EMSTestSpeakersParser : XCTestCase <EMSSpeakersParserDelegate>

@end

@implementation EMSTestSpeakersParser {
    EMSSpeakersParser *parser;
    NSData *data;
    NSURL *emsUrl;
}

- (void)setUp {
    [super setUp];

    parser = [[EMSSpeakersParser alloc] init];

    data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"speakers" ofType:@"json"]];

    emsUrl = [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/sessions/710a16d2-0113-4c39-9bb6-f7eb7bc24be0/speakers"];

    [parser setDelegate:self];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testParseSpeakers {
    [parser parseData:data forHref:emsUrl];
}

- (void)testParseSpeakersNil {
    [parser parseData:nil forHref:nil];
}

- (void)finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href error:(NSError *)error {
    if (href != nil) {
        XCTAssertNil(error, @"Error was not nil, %@, %@", error, [error userInfo]);

        XCTAssertEqual(href, emsUrl, @"Incorrect URL seen - expected %@ saw %@", emsUrl, href);

        XCTAssertEqual([speakers count], 2, @"Speakers count was not correct: %lu", (unsigned long)[speakers count]);

        EMSSpeaker *item = speakers[1];

        XCTAssertEqualObjects(item.name, @"Tao Yue", @"Incorrect name");

        XCTAssertEqualObjects(item.href, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/sessions/710a16d2-0113-4c39-9bb6-f7eb7bc24be0/speakers/e04c5baf-b3b6-40f2-a421-be5bd673834b"], @"Incorrect href");

        XCTAssertEqualObjects([item.bio substringToIndex:42], @"Dr. Tao Yue is a senior research scientist", @"Incorrect bio");

        XCTAssertEqualObjects(item.thumbnailUrl, [NSURL URLWithString:@"http://javazone.no/ems/server/binary/6ae90365-b12c-45ad-ba29-42b986dc915c?size=thumb"], @"Incorrect thumbnailUrl");
    } else {
        XCTAssertNotNil(error, @"Error was nil");

        XCTAssertEqualObjects(@"CollectionJSON", [error domain], @"Domain was incorrect - expected %@ saw %@", @"CollectionJSON", [error domain]);
        XCTAssertEqual(100, [error code], @"Code was incorrect - expected %d saw %ld", 100, (long)[error code]);
    }
}

@end

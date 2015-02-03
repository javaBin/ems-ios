//
//  EMSTestSessionsParser.m
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMSSessionsParser.h"
#import "EMSSession.h"
#import "EMSSpeaker.h"

@interface EMSTestSessionsParser : XCTestCase <EMSSessionsParserDelegate>

@end

@implementation EMSTestSessionsParser {
    EMSSessionsParser *parser;
    NSData *data;
    NSURL *emsUrl;
}

- (void)setUp {
    [super setUp];

    parser = [[EMSSessionsParser alloc] init];

    data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"sessions" ofType:@"json"]];

    emsUrl = [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/sessions"];

    [parser setDelegate:self];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testParseSessions {
    [parser parseData:data forHref:emsUrl];
}

- (void)testParseSessionsNil {
    [parser parseData:nil forHref:nil];
}

- (void)finishedSessions:(NSArray *)sessions forHref:(NSURL *)href error:(NSError *)error {
    if (href != nil) {
        XCTAssertNil(error, @"Error was not nil, %@, %@", error, [error userInfo]);

        XCTAssertEqual(href, emsUrl, @"Incorrect URL seen - expected %@ saw %@", emsUrl, href);

        XCTAssertEqual([sessions count], 158, @"Sessions count was not correct: %lu", (unsigned long)[sessions count]);

        EMSSession *item = sessions[123];

        XCTAssertEqualObjects(item.title, @"Sjakk Matt", @"Incorrect title");

        XCTAssertEqualObjects(item.href, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/sessions/c9e6c668-efa3-4916-bb9a-93d4a72d79bf"], @"Incorrect href");

        XCTAssertEqualObjects([item.body substringToIndex:42], @"Sjakk programmering startet på begynnelsen", @"Incorrect body");
        XCTAssertEqualObjects([item.audience substringToIndex:52], @"De som kunne vært interessert i sjakk programmering.", @"Incorrect audience");
        XCTAssertEqualObjects([item.summary substringToIndex:43], @"Sjakk Programmering er en veldig sær hobby!", @"Incorrect summary");

        XCTAssertEqualObjects(item.format, @"lightning-talk", @"Incorrect format");

        XCTAssertEqualObjects(item.state, @"approved", @"Incorrect state");

        XCTAssertEqualObjects(item.language, @"no", @"Incorrect language");

        XCTAssertEqualObjects(item.level, @"beginner", @"Incorrect level");

        XCTAssertEqualObjects(item.videoLink, [NSURL URLWithString:@"http://vimeo.com/105861412"], @"Incorrect videoLink");

        XCTAssertEqualObjects(item.attachmentCollection, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/sessions/c9e6c668-efa3-4916-bb9a-93d4a72d79bf/attachments"], @"Incorrect attachmentCollection");
        XCTAssertEqualObjects(item.speakerCollection, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/sessions/c9e6c668-efa3-4916-bb9a-93d4a72d79bf/speakers"], @"Incorrect speakerCollection");
        XCTAssertEqualObjects(item.roomItem, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/rooms/3fc1f1c8-ea9c-406b-ff27-e8999ba612b8"], @"Incorrect roomItem");
        XCTAssertEqualObjects(item.slotItem, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/slots/9038c884-68f3-42a8-f91a-fdce79859ab9"], @"Incorrect slotItem");

        NSArray *keywords = @[@"Concepts", @"Research Innovation"];
        XCTAssertEqualObjects(item.keywords, keywords, @"Incorrect keywords");

        EMSSpeaker *speaker = item.speakers[0];

        XCTAssertEqualObjects(speaker.name, @"Per S. Digre", @"Incorrect speaker name");
        XCTAssertEqualObjects(speaker.href, [NSURL URLWithString:@"http://javazone.no/ems/server/events/9f40063a-5f20-4d7b-b1e8-ed0c6cc18a5f/sessions/c9e6c668-efa3-4916-bb9a-93d4a72d79bf/speakers/97ee0bcc-faa5-4bd6-97c9-6cae0e9d93c6"], @"Incorrect speaker href");

        XCTAssertNil(speaker.bio, @"Speaker bio was not null");
        XCTAssertNil(speaker.thumbnailUrl, @"Speaker thumbnailUrl was not null");
        XCTAssertNil(speaker.lastUpdated, @"Speaker lastUpdated was not null");
    } else {
        XCTAssertNotNil(error, @"Error was nil");

        XCTAssertEqualObjects(@"CollectionJSON", [error domain], @"Domain was incorrect - expected %@ saw %@", @"CollectionJSON", [error domain]);
        XCTAssertEqual(100, [error code], @"Code was incorrect - expected %d saw %ld", 100, (long)[error code]);
    }
}

@end

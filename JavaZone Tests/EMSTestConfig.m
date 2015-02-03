#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMSConfig.h"

@interface EMSTestConfig : XCTestCase

@end

@implementation EMSTestConfig

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConfig {
    XCTAssertEqualObjects([EMSConfig emsRootUrl], [NSURL URLWithString:@"http://javazone.no/ems/server/"], @"Incorrect root url");
}

@end

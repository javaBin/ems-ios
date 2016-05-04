//
//  EMSConfig.m
//

#import "EMSConfig.h"

@implementation EMSConfig

+ (NSURL *) emsRootUrl {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
#ifdef DEBUG
#ifdef TEST_PROD
    return [NSURL URLWithString:prefs[@"ems-root-url-prod"]];
#else
    return [NSURL URLWithString:prefs[@"ems-root-url"]];
#endif
#else
    return [NSURL URLWithString:prefs[@"ems-root-url-prod"]];
#endif
}

+ (NSURL *) ratingUrl {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
#ifdef DEBUG
#ifdef TEST_PROD
    return [NSURL URLWithString:prefs[@"rating-server-prod"]];
#else
    return [NSURL URLWithString:prefs[@"rating-server"]];
#endif
#else
    return [NSURL URLWithString:prefs[@"rating-server-prod"]];
#endif
}

@end

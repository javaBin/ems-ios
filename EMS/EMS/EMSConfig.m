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

@end

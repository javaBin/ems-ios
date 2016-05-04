//
// NSURLResponse+EMSExtensions.m
//

#import "NSURLResponse+EMSExtensions.h"

@implementation NSURLResponse (EMSExtensions)
- (NSError *)ems_error {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];

    [errorDetail setValue:NSLocalizedString(@"Refresh failed", @"Error message when an HTTP error occured when refreshing.") forKey:NSLocalizedDescriptionKey];

    return [NSError errorWithDomain:@"EMS" code:[self ems_statusCode] userInfo:errorDetail];
}

- (BOOL)ems_hasSuccessfulStatus {
    NSInteger status = [self ems_statusCode];

    return status >= 200 && status < 300;
}

- (NSInteger)ems_statusCode {
    NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *) self;

    return httpUrlResponse.statusCode;
}


@end
//
//  EMSDateConverter.m
//  EMS
//
//  Created by Chris Searle on 12.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import "EMSDateConverter.h"

@implementation EMSDateConverter


+ (NSDate *)dateFromString:(NSString *)dateString {
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    
    [inputFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
	NSDate *date = [inputFormatter dateFromString:dateString];
	
    return date;
}

@end

//
//  EMSEventsParser.m
//

#import "EMSEventsParser.h"
#import "EMSConference.h"

#import "CJCollection.h"
#import "CJLink.h"
#import "CJItem.h"

#import "EMSDateConverter.h"

@implementation EMSEventsParser

- (NSArray *)processData:(NSData *)data andHref:(NSURL *)href error:(NSError **)error {
    NSError *parseError = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&parseError];

    if (!collection) {
        DDLogError(@"Failed to retrieve conferences %@ - %@ - %@", href, parseError, [parseError userInfo]);

        *error = parseError;

        return [NSArray array];
    }

    NSMutableArray *temp = [[NSMutableArray alloc] init];

    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *) obj;

        EMSConference *conf = [[EMSConference alloc] init];

        conf.href = item.href;

        [item.data enumerateObjectsUsingBlock:^(id dataObj, NSUInteger dataIdx, BOOL *dataStop) {
            NSDictionary *dict = (NSDictionary *) dataObj;

            NSString *field = dict[@"name"];
            NSString *value = dict[@"value"];

            if ([@"name" isEqualToString:field]) {
                conf.name = value;
            }
            if ([@"venue" isEqualToString:field]) {
                conf.venue = value;
            }
            if ([@"start" isEqualToString:field]) {
                conf.start = [EMSDateConverter dateFromString:value];
            }
            if ([@"end" isEqualToString:field]) {
                conf.end = [EMSDateConverter dateFromString:value];
            }
        }];

        [item.links enumerateObjectsUsingBlock:^(id linksObj, NSUInteger linksIdx, BOOL *linksStop) {
            CJLink *link = (CJLink *) linksObj;

            if ([@"session collection" isEqualToString:link.rel]) {
                conf.sessionCollection = link.href;

                if (link.otherFields != nil) {
                    conf.hintCount = link.otherFields[@"count"];
                }
            }
            if ([@"slot collection" isEqualToString:link.rel]) {
                conf.slotCollection = link.href;
            }
            if ([@"room collection" isEqualToString:link.rel]) {
                conf.roomCollection = link.href;
            }
        }];

        [temp addObject:conf];
    }];

    return [NSArray arrayWithArray:temp];
}

- (void)parseData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;

    NSArray *collection = [self processData:data andHref:href error:&error];

    [self.delegate finishedEvents:collection forHref:href error:error];
}

@end

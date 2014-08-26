//
//  EMSConferencesRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSConferencesRetriever.h"
#import "EMSConference.h"

#import "CJCollection.h"
#import "CJLink.h"
#import "CJItem.h"

#import "EMSDateConverter.h"
#import "EMSTracking.h"

@implementation EMSConferencesRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data andHref:(NSURL *)href {
    NSError *error = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];

    if (!collection) {
        EMS_LOG(@"Failed to retrieve conferences %@ - %@ - %@", href, error, [error userInfo]);

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

- (void)fetchedEventCollection:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData andHref:href];

    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

    [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"conferences"];
    [EMSTracking dispatch];

    [self.delegate finishedConferences:collection forHref:href];
}

- (void)parse:(NSData *)data forHref:(NSURL *)url withParseQueue:(dispatch_queue_t)queue {
    if (url == nil) {
        EMS_LOG(@"Asked to fetch nil events url");

        return;
    }
    dispatch_async(queue, ^{
        [self fetchedEventCollection:data forHref:url];
    });
}

@end

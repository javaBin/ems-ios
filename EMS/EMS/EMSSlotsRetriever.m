//
//  EMSSlotsRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSSlotsRetriever.h"
#import "EMSSlot.h"

#import "CJCollection.h"
#import "CJItem.h"

#import "EMSDateConverter.h"
#import "EMSTracking.h"

@implementation EMSSlotsRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];

    if (!collection) {
        EMS_LOG(@"Failed to retrieve slots %@ - %@ - %@", href, error, [error userInfo]);

        return [NSArray array];
    }

    NSMutableArray *temp = [[NSMutableArray alloc] init];

    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *) obj;

        EMSSlot *slot = [[EMSSlot alloc] init];

        slot.href = item.href;

        [item.data enumerateObjectsUsingBlock:^(id dataObj, NSUInteger dataIdx, BOOL *dataStop) {
            NSDictionary *dict = (NSDictionary *) dataObj;

            NSString *field = dict[@"name"];
            NSString *value = dict[@"value"];

            if ([@"start" isEqualToString:field]) {
                slot.start = [EMSDateConverter dateFromString:value];
            }
            if ([@"end" isEqualToString:field]) {
                slot.end = [EMSDateConverter dateFromString:value];
            }
        }];

        [temp addObject:slot];
    }];

    return [NSArray arrayWithArray:temp];
}

- (void)fetchedSlots:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData forHref:href];

    [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"slots"];
    [EMSTracking dispatch];

    [self.delegate finishedSlots:collection forHref:href];
}

- (void)fetch:(NSURL *)url withParseQueue:(dispatch_queue_t)queue {
    if (url == nil) {
        EMS_LOG(@"Asked to fetch nil slots url");

        return;
    }

    NSURLSession *session = [NSURLSession sharedSession];

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);
        }

        dispatch_async(queue, ^{
            [self fetchedSlots:data forHref:url];
        });

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
}

@end

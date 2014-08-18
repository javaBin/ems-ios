//
//  EMSSlotsRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSSlotsRetriever.h"
#import "EMSSlot.h"

#import "CJCollection.h"
#import "CJItem.h"

#import "EMSDateConverter.h"
#import "EMSFeatureConfig.h"

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

    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        NSNumber *interval = @([[NSDate date] timeIntervalSinceDate:timer]);
        [tracker send:[[GAIDictionaryBuilder createTimingWithCategory:@"retrieval"
                                                             interval:interval
                                                                 name:@"slots"
                                                                label:nil] build]];

        [[GAI sharedInstance] dispatch];
    }

    [self.delegate finishedSlots:collection forHref:href];
}

- (void)fetch:(NSURL *)url {
    if (url == nil) {
        EMS_LOG(@"Asked to fetch nil slots url");

        return;
    }

    dispatch_queue_t queue = dispatch_queue_create("ems_slot_queue", DISPATCH_QUEUE_CONCURRENT);

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    timer = [NSDate date];

    dispatch_async(queue, ^{
        NSError *rootError = nil;

        NSData *root = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&rootError];

        if (root == nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, rootError, [rootError userInfo]);
        }

        dispatch_async(queue, ^{
            [self fetchedSlots:root forHref:url];
        });
    });
}

@end

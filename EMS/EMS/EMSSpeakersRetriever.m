//
//  EMSSpeakersRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSSpeakersRetriever.h"
#import "EMSSpeaker.h"

#import "CJCollection.h"
#import "CJItem.h"
#import "CJLink.h"

@implementation EMSSpeakersRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];

    if (!collection) {
        CLS_LOG(@"Failed to retrieve speakers %@ - %@ - %@", href, error, [error userInfo]);

        return [NSArray array];
    }

    NSMutableArray *temp = [[NSMutableArray alloc] init];

    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *) obj;

        EMSSpeaker *speaker = [[EMSSpeaker alloc] init];

        speaker.href = item.href;

        [item.data enumerateObjectsUsingBlock:^(id dataObj, NSUInteger dataIdx, BOOL *dataStop) {
            NSDictionary *dict = (NSDictionary *) dataObj;

            NSString *field = dict[@"name"];
            NSString *value = dict[@"value"];

            if ([@"name" isEqualToString:field]) {
                speaker.name = value;
            }
            if ([@"bio" isEqualToString:field]) {
                speaker.bio = value;
            }
        }];

        [item.links enumerateObjectsUsingBlock:^(id linksObj, NSUInteger linksIdx, BOOL *linksStop) {
            CJLink *link = (CJLink *) linksObj;

            if ([@"thumbnail" isEqualToString:link.rel]) {
                speaker.thumbnailUrl = link.href;
            }
        }];

        [temp addObject:speaker];
    }];

    return [NSArray arrayWithArray:temp];
}

- (void)fetchedSpeakers:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData forHref:href];

    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

#ifndef DO_NOT_USE_GA
    id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    NSNumber *interval = @([[NSDate date] timeIntervalSinceDate:timer]);
    [tracker send:[[GAIDictionaryBuilder createTimingWithCategory:@"retrieval"
                                                         interval:interval
                                                             name:@"speakers"
                                                            label:nil] build]];

    [[GAI sharedInstance] dispatch];
#endif

    [self.delegate finishedSpeakers:collection forHref:href];
}

- (void)fetch:(NSURL *)url {
    if (url == nil) {
        CLS_LOG(@"Asked to fetch nil speakers url");

        return;
    }
    dispatch_queue_t queue = dispatch_queue_create("ems_speaker_queue", DISPATCH_QUEUE_CONCURRENT);

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    timer = [NSDate date];

    dispatch_async(queue, ^{
        NSError *rootError = nil;

        NSData *root = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&rootError];

        if (root == nil) {
            CLS_LOG(@"Retrieved nil root %@ - %@ - %@", url, rootError, [rootError userInfo]);
        }

        dispatch_async(queue, ^{
            [self fetchedSpeakers:root forHref:url];
        });
    });
}


@end

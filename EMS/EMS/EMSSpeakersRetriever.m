//
//  EMSSpeakersRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSSpeakersRetriever.h"
#import "EMSSpeaker.h"

#import "CJCollection.h"
#import "CJItem.h"
#import "CJLink.h"
#import "EMSTracking.h"

@implementation EMSSpeakersRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];

    if (!collection) {
        EMS_LOG(@"Failed to retrieve speakers %@ - %@ - %@", href, error, [error userInfo]);

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

        speaker.lastUpdated = [NSDate date];

        [temp addObject:speaker];
    }];

    return [NSArray arrayWithArray:temp];
}

- (void)fetchedSpeakers:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData forHref:href];

    [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"speakers"];
    [EMSTracking dispatch];

    [self.delegate finishedSpeakers:collection forHref:href];
}

- (void)parse:(NSData *)data forHref:(NSURL *)url withParseQueue:(dispatch_queue_t)queue {
    if (url == nil) {
        EMS_LOG(@"Asked to fetch nil speakers url");

        return;
    }
    dispatch_async(queue, ^{
        [self fetchedSpeakers:data forHref:url];
    });
}


@end

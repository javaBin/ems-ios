//
//  EMSSpeakersParser.m
//

#import "EMS-Swift.h"

#import "EMSSpeakersParser.h"

#import "CJCollection.h"
#import "CJItem.h"
#import "CJLink.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation EMSSpeakersParser

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href error:(NSError **)error {
    NSError *parseError = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&parseError];

    if (!collection) {
        DDLogError(@"Failed to retrieve speakers %@ - %@ - %@", href, parseError, [parseError userInfo]);

        *error = parseError;

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

- (void)parseData:(NSData *)data forHref:(NSURL *)href {
    NSError *error;

    NSArray *collection = [self processData:data forHref:href error:&error];

    [self.delegate finishedSpeakers:collection forHref:href error:error];
}

@end

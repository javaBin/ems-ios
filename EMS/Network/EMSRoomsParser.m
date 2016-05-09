//
//  EMSRoomsParser.m
//

#import "EMS-Swift.h"

#import "EMSRoomsParser.h"

#import "CJCollection.h"
#import "CJItem.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation EMSRoomsParser

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href error:(NSError **)error {
    NSError *parseError = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&parseError];

    if (!collection) {
        DDLogError(@"Failed to retrieve rooms %@ - %@ - %@", href, parseError, [parseError userInfo]);

        *error = parseError;

        return [NSArray array];
    }

    NSMutableArray *temp = [[NSMutableArray alloc] init];

    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *) obj;

        EMSRoom *room = [[EMSRoom alloc] init];

        room.href = item.href;

        [item.data enumerateObjectsUsingBlock:^(id dataObj, NSUInteger dataIdx, BOOL *dataStop) {
            NSDictionary *dict = (NSDictionary *) dataObj;

            NSString *field = dict[@"name"];
            NSString *value = dict[@"value"];

            if ([@"name" isEqualToString:field]) {
                room.name = value;
            }
        }];

        [temp addObject:room];
    }];

    return [NSArray arrayWithArray:temp];
}

- (void)parseData:(NSData *)data forHref:(NSURL *)href {
    NSError *error;

    NSArray *collection = [self processData:data forHref:href error:&error];

    [self.delegate finishedRooms:collection forHref:href error:error];
}

@end

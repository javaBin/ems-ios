//
// EMSSpeakersRetriever.m
//

#import "EMSSpeakersRetriever.h"
#import "EMSSpeakersParserDelegate.h"
#import "EMSAppDelegate.h"
#import "EMSSpeakersParser.h"
#import "EMSTracking.h"

@interface EMSSpeakersRetriever () <EMSSpeakersParserDelegate>

@property(readwrite) BOOL refreshingSpeakers;
@property(nonatomic) NSURLSession *speakersURLSession;
@property(nonatomic) NSOperationQueue *speakersParseQueue;

@end

@implementation EMSSpeakersRetriever

+ (instancetype)sharedInstance {
    static EMSSpeakersRetriever *instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EMSSpeakersRetriever alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _refreshingSpeakers = NO;
        NSURLSessionConfiguration *speakersConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _speakersURLSession = [NSURLSession sessionWithConfiguration:speakersConfiguration];
        _speakersParseQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href error:(NSError *)error {
    if (error != nil) {
        EMS_LOG(@"Retrieved error for speakers %@ - %@", error, [error userInfo]);

        return;
    }

    EMS_LOG(@"Storing speakers %lu for href %@", (unsigned long) [speakers count], href);

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock:^{
        NSError *saveError = nil;

        if (![backgroundModel storeSpeakers:speakers forHref:[href absoluteString] error:&saveError]) {
            EMS_LOG(@"Failed to store speakers %@ - %@", saveError, [saveError userInfo]);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
            self.refreshingSpeakers = NO;

            if ([self.delegate respondsToSelector:@selector(finishedSpeakers:forHref:error:)]) {
                [self.delegate finishedSpeakers:speakers forHref:href error:NULL];
            }
        });
    }];
}

- (void)refreshSpeakers:(NSURL *)url {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    if (self.refreshingSpeakers) {
        return;
    }

    self.refreshingSpeakers = YES;

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    NSDate *timer = [NSDate date];

    [[self.speakersURLSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);
        }

        EMSSpeakersParser *parser = [[EMSSpeakersParser alloc] init];

        parser.delegate = self;

        [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"speakers"];
        [EMSTracking dispatch];

        [self.speakersParseQueue addOperationWithBlock:^{
            [parser parseData:data forHref:url];
        }];

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];

}

@end
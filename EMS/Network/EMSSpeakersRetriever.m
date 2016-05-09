//
// EMSSpeakersRetriever.m
//

#import "EMS-Swift.h"

#import "EMSSpeakersRetriever.h"
#import "EMSAppDelegate.h"
#import "EMSTracking.h"
#import "NSURLResponse+EMSExtensions.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@interface EMSSpeakersRetriever () <EMSSpeakersParserDelegate>

@property(readwrite) BOOL refreshingSpeakers;
@property(nonatomic) NSURLSession *speakersURLSession;
@property(nonatomic) NSOperationQueue *speakersParseQueue;

@end

@implementation EMSSpeakersRetriever

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

- (void)finishedWithError:(NSError *)error {
    if (!self.refreshingSpeakers) {
        //Already reported an error.
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogError(@"Error for speakers %@ - %@", error, [error userInfo]);

        self.refreshingSpeakers = NO;
    });
}

- (void)finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href error:(NSError *)error {
    if (error != nil) {
        [self finishedWithError:error];
    } else {
        DDLogVerbose(@"Storing speakers %lu for href %@", (unsigned long) [speakers count], href);

        EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

        [backgroundModel.managedObjectContext performBlock:^{
            NSError *saveError = nil;

            if (![backgroundModel storeSpeakers:speakers forHref:[href absoluteString] error:&saveError]) {
                [self finishedWithError:saveError];
            } else {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
                    self.refreshingSpeakers = NO;

                    if ([self.delegate respondsToSelector:@selector(finishedSpeakers:forHref:error:)]) {
                        [self.delegate finishedSpeakers:speakers forHref:href error:NULL];
                    }
                });
            }
        }];
    }
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
            [self finishedWithError:error];
        } else if (![response ems_hasSuccessfulStatus]) {
            [self finishedWithError:[response ems_error]];
        } else {
            EMSSpeakersParser *parser = [[EMSSpeakersParser alloc] init];

            parser.delegate = self;

            [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"speakers"];
            [EMSTracking dispatch];

            [self.speakersParseQueue addOperationWithBlock:^{
                [parser parseData:data forHref:url];
            }];
        }

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];

}

@end